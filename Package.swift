// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BezelGlow",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "BezelGlow", targets: ["BezelGlow"]),
    ],
    targets: [
        .target(
            name: "BezelGlow",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "BezelGlowTests",
            dependencies: ["BezelGlow"]
        ),
    ]
)
