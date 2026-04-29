import AppKit
import GlassRemindersCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: ReminderStore!
    private var panelController: ReminderPanelController!
    private var scheduler: ReminderScheduler!
    private var statusBarController: StatusBarController!
    private var settingsWindowController: SettingsWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        store = ReminderStore()
        do {
            try store.load()
        } catch {
            NSLog("GlassReminders: failed to load store: \(error)")
        }

        panelController = ReminderPanelController(store: store)
        scheduler = ReminderScheduler(store: store, presenter: panelController)
        settingsWindowController = SettingsWindowController(store: store, scheduler: scheduler)
        statusBarController = StatusBarController(
            onSettings: { [weak self] in self?.settingsWindowController.show() },
            onTestWater: { [weak self] in self?.scheduler.presentTest(jobID: "water") },
            onTestEyeDrops: { [weak self] in self?.scheduler.presentTest(jobID: "eye-drops") },
            onRevealConfig: { [weak self] in self?.revealConfigFolder() },
            onQuit: { NSApp.terminate(nil) }
        )

        scheduler.start()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc private func handleWake() {
        scheduler.evaluateNow()
    }

    private func revealConfigFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([store.storageDirectory])
    }
}
