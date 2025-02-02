// swift-tools-version: 5.10.0

import PackageDescription

let package = Package(
    name: "teemoji",
    platforms: [
        .macOS(.v11)
    ],
    targets: [
        .executableTarget(
            name: "teemoji",
            resources: [.copy("TeemojiClassifier.mlmodelc")]
        ),
        .testTarget(
            name: "TeemojiTests",
            dependencies: ["teemoji"],
            resources: [.copy("TeemojiClassifier.mlmodelc")]
        ),
    ]
)
