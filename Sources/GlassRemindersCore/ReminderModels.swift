import Foundation

public enum ScheduleMode: String, Codable, CaseIterable, Identifiable {
    case interval
    case fixedTimes
    case mixed

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .interval:
            return "Interval"
        case .fixedTimes:
            return "Fixed times"
        case .mixed:
            return "Mixed"
        }
    }
}

public enum ReminderVisualStyle: String, Codable, CaseIterable, Identifiable {
    case water
    case eyeDrops
    case custom

    public var id: String { rawValue }
}

public struct ReminderSchedule: Codable, Equatable {
    public var mode: ScheduleMode
    public var intervalMinutes: Int?
    public var activeStart: DayTime
    public var activeEnd: DayTime
    public var times: [DayTime]

    public init(
        mode: ScheduleMode,
        intervalMinutes: Int? = nil,
        activeStart: DayTime = DayTime(hour: 8, minute: 0),
        activeEnd: DayTime = DayTime(hour: 22, minute: 0),
        times: [DayTime] = []
    ) {
        self.mode = mode
        self.intervalMinutes = intervalMinutes
        self.activeStart = activeStart
        self.activeEnd = activeEnd
        self.times = times.removingDuplicates().sorted()
    }
}

public struct ReminderAsset: Codable, Equatable {
    public var style: ReminderVisualStyle
    public var bundledImageName: String?
    public var customImagePath: String?
    public var customSoundPath: String?

    public init(
        style: ReminderVisualStyle,
        bundledImageName: String? = nil,
        customImagePath: String? = nil,
        customSoundPath: String? = nil
    ) {
        self.style = style
        self.bundledImageName = bundledImageName
        self.customImagePath = customImagePath
        self.customSoundPath = customSoundPath
    }
}

public struct ReminderJob: Codable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var message: String
    public var enabled: Bool
    public var schedule: ReminderSchedule
    public var asset: ReminderAsset
    public var speechText: String
    public var actionLabel: String
    public var repeatUntilAcknowledged: Bool
    public var nagEveryMinutes: Int
    public var snoozeMinutes: Int
    public var volume: Double

    public init(
        id: String = UUID().uuidString,
        title: String,
        message: String,
        enabled: Bool = true,
        schedule: ReminderSchedule,
        asset: ReminderAsset,
        speechText: String,
        actionLabel: String,
        repeatUntilAcknowledged: Bool = true,
        nagEveryMinutes: Int,
        snoozeMinutes: Int = 10,
        volume: Double = 0.5
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.enabled = enabled
        self.schedule = schedule
        self.asset = asset
        self.speechText = speechText
        self.actionLabel = actionLabel
        self.repeatUntilAcknowledged = repeatUntilAcknowledged
        self.nagEveryMinutes = max(nagEveryMinutes, 1)
        self.snoozeMinutes = max(snoozeMinutes, 1)
        self.volume = min(max(volume, 0), 1)
    }
}

public struct ReminderState: Codable, Equatable {
    public var acknowledgedOccurrenceIDs: [String: String]
    public var activeOccurrenceIDs: [String: String]
    public var lastPresentedAt: [String: Date]
    public var snoozedUntil: [String: Date]
    public var skippedUntil: [String: Date]

    public init(
        acknowledgedOccurrenceIDs: [String: String] = [:],
        activeOccurrenceIDs: [String: String] = [:],
        lastPresentedAt: [String: Date] = [:],
        snoozedUntil: [String: Date] = [:],
        skippedUntil: [String: Date] = [:]
    ) {
        self.acknowledgedOccurrenceIDs = acknowledgedOccurrenceIDs
        self.activeOccurrenceIDs = activeOccurrenceIDs
        self.lastPresentedAt = lastPresentedAt
        self.snoozedUntil = snoozedUntil
        self.skippedUntil = skippedUntil
    }
}

public struct DueReminder: Equatable {
    public var job: ReminderJob
    public var occurrenceID: String
    public var scheduledAt: Date
    public var isTest: Bool

    public init(job: ReminderJob, occurrenceID: String, scheduledAt: Date, isTest: Bool = false) {
        self.job = job
        self.occurrenceID = occurrenceID
        self.scheduledAt = scheduledAt
        self.isTest = isTest
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
