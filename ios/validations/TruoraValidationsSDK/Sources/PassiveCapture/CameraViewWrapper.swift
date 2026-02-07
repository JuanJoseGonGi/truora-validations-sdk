//
//  CameraViewWrapper.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 23/01/26.
//

import SwiftUI
import TruoraCamera
import UIKit

struct CameraViewWrapper: UIViewRepresentable {
    @ObservedObject var viewModel: PassiveCaptureViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> CameraView {
        let processor = FrameProcessorFactory.createProcessor(
            for: .face,
            delegate: context.coordinator
        )
        let cameraView = CameraView(frameProcessor: processor)
        cameraView.backgroundColor = .clear
        cameraView.delegate = context.coordinator
        context.coordinator.cameraView = cameraView
        viewModel.cameraViewDelegate = context.coordinator
        return cameraView
    }

    func updateUIView(_: CameraView, context _: Context) {}

    @MainActor class Coordinator: NSObject, @preconcurrency CameraDelegate, CameraViewDelegate {
        let viewModel: PassiveCaptureViewModel
        weak var cameraView: CameraView?

        init(viewModel: PassiveCaptureViewModel) {
            self.viewModel = viewModel
        }

        func setupCamera() {
            guard let cameraView else {
                print("⚠️ setupCamera() failed - cameraView is nil")
                DispatchQueue.main.async {
                    let message = "Camera view not available. Please restart the validation."
                    self.viewModel.errorMessage = message
                    self.viewModel.showError = true
                }
                return
            }
            // Passive capture always uses front camera only - camera switching is not supported
            cameraView.startCamera(side: .front, cameraOutputMode: .video)
        }

        func startRecording() {
            guard let cameraView else {
                print("⚠️ CameraViewDelegate: startRecording() called but cameraView is nil")
                DispatchQueue.main.async {
                    self.viewModel.errorMessage = "Camera not ready to record. Please try again."
                    self.viewModel.showError = true
                }
                return
            }
            cameraView.startRecordingVideo()
        }

        func stopRecording(skipMediaNotification: Bool) {
            guard let cameraView else {
                print("⚠️ CameraViewDelegate: stopRecording() called but cameraView is nil")
                DispatchQueue.main.async {
                    self.viewModel.errorMessage = "Unable to stop recording. " +
                        "Camera resources may not be released properly."
                    self.viewModel.showError = true
                }
                return
            }
            cameraView.stopVideoRecording(skipMediaNotification: skipMediaNotification)
        }

        func stopCamera() {
            guard let cameraView else {
                print("⚠️ CameraViewDelegate: stopCamera() called but cameraView is nil")
                return
            }
            cameraView.stopCamera()
        }

        func pauseCamera() {
            guard let cameraView else {
                print("⚠️ CameraViewDelegate: pauseCamera() called but cameraView is nil")
                return
            }
            cameraView.pauseCamera()
        }

        func resumeCamera() {
            guard let cameraView else {
                print("⚠️ CameraViewDelegate: resumeCamera() called but cameraView is nil")
                return
            }
            cameraView.resumeCamera()
        }

        func cameraReady() {
            print("🟢 CameraViewWrapper: Camera ready callback")
            viewModel.cameraReady()
        }

        func mediaReady(media: Data) {
            print("🟢 CameraViewWrapper: Video recording completed, \(media.count) bytes")
            viewModel.videoRecordingCompleted(videoData: media)
        }

        func lastFrameCaptured(frameData: Data) {
            viewModel.lastFrameCaptured(frameData: frameData)
        }

        func reportError(error: CameraError) {
            #if DEBUG
            print("❌ CameraViewWrapper: Camera error: \(error)")
            #endif

            if case .permissionDenied = error {
                viewModel.cameraPermissionDenied()
            } else {
                viewModel.showError("Camera error: \(error.localizedDescription)")
            }
        }

        func detectionsReceived(_ results: [DetectionResult]) {
            viewModel.detectionsReceived(results)
        }

        func autocaptureUnavailable(error: Error?) {
            // Not applicable for face capture - autocapture is always available
            // Face detection uses Vision framework which doesn't require ML model download
            _ = error
        }
    }
}

@MainActor
protocol CameraViewDelegate: AnyObject {
    func setupCamera()
    func startRecording()
    func stopRecording(skipMediaNotification: Bool)
    func stopCamera()
    func pauseCamera()
    func resumeCamera()
}
