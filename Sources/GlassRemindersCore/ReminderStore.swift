import Combine
import Foundation

public final class ReminderStore: ObservableObject {
    public enum StoreError: Error {
        case missingAsset(URL)
    }

    @Published public private(set) var jobs: [ReminderJob] = []
    @Published public private(set) var state = ReminderState()

    public let storageDirectory: URL

    private var remindersURL: URL {
        storageDirectory.appendingPathComponent("reminders.json")
    }

    private var stateURL: URL {
        storageDirectory.appendingPathComponent("state.json")
    }

    private var assetsDirectory: URL {
        storageDirectory.appendingPathComponent("Assets")
    }

    public init(storageDirectory: URL = ReminderStore.defaultStorageDirectory()) {
        self.storageDirectory = storageDirectory
    }

    public static func defaultStorageDirectory() -> URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GlassReminders", isDirectory: true)
    }

    public func load() throws {
        try FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: remindersURL.path) {
            do {
                let data = try Data(contentsOf: remindersURL)
                jobs = try Self.decoder.decode(PersistedReminders.self, from: data).reminders
            } catch {
                jobs = DefaultReminderFactory.defaultJobs()
                try saveJobs()
            }
        } else {
            jobs = DefaultReminderFactory.defaultJobs()
            try saveJobs()
        }

        if FileManager.default.fileExists(atPath: stateURL.path) {
            do {
                let data = try Data(contentsOf: stateURL)
                state = try Self.decoder.decode(ReminderState.self, from: data)
            } catch {
                state = ReminderState()
                try saveState()
            }
        } else {
            state = ReminderState()
            try saveState()
        }
    }

    public func add(_ job: ReminderJob) {
        jobs.append(job)
        try? saveJobs()
    }

    public func update(_ job: ReminderJob) {
        guard let index = jobs.firstIndex(where: { $0.id == job.id }) else {
            return
        }

        jobs[index] = job
        try? saveJobs()
    }

    public func delete(jobID: String) {
        jobs.removeAll { $0.id == jobID }
        clearState(for: jobID)
        try? saveJobs()
        try? saveState()
    }

    public func resetDefaults() {
        jobs = DefaultReminderFactory.defaultJobs()
        state = ReminderState()
        try? saveJobs()
        try? saveState()
    }

    public func markPresented(jobID: String, occurrenceID: String, at date: Date = Date()) {
        state.activeOccurrenceIDs[jobID] = occurrenceID
        state.lastPresentedAt[jobID] = date
        try? saveState()
    }

    public func acknowledge(jobID: String, occurrenceID: String) {
        state.acknowledgedOccurrenceIDs[jobID] = occurrenceID
        state.activeOccurrenceIDs.removeValue(forKey: jobID)
        state.lastPresentedAt.removeValue(forKey: jobID)
        state.snoozedUntil.removeValue(forKey: jobID)
        try? saveState()
    }

    public func snooze(jobID: String, minutes: Int, from date: Date = Date()) {
        state.snoozedUntil[jobID] = date.addingTimeInterval(TimeInterval(max(minutes, 1) * 60))
        try? saveState()
    }

    public func skipToday(jobID: String, now: Date = Date(), calendar: Calendar = .current) {
        let calculator = ScheduleCalculator(calendar: calendar)
        state.skippedUntil[jobID] = calculator.startOfNextDay(after: now)
        state.activeOccurrenceIDs.removeValue(forKey: jobID)
        state.lastPresentedAt.removeValue(forKey: jobID)
        try? saveState()
    }

    public func copyAsset(from sourceURL: URL) throws -> String {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw StoreError.missingAsset(sourceURL)
        }

        try FileManager.default.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)
        let fileName = "\(UUID().uuidString)-\(sourceURL.lastPathComponent)"
        let targetURL = assetsDirectory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: targetURL.path) {
            try FileManager.default.removeItem(at: targetURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: targetURL)
        return targetURL.path
    }

    private func clearState(for jobID: String) {
        state.acknowledgedOccurrenceIDs.removeValue(forKey: jobID)
        state.activeOccurrenceIDs.removeValue(forKey: jobID)
        state.lastPresentedAt.removeValue(forKey: jobID)
        state.snoozedUntil.removeValue(forKey: jobID)
        state.skippedUntil.removeValue(forKey: jobID)
    }

    private func saveJobs() throws {
        let payload = PersistedReminders(schemaVersion: 1, reminders: jobs)
        try Self.encoder.encode(payload).write(to: remindersURL, options: [.atomic])
    }

    private func saveState() throws {
        try Self.encoder.encode(state).write(to: stateURL, options: [.atomic])
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private struct PersistedReminders: Codable {
    var schemaVersion: Int
    var reminders: [ReminderJob]
}
