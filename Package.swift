// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Drawg",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Drawg",
            dependencies: ["KeyboardShortcuts"],
            path: "Sources/Drawg"
        )
    ]
)
