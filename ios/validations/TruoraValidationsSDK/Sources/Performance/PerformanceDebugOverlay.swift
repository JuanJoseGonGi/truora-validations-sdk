//
//  PerformanceDebugOverlay.swift
//  TruoraValidationsSDK
//

#if DEBUG

import SwiftUI

/// Semi-transparent on-screen overlay showing the current adaptive performance state.
/// Only included in DEBUG builds — never shipped to production.
///
/// Usage in a SwiftUI View body (within a ZStack):
/// ```swift
/// #if DEBUG
/// if let advisor = viewModel.performanceAdvisor {
///     PerformanceDebugOverlay(advisor: advisor)
/// }
/// #endif
/// ```
struct PerformanceDebugOverlay: View {
    let advisor: PerformanceAdvisor

    @State private var displayText: String = ""
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading) {
            Text(displayText)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(.green)
                .padding(8)
                .background(Color.black.opacity(0.6))
                .cornerRadius(6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 50)
        .padding(.leading, 8)
        .allowsHitTesting(false)
        .onAppear { updateText() }
        .onReceive(timer) { _ in updateText() }
    }

    private func updateText() {
        let res = advisor.recommendedVideoResolution
        let jpeg = String(format: "%.2f", Double(advisor.recommendedJpegQuality))
        let tflite = advisor.recommendedTFLiteThreadCount
        let maxImg = Int(advisor.recommendedMaxImageSize)
        let auto = advisor.shouldUseAutocapture ? "ON" : "OFF"
        let avgMs = Int(advisor.inferenceTracker.averageSeconds * 1000)
        let speed = advisor.inferenceTracker.speed

        displayText = """
        [PERF DEBUG]
        res:  \(res.maxWidth)x\(res.maxHeight)
        auto: \(auto)
        jpeg: \(jpeg)
        tfl:  \(tflite) threads
        img:  \(maxImg)px
        inf:  \(avgMs)ms \(speed)
        """
    }
}

#endif
