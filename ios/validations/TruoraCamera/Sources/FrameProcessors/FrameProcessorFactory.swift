//
//  FrameProcessorFactory.swift
//  TruoraCamera
//
//  Created by Brayan Escobar on 11/26/25.
//

import Foundation

/// Factory for creating frame processors based on detection type
public class FrameProcessorFactory {
    public static func createProcessor(
        for type: DetectionType,
        delegate: CameraDelegate?,
        logger: MLLifecycleLogger? = nil
    ) -> FrameProcessor? {
        switch type {
        case .face:
            FaceFrameProcessor(delegate: delegate, logger: logger)
        case .document:
            DocumentFrameProcessor(delegate: delegate, logger: logger)
        case .none:
            nil
        }
    }
}
