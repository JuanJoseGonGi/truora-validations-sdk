//
//  CameraManager+Setup.swift
//  TruoraCamera
//
//  Created by Truora on 21/11/25.
//

import AVFoundation
import UIKit

extension CameraManager {
    func setupCamera(view: UIView, cameraOutputMode: CameraOutputMode) {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            debugLog("🧪 CameraManager: UI Testing mode detected. Skipping real camera setup.")
            cameraIsSetup = true
            // Simulate camera ready delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.delegate?.cameraReady()
            }
            return
        }
        #endif

        guard !cameraIsSetup else {
            debugLog("⚠️ CameraManager: setupCamera called when camera is already setup")
            return
        }

        // Mark as setup immediately to prevent race conditions with double setup calls
        cameraIsSetup = true

        // Reset paused state when starting fresh
        skipMediaNotification = false

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            debugLog("✅ CameraManager: Camera permission granted")
            configureSession(view: view, cameraOutputMode: cameraOutputMode)
        case .notDetermined:
            debugLog("⚠️ CameraManager: Camera permission not determined")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureSession(view: view, cameraOutputMode: cameraOutputMode)
                    } else {
                        let cameraError = CameraError.internalError(
                            "Camera permission denied by user"
                        )
                        self?.delegate?.reportError(error: cameraError)
                    }
                }
            }
        case .denied, .restricted:
            debugLog("❌ CameraManager: Camera permission denied or restricted")
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            delegate?.reportError(error: .permissionDenied(status: status))
            return
        @unknown default:
            debugLog("❌ CameraManager: Unknown camera permission status")
            let cameraError = CameraError.internalError("Unknown camera permission status")
            delegate?.reportError(error: cameraError)
            return
        }
    }

    private func configureSession(view: UIView, cameraOutputMode: CameraOutputMode) {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .hd1280x720
        focusGesture.isEnabled = true

        captureSession?.beginConfiguration()
        let inputAdded = setupInput()
        let outputAdded = setupOutputMode(cameraOutputMode)
        captureSession?.commitConfiguration()

        guard inputAdded, outputAdded else {
            debugLog(
                "❌ CameraManager: Failed to setup camera - input: \(inputAdded), output: \(outputAdded)"
            )
            cameraIsSetup = false // Reset since setup failed
            let cameraError = CameraError.internalError("Failed to configure camera")
            delegate?.reportError(error: cameraError)
            return
        }

        setupLivePreview(photoPreview: view)
    }

    @discardableResult
    func setupInput() -> Bool {
        guard let camera = getCamera() else {
            debugLog("❌ CameraManager: Failed to get camera device")
            let cameraError = CameraError.internalError("Error getting camera")
            delegate?.reportError(error: cameraError)
            return false
        }

        var input: AVCaptureDeviceInput?
        do {
            input = try AVCaptureDeviceInput(device: camera)
        } catch {
            debugLog("❌ CameraManager: Failed to create camera input: \(error.localizedDescription)")
            let message = "Error creating capture device input: \(error.localizedDescription)"
            delegate?.reportError(error: .internalError(message))
            return false
        }

        guard let captureSession, let input, captureSession.canAddInput(input) else {
            debugLog("❌ CameraManager: Cannot add camera input to session")
            let cameraError = CameraError.internalError("Error creating capture device input")
            delegate?.reportError(error: cameraError)
            return false
        }

        captureSession.addInput(input)
        return true
    }

    @discardableResult
    func setupOutputMode(_ newCameraOutputMode: CameraOutputMode) -> Bool {
        cameraOutputMode = newCameraOutputMode

        switch cameraOutputMode {
        case .image:
            return setImageOutput()
        case .video:
            return setVideoOutput()
        }
    }

    func setImageOutput() -> Bool {
        if imageOutput != nil {
            return true
        }

        let newImageOutput = AVCapturePhotoOutput()
        imageOutput = newImageOutput

        guard let captureSession, captureSession.canAddOutput(newImageOutput) else {
            debugLog("❌ CameraManager: Cannot add image output to session")
            let cameraError = CameraError.internalError("Unable to initialize camera")
            delegate?.reportError(error: cameraError)
            return false
        }

        captureSession.addOutput(newImageOutput)

        // Also add video data output for frame processing (detection)
        // This enables document/face detection while in still image capture mode
        let newVideoDataOutput = AVCaptureVideoDataOutput()
        newVideoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        newVideoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        newVideoDataOutput.alwaysDiscardsLateVideoFrames = true

        videoDataOutput = newVideoDataOutput

        guard captureSession.canAddOutput(newVideoDataOutput) else {
            debugLog(
                "⚠️ CameraManager: Cannot add video data output for frame processing in image mode"
            )
            // Not a critical error - image capture will still work, just without frame processing
            return true
        }

        captureSession.addOutput(newVideoDataOutput)

        return true
    }

    func setVideoOutput() -> Bool {
        if videoOutput != nil {
            return true
        }

        let newVideoOutput = AVCaptureMovieFileOutput()
        newVideoOutput.movieFragmentInterval = CMTime.invalid

        videoOutput = newVideoOutput

        guard let captureSession, captureSession.canAddOutput(newVideoOutput) else {
            debugLog("❌ CameraManager: Cannot add video output to session")
            let cameraError = CameraError.internalError("Unable to initialize camera")
            delegate?.reportError(error: cameraError)
            return false
        }

        captureSession.addOutput(newVideoOutput)

        // Configure HEVC if available (iOS 13+ support)
        if let connection = newVideoOutput.connection(with: .video),
           newVideoOutput.availableVideoCodecTypes.contains(.hevc) {
            newVideoOutput.setOutputSettings(
                [AVVideoCodecKey: AVVideoCodecType.hevc], for: connection
            )
            debugLog("✅ CameraManager: HEVC codec configured for video recording")
        }

        let newVideoDataOutput = AVCaptureVideoDataOutput()
        newVideoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        newVideoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        newVideoDataOutput.alwaysDiscardsLateVideoFrames = true

        videoDataOutput = newVideoDataOutput

        guard captureSession.canAddOutput(newVideoDataOutput) else {
            debugLog("❌ CameraManager: Cannot add video data output to session")
            let cameraError = CameraError.internalError("Unable to add video data output")
            delegate?.reportError(error: cameraError)
            return false
        }

        captureSession.addOutput(newVideoDataOutput)
        return true
    }

    func setupLivePreview(photoPreview: UIView) {
        guard let captureSession else { return }

        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        guard let videoPreviewLayer else { return }

        videoPreviewLayer.frame = photoPreview.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait

        photoPreview.layer.addSublayer(videoPreviewLayer)

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.captureSession?.startRunning()

            // Wait for session to start and connections to be established
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard let self else { return }

                guard self.captureSession?.isRunning == true else {
                    self.cameraIsSetup = false // Reset since session failed to start
                    let cameraError = CameraError.internalError("Camera session failed to start")
                    self.delegate?.reportError(error: cameraError)
                    return
                }

                self.videoPreviewLayer?.frame = photoPreview.bounds
                // Note: cameraIsSetup is already true (set synchronously in setupCamera)
                self.attachFocus(photoPreview)

                if self.cameraOutputMode == .video {
                    self.waitForVideoConnectionReady()
                } else {
                    self.delegate?.cameraReady()
                }
            }
        }
    }

    func calculateVisibleCameraFrame(for view: UIView) -> CGRect {
        view.bounds
    }

    func updatePreviewLayerFrame(for view: UIView) {
        guard cameraIsSetup else { return }
        videoPreviewLayer?.frame = view.bounds
    }
}
