// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Nrova",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Nrova",
            targets: ["Nrova"]
        )
    ],
    targets: [
        .target(
            name: "Nrova",
            path: "Sources/Nrova"
        ),
        .testTarget(
            name: "NrovaTests",
            dependencies: ["Nrova"],
            path: "Tests/NrovaTests"
        )
    ]
)
