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
    private let detector: DocumentDetector
    private weak var delegate: CameraDelegate?

    /// Callback invoked with inference latency in seconds after each detection.
    /// Set by the host module to feed into the performance advisor's inference tracker.
    var onInferenceLatency: ((TimeInterval) -> Void)?

    init(delegate: CameraDelegate?, logger: MLLifecycleLogger? = nil, tfliteThreadCount: Int = 2) {
        self.delegate = delegate
        self.detector = DocumentDetector(logger: logger, tfliteThreadCount: tfliteThreadCount)
        setupDetector()
    }

    func process(sampleBuffer: CMSampleBuffer) {
        inferenceStartTime = CACurrentMediaTime()
        detector.detectID(in: sampleBuffer)
    }

    /// Tracks the start time of the current inference for latency measurement
    private var inferenceStartTime: CFTimeInterval = 0

    private func setupDetector() {
        // Note: DocumentDetector already dispatches callbacks to main thread
        detector.onIDDetected = { [weak self] detectionResults in
            if let start = self?.inferenceStartTime, start > 0 {
                let latency = CACurrentMediaTime() - start
                self?.onInferenceLatency?(latency)
            }
            self?.delegate?.detectionsReceived(detectionResults)
        }

        detector.onError = { [weak self] error in
            // Record latency even on error so the tracker sees slow frames
            if let start = self?.inferenceStartTime, start > 0 {
                let latency = CACurrentMediaTime() - start
                self?.onInferenceLatency?(latency)
            }
            // Frame detection errors are transient and should not interrupt user experience.
            // Individual frame failures are normal (e.g., motion blur, bad lighting) and
            // the camera will continue processing subsequent frames.
            debugLog("⚠️ DocumentFrameProcessor: Frame detection error (non-fatal): \(error.localizedDescription)")
        }

        detector.onModelLoadFailed = { [weak self] error in
            // Model failed to load - notify delegate to fall back to manual capture
            // Error is passed for debugging purposes but UI should not show it to user
            self?.delegate?.autocaptureUnavailable(error: error)
        }
    }
}
