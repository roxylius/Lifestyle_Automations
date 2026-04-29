import AppKit
import GlassRemindersCore
import SwiftUI

struct ReminderPanelView: View {
    let dueReminder: DueReminder
    let onAcknowledge: () -> Void
    let onSnooze: () -> Void
    let onSkipToday: () -> Void

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(spacing: 16) {
                ReminderAnimationView(asset: dueReminder.job.asset)
                    .frame(width: 156, height: 156)
                    .padding(.top, 18)

                VStack(spacing: 6) {
                    Text(dueReminder.job.title)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text(dueReminder.job.message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                .padding(.horizontal, 28)

                HStack(spacing: 10) {
                    Button(action: onSnooze) {
                        Label("Snooze", systemImage: "clock")
                    }
                    .buttonStyle(.bordered)

                    Button(action: onSkipToday) {
                        Label("Skip today", systemImage: "forward.end")
                    }
                    .buttonStyle(.bordered)

                    Button(action: onAcknowledge) {
                        Label(dueReminder.job.actionLabel, systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .controlSize(.large)
                .padding(.bottom, 22)
            }
        }
        .frame(width: 430, height: 390)
        .padding(1)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
