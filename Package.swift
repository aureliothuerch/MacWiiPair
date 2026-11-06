// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacWiiPair",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacWiiPair",
            path: "Sources/MacWiiPair",
            // Swift 5 mode: Swift 6 flags the hook's static mutable state
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "MacWiiPairTests",
            dependencies: ["MacWiiPair"],
            path: "Tests/MacWiiPairTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
