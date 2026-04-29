import AppKit
import GlassRemindersCore
import SwiftUI

final class SettingsWindowController {
    private let store: ReminderStore
    private let scheduler: ReminderScheduler
    private var window: NSWindow?

    init(store: ReminderStore, scheduler: ReminderScheduler) {
        self.store = store
        self.scheduler = scheduler
    }

    func show() {
        if window == nil {
            let view = SettingsView(
                store: store,
                onTest: { [weak scheduler] jobID in
                    scheduler?.presentTest(jobID: jobID)
                }
            )
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 920, height: 620),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Glass Reminders"
            window.contentView = NSHostingView(rootView: view)
            window.center()
            self.window = window
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
