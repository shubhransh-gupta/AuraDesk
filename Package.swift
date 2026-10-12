// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AetherWall",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AetherWall", targets: ["AetherWall"])
    ],
    targets: [
        .executableTarget(
            name: "AetherWall",
            path: "Sources/AetherWall",
            resources: [
                .copy("Resources/curated_4k_catalog.json")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AVKit"),
                .linkedFramework("CoreMedia"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
