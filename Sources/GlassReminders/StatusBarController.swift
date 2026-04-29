import AppKit

final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onSettings: () -> Void
    private let onTestWater: () -> Void
    private let onTestEyeDrops: () -> Void
    private let onRevealConfig: () -> Void
    private let onQuit: () -> Void

    init(
        onSettings: @escaping () -> Void,
        onTestWater: @escaping () -> Void,
        onTestEyeDrops: @escaping () -> Void,
        onRevealConfig: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onSettings = onSettings
        self.onTestWater = onTestWater
        self.onTestEyeDrops = onTestEyeDrops
        self.onRevealConfig = onRevealConfig
        self.onQuit = onQuit
        super.init()
        configure()
    }

    private func configure() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "Glass Reminders")
            button.toolTip = "Glass Reminders"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Test Water Reminder", action: #selector(testWater), keyEquivalent: "w"))
        menu.addItem(NSMenuItem(title: "Test Eye Drops Reminder", action: #selector(testEyeDrops), keyEquivalent: "e"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Reveal Config Folder", action: #selector(revealConfig), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
    }

    @objc private func openSettings() {
        onSettings()
    }

    @objc private func testWater() {
        onTestWater()
    }

    @objc private func testEyeDrops() {
        onTestEyeDrops()
    }

    @objc private func revealConfig() {
        onRevealConfig()
    }

    @objc private func quit() {
        onQuit()
    }
}
