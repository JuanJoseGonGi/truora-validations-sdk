// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TruoraValidationsSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "TruoraValidationsSDK",
            targets: ["TruoraValidationsSDK"]
        ),
        .library(
            name: "TruoraCamera",
            targets: ["TruoraCamera"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TruoraValidationsSDK",
            dependencies: ["TruoraCamera"],
            path: "ios/validations/TruoraValidationsSDK/Sources",
            resources: [.process("../Resources")],
            swiftSettings: [.define("SWIFT_PACKAGE")]
        ),
        .target(
            name: "TruoraCamera",
            dependencies: ["TensorFlowLite"],
            path: "ios/validations/TruoraCamera/Sources",
            resources: [
                .process("Assets.xcassets"),
                .process("../Resources")
            ]
        ),
        .target(
            name: "TensorFlowLite",
            dependencies: ["TensorFlowLiteC"],
            path: "ios/validations/TensorFlowLite/Sources"
        ),
        .binaryTarget(
            name: "TensorFlowLiteC",
            path: "ios/validations/XCFrameworks/TensorFlowLiteC.xcframework"
        )
    ]
)
