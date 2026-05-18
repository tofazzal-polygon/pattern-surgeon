// swift-tools-version:5.9
import PackageDescription

// Intentionally broken: a compile-time type error so `swift build` fails
// (router swift branch -> exit 2). This proves the safety harness refuses
// to operate on a red baseline.
let package = Package(
    name: "BaselineRedSwift",
    targets: [
        .target(name: "App", path: "Sources/App"),
    ]
)
