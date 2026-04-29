import AppKit
import GlassRemindersCore
import SwiftUI

final class ReminderPanelController: ReminderPresenting {
    private let store: ReminderStore
    private let audioPlayer = AudioCuePlayer()
    private var panel: GlassPanel?

    init(store: ReminderStore) {
        self.store = store
    }

    func present(_ dueReminder: DueReminder) {
        audioPlayer.stop()
        audioPlayer.play(for: dueReminder.job)

        let panel = panel ?? makePanel()
        self.panel = panel

        panel.contentView = ClearHostingView(
            rootView: ReminderPanelView(
                dueReminder: dueReminder,
                onAcknowledge: { [weak self] in self?.acknowledge(dueReminder) },
                onSnooze: { [weak self] in self?.snooze(dueReminder) },
                onSkipToday: { [weak self] in self?.skipToday(dueReminder) }
            )
        )

        position(panel)
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func acknowledge(_ dueReminder: DueReminder) {
        audioPlayer.stop()
        if !dueReminder.isTest {
            store.acknowledge(jobID: dueReminder.job.id, occurrenceID: dueReminder.occurrenceID)
        }
        panel?.orderOut(nil)
    }

    private func snooze(_ dueReminder: DueReminder) {
        audioPlayer.stop()
        if !dueReminder.isTest {
            store.snooze(jobID: dueReminder.job.id, minutes: dueReminder.job.snoozeMinutes)
        }
        panel?.orderOut(nil)
    }

    private func skipToday(_ dueReminder: DueReminder) {
        audioPlayer.stop()
        if !dueReminder.isTest {
            store.skipToday(jobID: dueReminder.job.id)
        }
        panel?.orderOut(nil)
    }

    private func makePanel() -> GlassPanel {
        let panel = GlassPanel(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 390),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        return panel
    }

    private func position(_ panel: NSPanel) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = panel.frame.size
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.midY - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}

final class GlassPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class ClearHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
}
