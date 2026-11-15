// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SoundLadder",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SoundLadder",
            path: "Sources/SoundLadder",
            linkerSettings: [.linkedFramework("CoreAudio"), .linkedFramework("ServiceManagement")]
        )
    ]
)
