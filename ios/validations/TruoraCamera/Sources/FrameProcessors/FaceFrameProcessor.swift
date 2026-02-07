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
    private let detector = CoreMLFaceDetector()
    private weak var delegate: CameraDelegate?

    init(delegate: CameraDelegate?) {
        self.delegate = delegate
        setupDetector()
    }

    func process(sampleBuffer: CMSampleBuffer) {
        detector.detectFaces(in: sampleBuffer)
    }

    private func setupDetector() {
        // Note: CoreMLFaceDetector already dispatches callbacks to main thread
        detector.onFacesDetected = { [weak self] detectionResults in
            self?.delegate?.detectionsReceived(detectionResults)
        }

        detector.onError = { error in
            // Frame detection errors are transient and should not interrupt user experience.
            // Individual frame failures are normal (e.g., motion blur, bad lighting) and
            // the camera will continue processing subsequent frames.
            #if DEBUG
            print("⚠️ FaceFrameProcessor: Frame detection error (non-fatal): \(error.localizedDescription)")
            #endif
        }
    }
}
