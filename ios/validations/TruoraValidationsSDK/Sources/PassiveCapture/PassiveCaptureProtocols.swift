//
//  PassiveCaptureProtocols.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 30/10/25.
//

import Foundation
import TruoraCamera
import UIKit

/// Protocol for updating the passive capture view.
/// Implementations should ensure UI updates are performed on the main thread.
@MainActor protocol PassiveCapturePresenterToView: AnyObject {
    func setupCamera()
    func startRecording()
    func stopRecording()
    func stopCamera()
    func pauseCamera()
    func resumeCamera()
    func pauseVideo()
    func resumeVideo()
    func updateUI(
        state: PassiveCaptureState,
        feedback: FeedbackType,
        countdown: Int,
        showHelpDialog: Bool,
        showSettingsPrompt: Bool,
        lastFrameData: Data?,
        uploadState: UploadState
    )
    func showError(_ message: String)

    /// Resets the recording in progress flag, re-enabling the record button
    func resetRecordingInProgress()
}

@MainActor
protocol PassiveCaptureViewToPresenter: AnyObject {
    func viewDidLoad() async
    func viewWillAppear() async
    func viewWillDisappear() async
    func appWillResignActive() async
    func appDidBecomeActive() async
    func cameraReady() async
    func cameraPermissionDenied() async
    func videoRecordingCompleted(videoData: Data) async
    func lastFrameCaptured(frameData: Data) async
    func detectionsReceived(_ results: [DetectionResult]) async
    func handleCaptureEvent(_ event: PassiveCaptureEvent) async
}

protocol PassiveCapturePresenterToInteractor: AnyObject {
    func setUploadUrl(_ uploadUrl: String?)
    func uploadVideo(_ videoData: Data)
}

@MainActor
protocol PassiveCaptureInteractorToPresenter: AnyObject {
    func videoUploadCompleted(validationId: String) async
    func videoUploadFailed(_ error: TruoraException) async
}
