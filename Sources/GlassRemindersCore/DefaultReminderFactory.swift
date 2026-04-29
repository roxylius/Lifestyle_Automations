import Foundation

public enum DefaultReminderFactory {
    public static func defaultJobs() -> [ReminderJob] {
        [
            waterReminder(),
            eyeDropsReminder()
        ]
    }

    public static func waterReminder() -> ReminderJob {
        ReminderJob(
            id: "water",
            title: "Drink water",
            message: "Take a short break and drink water.",
            schedule: ReminderSchedule(
                mode: .interval,
                intervalMinutes: 90,
                activeStart: DayTime(hour: 8, minute: 0),
                activeEnd: DayTime(hour: 22, minute: 0)
            ),
            asset: ReminderAsset(style: .water, bundledImageName: "drink-water.gif"),
            speechText: "Drink water",
            actionLabel: "Drank water",
            repeatUntilAcknowledged: true,
            nagEveryMinutes: 5,
            snoozeMinutes: 10,
            volume: 0.5
        )
    }

    public static func eyeDropsReminder() -> ReminderJob {
        ReminderJob(
            id: "eye-drops",
            title: "Put eye drops",
            message: "Use your eye drops now.",
            schedule: ReminderSchedule(
                mode: .mixed,
                intervalMinutes: 180,
                activeStart: DayTime(hour: 8, minute: 0),
                activeEnd: DayTime(hour: 20, minute: 0),
                times: [
                    DayTime(hour: 8, minute: 0),
                    DayTime(hour: 13, minute: 15),
                    DayTime(hour: 20, minute: 30)
                ]
            ),
            asset: ReminderAsset(style: .eyeDrops, bundledImageName: "cat-eye-drops.gif"),
            speechText: "Put eye drops",
            actionLabel: "Done",
            repeatUntilAcknowledged: true,
            nagEveryMinutes: 10,
            snoozeMinutes: 10,
            volume: 0.5
        )
    }

    public static func customReminder() -> ReminderJob {
        ReminderJob(
            title: "New reminder",
            message: "Reminder time.",
            schedule: ReminderSchedule(
                mode: .fixedTimes,
                times: [DayTime(hour: 9, minute: 0)]
            ),
            asset: ReminderAsset(style: .custom),
            speechText: "Reminder",
            actionLabel: "Done",
            repeatUntilAcknowledged: true,
            nagEveryMinutes: 10,
            snoozeMinutes: 10,
            volume: 0.5
        )
    }
}
