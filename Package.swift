// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YouTubeDownloader",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "YouTubeDownloader",
            targets: ["YouTubeDownloader"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "YouTubeDownloader",
            dependencies: [],
            path: "Sources/YouTubeDownloader"
        )
    ]
)
