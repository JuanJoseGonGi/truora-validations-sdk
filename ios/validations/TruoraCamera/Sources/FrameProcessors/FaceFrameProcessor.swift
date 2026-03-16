//
//  FaceFrameProcessor.swift
//  TruoraCamera
//
//  Created by Brayan Escobar on 11/26/25.
//

import AVFoundation
import Foundation

/// Face frame processor that wraps CoreMLFaceDetector and forwards results to delegate
class FaceFrameProcessor: FrameProcessor {
    private let detector: CoreMLFaceDetector
    private weak var delegate: CameraDelegate?

    /// Callback invoked with inference latency in seconds after each detection.
    /// Set by the host module to feed into the performance advisor's inference tracker.
    var onInferenceLatency: ((TimeInterval) -> Void)?

    init(delegate: CameraDelegate?, logger: MLLifecycleLogger? = nil) {
        self.delegate = delegate
        self.detector = CoreMLFaceDetector(logger: logger)
        setupDetector()
    }

    func process(sampleBuffer: CMSampleBuffer) {
        let startTime = CACurrentMediaTime()
        inferenceStartTime = startTime
        detector.detectFaces(in: sampleBuffer)
    }

    /// Tracks the start time of the current inference for latency measurement
    private var inferenceStartTime: CFTimeInterval = 0

    private func setupDetector() {
        // Note: CoreMLFaceDetector already dispatches callbacks to main thread
        detector.onFacesDetected = { [weak self] detectionResults in
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
            debugLog("⚠️ FaceFrameProcessor: Frame detection error (non-fatal): \(error.localizedDescription)")
        }
    }
}
