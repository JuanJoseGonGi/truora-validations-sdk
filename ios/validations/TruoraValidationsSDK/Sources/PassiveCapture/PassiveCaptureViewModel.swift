//
//  PassiveCaptureViewModel.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 23/01/26.
//

import Combine
import Foundation
import TruoraCamera
import UIKit

/// ViewModel for the passive face capture screen.
/// Uses @Published properties which automatically notify SwiftUI on the main thread.
@MainActor final class PassiveCaptureViewModel: ObservableObject {
    @Published var state: PassiveCaptureState = .countdown
    @Published var feedback: FeedbackType = .none
    @Published var countdown: Int = 3
    @Published var showHelpDialog = false
    @Published var showSettingsPrompt = false
    @Published var lastFrameData: Data?
    @Published var uploadState: UploadState = .none
    @Published var errorMessage: String?
    @Published var showError = false

    /// Tracks if a recording is currently in progress to prevent multiple clicks
    @Published var isRecordingInProgress: Bool = false

    var presenter: PassiveCaptureViewToPresenter?
    weak var cameraViewDelegate: CameraViewDelegate?

    func onAppear() {
        Task { await presenter?.viewDidLoad() }
    }

    func onWillAppear() {
        Task { await presenter?.viewWillAppear() }
    }

    func onWillDisappear() {
        Task { await presenter?.viewWillDisappear() }
    }

    func onAppWillResignActive() {
        Task { await presenter?.appWillResignActive() }
    }

    func onAppDidBecomeActive() {
        Task { await presenter?.appDidBecomeActive() }
    }

    func handleEvent(_ event: PassiveCaptureEvent) {
        // Immediately disable button when recording is requested to prevent multiple clicks
        if case .recordVideoRequested = event {
            isRecordingInProgress = true
        }
        Task { await presenter?.handleCaptureEvent(event) }
    }

    // MARK: - Camera Delegate Methods called by Wrapper

    func cameraReady() {
        Task { await presenter?.cameraReady() }
    }

    func cameraPermissionDenied() {
        Task { await presenter?.cameraPermissionDenied() }
    }

    func videoRecordingCompleted(videoData: Data) {
        Task { await presenter?.videoRecordingCompleted(videoData: videoData) }
    }

    func lastFrameCaptured(frameData: Data) {
        Task { await presenter?.lastFrameCaptured(frameData: frameData) }
    }

    func detectionsReceived(_ results: [DetectionResult]) {
        Task { await presenter?.detectionsReceived(results) }
    }

    func cameraError(_ errorMessage: String) {
        Task { await presenter?.cameraError(errorMessage) }
    }
}

// MARK: - PassiveCapturePresenterToView

extension PassiveCaptureViewModel: PassiveCapturePresenterToView {
    func setupCamera() {
        debugLog("🟢 Setting up camera")
        guard let delegate = cameraViewDelegate else {
            debugLog("⚠️ setupCamera() failed - delegate is nil")
            errorMessage = "Camera initialization failed. Please try again."
            showError = true
            return
        }
        delegate.setupCamera()
    }

    func startRecording() {
        debugLog("🟢 PassiveCaptureViewModel: Starting recording")
        guard let delegate = cameraViewDelegate else {
            debugLog("⚠️ startRecording() failed - delegate is nil")
            errorMessage = "Unable to start recording. Please try again."
            showError = true
            return
        }
        delegate.startRecording()
    }

    func stopRecording() {
        debugLog("🟢 Stopping recording")
        guard let delegate = cameraViewDelegate else {
            debugLog("⚠️ stopRecording() failed - delegate is nil")
            errorMessage = "Unable to stop recording properly. The camera may still be in use."
            showError = true
            return
        }
        delegate.stopRecording(skipMediaNotification: false)
    }

    func stopCamera() {
        debugLog("🟢 Stopping camera")
        guard let delegate = cameraViewDelegate else {
            debugLog("⚠️ stopCamera() failed - delegate is nil")
            return
        }
        delegate.stopCamera()
    }

    func pauseCamera() {
        debugLog("🟢 PassiveCaptureViewModel: Pausing camera")
        guard let delegate = cameraViewDelegate else {
            debugLog("⚠️ PassiveCaptureViewModel: pauseCamera() called but delegate is nil")
            return
        }
        delegate.pauseCamera()
    }

    func resumeCamera() {
        debugLog("🟢 PassiveCaptureViewModel: Resuming camera")
        guard let delegate = cameraViewDelegate else {
            debugLog("⚠️ PassiveCaptureViewModel: resumeCamera() called but delegate is nil")
            return
        }
        delegate.resumeCamera()
    }

    func pauseVideo() {
        debugLog("🟢 PassiveCaptureViewModel: Pausing video")
        guard let delegate = cameraViewDelegate else {
            debugLog("⚠️ PassiveCaptureViewModel: pauseVideo() called but delegate is nil")
            return
        }
        delegate.stopRecording(skipMediaNotification: true)
    }

    func resumeVideo() {
        startRecording()
    }

    func updateUI(
        state: PassiveCaptureState,
        feedback: FeedbackType,
        countdown: Int,
        showHelpDialog: Bool,
        showSettingsPrompt: Bool,
        lastFrameData: Data?,
        uploadState: UploadState
    ) {
        self.state = state
        self.feedback = feedback
        self.countdown = countdown
        self.showHelpDialog = showHelpDialog
        self.showSettingsPrompt = showSettingsPrompt
        self.lastFrameData = lastFrameData
        self.uploadState = uploadState
    }

    func showError(_ message: String) {
        self.errorMessage = message
        self.showError = true
    }

    func resetRecordingInProgress() {
        isRecordingInProgress = false
    }
}
