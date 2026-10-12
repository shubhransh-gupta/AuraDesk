// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AuraDesk",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AuraDesk", targets: ["AuraDesk"])
    ],
    targets: [
        .executableTarget(
            name: "AuraDesk",
            path: "Sources/AuraDesk",
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
