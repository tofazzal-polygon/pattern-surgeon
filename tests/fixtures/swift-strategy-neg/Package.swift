// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftStrategyNeg",
    targets: [
        .target(name: "App", path: "Sources/App"),
        .testTarget(name: "AppTests", dependencies: ["App"], path: "Tests/AppTests"),
    ]
)
