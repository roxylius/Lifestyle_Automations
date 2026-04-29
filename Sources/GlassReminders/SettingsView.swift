import AppKit
import GlassRemindersCore
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var store: ReminderStore
    let onTest: (String) -> Void

    @State private var selectedID: String?
    @State private var draft: ReminderJob?
    @State private var activeStartText = "08:00"
    @State private var activeEndText = "22:00"
    @State private var fixedTimesText = ""
    @State private var statusMessage = ""

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 260)
                .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            editor
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if selectedID == nil {
                selectedID = store.jobs.first?.id
                loadDraft(for: selectedID)
            }
        }
        .onChange(of: selectedID) { newValue in
            loadDraft(for: newValue)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders")
                .font(.system(size: 18, weight: .semibold))
                .padding(.horizontal, 18)
                .padding(.top, 18)

            List(selection: $selectedID) {
                ForEach(store.jobs) { job in
                    HStack {
                        Image(systemName: job.enabled ? "bell.fill" : "bell.slash")
                            .foregroundStyle(job.enabled ? .blue : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(job.title)
                                .font(.system(size: 14, weight: .medium))
                            Text(scheduleSummary(job))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(job.id)
                }
            }

            HStack {
                Button {
                    let job = DefaultReminderFactory.customReminder()
                    store.add(job)
                    selectedID = job.id
                    loadDraft(for: job.id)
                } label: {
                    Label("Add", systemImage: "plus")
                }

                Button(role: .destructive) {
                    guard let selectedID else { return }
                    store.delete(jobID: selectedID)
                    self.selectedID = store.jobs.first?.id
                    loadDraft(for: self.selectedID)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedID == nil)
            }
            .padding(.horizontal, 18)

            Button {
                store.resetDefaults()
                selectedID = store.jobs.first?.id
                loadDraft(for: selectedID)
                statusMessage = "Defaults restored."
            } label: {
                Label("Restore Defaults", systemImage: "arrow.counterclockwise")
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private var editor: some View {
        if draft != nil {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    basicsSection
                    scheduleSection
                    mediaSection
                    actionsSection

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "bell")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text("No Reminder Selected")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(draft?.title ?? "Reminder")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("Configure the schedule, animation, sound, and acknowledgement behavior.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                saveDraft()
            } label: {
                Label("Save", systemImage: "checkmark")
            }
            .keyboardShortcut("s", modifiers: [.command])

            Button {
                if let id = draft?.id {
                    onTest(id)
                }
            } label: {
                Label("Test", systemImage: "play.fill")
            }
        }
    }

    private var basicsSection: some View {
        GroupBox("Basics") {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 14, verticalSpacing: 12) {
                GridRow {
                    Text("Enabled")
                    Toggle("", isOn: binding(\.enabled, default: true))
                        .labelsHidden()
                }
                GridRow {
                    Text("Title")
                    TextField("Drink water", text: binding(\.title, default: ""))
                        .textFieldStyle(.roundedBorder)
                }
                GridRow {
                    Text("Message")
                    TextField("Take a short break.", text: binding(\.message, default: ""))
                        .textFieldStyle(.roundedBorder)
                }
                GridRow {
                    Text("Voice text")
                    TextField("Drink water", text: binding(\.speechText, default: ""))
                        .textFieldStyle(.roundedBorder)
                }
                GridRow {
                    Text("Button label")
                    TextField("Done", text: binding(\.actionLabel, default: ""))
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var scheduleSection: some View {
        GroupBox("Schedule") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Mode", selection: scheduleModeBinding) {
                    ForEach(ScheduleMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Stepper("Every \(intervalBinding.wrappedValue) minutes", value: intervalBinding, in: 1...720)
                    TextField("Start", text: $activeStartText)
                        .frame(width: 84)
                        .textFieldStyle(.roundedBorder)
                    Text("to")
                        .foregroundStyle(.secondary)
                    TextField("End", text: $activeEndText)
                        .frame(width: 84)
                        .textFieldStyle(.roundedBorder)
                }

                TextField("Fixed times, comma separated, e.g. 08:00, 13:15, 20:30", text: $fixedTimesText)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Stepper("Nag every \(nagBinding.wrappedValue) minutes", value: nagBinding, in: 1...120)
                    Stepper("Snooze \(snoozeBinding.wrappedValue) minutes", value: snoozeBinding, in: 1...120)
                }

                Toggle("Repeat until acknowledged", isOn: binding(\.repeatUntilAcknowledged, default: true))
            }
        }
    }

    private var mediaSection: some View {
        GroupBox("Animation and sound") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Default animation", selection: visualStyleBinding) {
                    Text("Water").tag(ReminderVisualStyle.water)
                    Text("Eye drops").tag(ReminderVisualStyle.eyeDrops)
                    Text("Custom").tag(ReminderVisualStyle.custom)
                }
                .pickerStyle(.segmented)

                HStack {
                    Button {
                        chooseAnimation()
                    } label: {
                        Label("Choose GIF/PNG", systemImage: "photo")
                    }

                    Text(draft?.asset.customImagePath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "Using built-in animation")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Button {
                        chooseSound()
                    } label: {
                        Label("Choose Sound", systemImage: "speaker.wave.2")
                    }

                    Text(draft?.asset.customSoundPath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "Using system sound")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Text("Volume")
                    Slider(value: binding(\.volume, default: 0.5), in: 0...1)
                    Text("\(Int((draft?.volume ?? 0.5) * 100))%")
                        .frame(width: 44, alignment: .trailing)
                        .monospacedDigit()
                }
            }
        }
    }

    private var actionsSection: some View {
        HStack {
            Button {
                loadDraft(for: selectedID)
                statusMessage = "Changes reverted."
            } label: {
                Label("Revert", systemImage: "arrow.uturn.backward")
            }

            Button {
                saveDraft()
            } label: {
                Label("Save Changes", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var scheduleModeBinding: Binding<ScheduleMode> {
        Binding(
            get: { draft?.schedule.mode ?? .fixedTimes },
            set: { draft?.schedule.mode = $0 }
        )
    }

    private var visualStyleBinding: Binding<ReminderVisualStyle> {
        Binding(
            get: { draft?.asset.style ?? .custom },
            set: { draft?.asset.style = $0 }
        )
    }

    private var intervalBinding: Binding<Int> {
        Binding(
            get: { draft?.schedule.intervalMinutes ?? 90 },
            set: { draft?.schedule.intervalMinutes = $0 }
        )
    }

    private var nagBinding: Binding<Int> {
        Binding(
            get: { draft?.nagEveryMinutes ?? 10 },
            set: { draft?.nagEveryMinutes = $0 }
        )
    }

    private var snoozeBinding: Binding<Int> {
        Binding(
            get: { draft?.snoozeMinutes ?? 10 },
            set: { draft?.snoozeMinutes = $0 }
        )
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<ReminderJob, Value>, default defaultValue: Value) -> Binding<Value> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? defaultValue },
            set: { draft?[keyPath: keyPath] = $0 }
        )
    }

    private func loadDraft(for id: String?) {
        guard let id, let job = store.jobs.first(where: { $0.id == id }) else {
            draft = nil
            return
        }

        draft = job
        activeStartText = job.schedule.activeStart.description
        activeEndText = job.schedule.activeEnd.description
        fixedTimesText = job.schedule.times.map(\.description).joined(separator: ", ")
        statusMessage = ""
    }

    private func saveDraft() {
        guard var job = draft else {
            return
        }

        if let activeStart = DayTime(activeStartText) {
            job.schedule.activeStart = activeStart
        }
        if let activeEnd = DayTime(activeEndText) {
            job.schedule.activeEnd = activeEnd
        }
        job.schedule.times = DayTime.parseList(fixedTimesText)
        job.volume = min(max(job.volume, 0), 1)
        job.nagEveryMinutes = max(job.nagEveryMinutes, 1)
        job.snoozeMinutes = max(job.snoozeMinutes, 1)

        store.update(job)
        draft = job
        statusMessage = "Saved."
    }

    private func chooseAnimation() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.gif, .png, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let copiedPath = try store.copyAsset(from: url)
            draft?.asset.customImagePath = copiedPath
            draft?.asset.style = .custom
            statusMessage = "Animation selected. Save changes to persist it."
        } catch {
            statusMessage = "Could not copy animation: \(error)"
        }
    }

    private func chooseSound() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let copiedPath = try store.copyAsset(from: url)
            draft?.asset.customSoundPath = copiedPath
            statusMessage = "Sound selected. Save changes to persist it."
        } catch {
            statusMessage = "Could not copy sound: \(error)"
        }
    }

    private func scheduleSummary(_ job: ReminderJob) -> String {
        switch job.schedule.mode {
        case .interval:
            return "Every \(job.schedule.intervalMinutes ?? 0)m, \(job.schedule.activeStart)-\(job.schedule.activeEnd)"
        case .fixedTimes:
            return job.schedule.times.map(\.description).joined(separator: ", ")
        case .mixed:
            let interval = "Every \(job.schedule.intervalMinutes ?? 0)m"
            let fixed = job.schedule.times.map(\.description).joined(separator: ", ")
            return "\(interval) + \(fixed)"
        }
    }
}
