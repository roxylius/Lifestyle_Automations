// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GlassReminders",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "GlassReminders", targets: ["GlassReminders"])
    ],
    targets: [
        .target(
            name: "GlassRemindersCore",
            path: "Sources/GlassRemindersCore"
        ),
        .executableTarget(
            name: "GlassReminders",
            dependencies: ["GlassRemindersCore"],
            path: "Sources/GlassReminders"
        ),
        .testTarget(
            name: "GlassRemindersCoreTests",
            dependencies: ["GlassRemindersCore"],
            path: "Tests/GlassRemindersCoreTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
