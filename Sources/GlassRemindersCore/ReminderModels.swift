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

public enum AudioPlaybackMode: String, Codable, CaseIterable, Identifiable {
    case loopUntilAction
    case repeatCount

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .loopUntilAction:
            return "Loop until action"
        case .repeatCount:
            return "Repeat count"
        }
    }
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
    public var audioPlaybackMode: AudioPlaybackMode
    public var audioRepeatCount: Int
    public var audioRepeatGapSeconds: Double
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
        audioPlaybackMode: AudioPlaybackMode = .loopUntilAction,
        audioRepeatCount: Int = 3,
        audioRepeatGapSeconds: Double = 1.5,
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
        self.audioPlaybackMode = audioPlaybackMode
        self.audioRepeatCount = max(audioRepeatCount, 1)
        self.audioRepeatGapSeconds = max(audioRepeatGapSeconds, 0)
        self.volume = min(max(volume, 0), 1)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case enabled
        case schedule
        case asset
        case speechText
        case actionLabel
        case repeatUntilAcknowledged
        case nagEveryMinutes
        case snoozeMinutes
        case audioPlaybackMode
        case audioRepeatCount
        case audioRepeatGapSeconds
        case volume
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            title: try container.decode(String.self, forKey: .title),
            message: try container.decode(String.self, forKey: .message),
            enabled: try container.decode(Bool.self, forKey: .enabled),
            schedule: try container.decode(ReminderSchedule.self, forKey: .schedule),
            asset: try container.decode(ReminderAsset.self, forKey: .asset),
            speechText: try container.decode(String.self, forKey: .speechText),
            actionLabel: try container.decode(String.self, forKey: .actionLabel),
            repeatUntilAcknowledged: try container.decode(Bool.self, forKey: .repeatUntilAcknowledged),
            nagEveryMinutes: try container.decode(Int.self, forKey: .nagEveryMinutes),
            snoozeMinutes: try container.decode(Int.self, forKey: .snoozeMinutes),
            audioPlaybackMode: try container.decodeIfPresent(AudioPlaybackMode.self, forKey: .audioPlaybackMode) ?? .loopUntilAction,
            audioRepeatCount: try container.decodeIfPresent(Int.self, forKey: .audioRepeatCount) ?? 3,
            audioRepeatGapSeconds: try container.decodeIfPresent(Double.self, forKey: .audioRepeatGapSeconds) ?? 1.5,
            volume: try container.decode(Double.self, forKey: .volume)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(schedule, forKey: .schedule)
        try container.encode(asset, forKey: .asset)
        try container.encode(speechText, forKey: .speechText)
        try container.encode(actionLabel, forKey: .actionLabel)
        try container.encode(repeatUntilAcknowledged, forKey: .repeatUntilAcknowledged)
        try container.encode(nagEveryMinutes, forKey: .nagEveryMinutes)
        try container.encode(snoozeMinutes, forKey: .snoozeMinutes)
        try container.encode(audioPlaybackMode, forKey: .audioPlaybackMode)
        try container.encode(audioRepeatCount, forKey: .audioRepeatCount)
        try container.encode(audioRepeatGapSeconds, forKey: .audioRepeatGapSeconds)
        try container.encode(volume, forKey: .volume)
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
