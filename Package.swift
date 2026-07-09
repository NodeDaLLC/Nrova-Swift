// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NodeDa",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "NodeDa",
            targets: ["NodeDa"]
        )
    ],
    targets: [
        .target(
            name: "NodeDa",
            path: "Sources/NodeDa"
        ),
        .testTarget(
            name: "NodeDaTests",
            dependencies: ["NodeDa"],
            path: "Tests/NodeDaTests"
        )
    ]
)
