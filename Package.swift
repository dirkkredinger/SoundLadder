// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AudioPriority",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "AudioPriority",
            path: "Sources/AudioPriority",
            linkerSettings: [.linkedFramework("CoreAudio"), .linkedFramework("ServiceManagement")]
        )
    ]
)
