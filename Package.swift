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
                .copy("Resources/curated_4k_catalog.json"),
                .copy("Resources/hero-center-mac.png"),
                .copy("Resources/mac-battery.png"),
                .copy("Resources/mac-cloud.png"),
                .copy("Resources/mac-desktop.png"),
                .copy("Resources/mac-lockscreen.png"),
                .copy("Resources/mac-mchip.png"),
                .copy("Resources/mac-multimonitor.png"),
                .copy("Resources/mac-screensaver.png")
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
