//
//  PassiveCaptureInteractor.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 30/10/25.
//

import Foundation

class PassiveCaptureInteractor {
    weak var presenter: PassiveCaptureInteractorToPresenter?
    let validationId: String
    private var uploadUrl: String?
    private var uploadTask: Task<Void, Never>?

    init(presenter: PassiveCaptureInteractorToPresenter, validationId: String) {
        self.presenter = presenter
        self.validationId = validationId
    }

    deinit {
        uploadTask?.cancel()
    }
}

extension PassiveCaptureInteractor: PassiveCapturePresenterToInteractor {
    func setUploadUrl(_ uploadUrl: String?) {
        self.uploadUrl = uploadUrl
    }

    func uploadVideo(_ videoData: Data) {
        print(
            "🟢 PassiveCaptureInteractor: Uploading video (\(videoData.count) bytes) "
                + "for validation \(validationId)..."
        )

        guard let presenter else {
            print("❌ PassiveCaptureInteractor: Presenter is nil")
            return
        }

        #if DEBUG
        if handleOfflineMode() { return }
        #endif

        let validated = validateUploadPreconditions(
            videoData: videoData,
            presenter: presenter
        )
        guard let validated else {
            return
        }

        uploadTask = Task {
            await performVideoUploadTask(
                videoData: videoData,
                apiClient: validated.apiClient,
                uploadUrl: validated.uploadUrl
            )
        }
    }

    #if DEBUG
    private func handleOfflineMode() -> Bool {
        guard TruoraValidationsSDK.isOfflineMode else { return false }
        print("🟢 PassiveCaptureInteractor: Offline mode, mocking successful upload")
        Task { await self.presenter?.videoUploadCompleted(validationId: self.validationId) }
        return true
    }
    #endif

    private func validateUploadPreconditions(
        videoData: Data,
        presenter: PassiveCaptureInteractorToPresenter
    ) -> (apiClient: TruoraAPIClient, uploadUrl: String)? {
        guard !videoData.isEmpty else {
            print("❌ PassiveCaptureInteractor: Video data is empty")
            let details = "Video data is empty"
            reportUploadError(presenter: presenter, type: .uploadFailed, details: details)
            return nil
        }

        guard let apiClient = ValidationConfig.shared.apiClient else {
            print("❌ PassiveCaptureInteractor: API client not configured")
            let details = "API client not configured"
            reportUploadError(presenter: presenter, type: .invalidConfiguration, details: details)
            return nil
        }

        guard let uploadUrl else {
            let details = "No upload URL provided"
            reportUploadError(presenter: presenter, type: .uploadFailed, details: details)
            return nil
        }

        if UploadUrlValidator.isExpired(uploadUrl) {
            print("❌ PassiveCaptureInteractor: Upload URL has expired (validation timeout)")
            let details = "Validation expired. The time limit was exceeded."
            reportUploadError(presenter: presenter, type: .validationError, details: details)
            return nil
        }

        return (apiClient, uploadUrl)
    }

    private func reportUploadError(
        presenter: PassiveCaptureInteractorToPresenter,
        type: SDKErrorType,
        details: String
    ) {
        Task { await presenter.videoUploadFailed(.sdk(SDKError(type: type, details: details))) }
    }

    private func performVideoUploadTask(
        videoData: Data,
        apiClient: TruoraAPIClient,
        uploadUrl: String
    ) async {
        do {
            print("🟢 PassiveCaptureInteractor: Upload URL obtained, uploading video...")

            // Upload video to presigned URL
            try await apiClient.uploadFile(
                uploadUrl: uploadUrl,
                fileData: videoData,
                contentType: "video/mp4"
            )

            guard !Task.isCancelled else {
                print("⚠️ PassiveCaptureInteractor: Upload task was cancelled")
                return
            }

            print("🟢 PassiveCaptureInteractor: Video uploaded successfully")

            // Navigate to result view immediately - polling will happen there
            await presenter?.videoUploadCompleted(validationId: validationId)
        } catch is CancellationError {
            print("⚠️ PassiveCaptureInteractor: Task was cancelled")
        } catch {
            print("❌ PassiveCaptureInteractor: Upload failed: \(error)")
            await presenter?.videoUploadFailed(
                .sdk(SDKError(type: .uploadFailed, details: error.localizedDescription))
            )
        }
    }
}
