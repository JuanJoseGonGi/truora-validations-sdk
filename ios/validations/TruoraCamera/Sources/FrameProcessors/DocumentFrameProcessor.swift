//
//  DocumentFrameProcessor.swift
//  TruoraCamera
//
//  Created by Sergio Guzmán on 06/01/26.
//

import AVFoundation
import Foundation

/// Document frame processor that wraps DocumentDetector id detection model and forwards results to delegate
class DocumentFrameProcessor: FrameProcessor {
    private let detector = DocumentDetector()
    private weak var delegate: CameraDelegate?

    init(delegate: CameraDelegate?) {
        self.delegate = delegate
        setupDetector()
    }

    func process(sampleBuffer: CMSampleBuffer) {
        detector.detectID(in: sampleBuffer)
    }

    private func setupDetector() {
        // Note: DocumentDetector already dispatches callbacks to main thread
        detector.onIDDetected = { [weak self] detectionResults in
            self?.delegate?.detectionsReceived(detectionResults)
        }

        detector.onError = { error in
            // Frame detection errors are transient and should not interrupt user experience.
            // Individual frame failures are normal (e.g., motion blur, bad lighting) and
            // the camera will continue processing subsequent frames.
            #if DEBUG
            print("⚠️ DocumentFrameProcessor: Frame detection error (non-fatal): \(error.localizedDescription)")
            #endif
        }

        detector.onModelLoadFailed = { [weak self] error in
            // Model failed to load - notify delegate to fall back to manual capture
            // Error is passed for debugging purposes but UI should not show it to user
            self?.delegate?.autocaptureUnavailable(error: error)
        }
    }
}
