import Foundation

public struct ScheduleCalculator {
    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func scheduledDates(for job: ReminderJob, on day: Date) -> [Date] {
        var dates = Set<Date>()

        if job.schedule.mode == .interval || job.schedule.mode == .mixed {
            intervalDates(for: job.schedule, on: day).forEach { dates.insert($0) }
        }

        if job.schedule.mode == .fixedTimes || job.schedule.mode == .mixed {
            job.schedule.times.forEach { time in
                if let date = date(on: day, at: time) {
                    dates.insert(date)
                }
            }
        }

        return dates.sorted()
    }

    public func dueReminder(for job: ReminderJob, state: ReminderState, now: Date = Date()) -> DueReminder? {
        guard job.enabled else {
            return nil
        }

        if let skippedUntil = state.skippedUntil[job.id], skippedUntil > now {
            return nil
        }

        if let snoozedUntil = state.snoozedUntil[job.id], snoozedUntil > now {
            return nil
        }

        let candidates = scheduledDates(for: job, on: now)
            .filter { $0 <= now }
            .sorted()

        guard let scheduledAt = candidates.last else {
            return nil
        }

        let occurrenceID = Self.occurrenceID(for: scheduledAt, calendar: calendar)
        if state.acknowledgedOccurrenceIDs[job.id] == occurrenceID {
            return nil
        }

        if job.repeatUntilAcknowledged,
           state.activeOccurrenceIDs[job.id] == occurrenceID,
           let lastPresentedAt = state.lastPresentedAt[job.id] {
            let nagInterval = TimeInterval(job.nagEveryMinutes * 60)
            if now.timeIntervalSince(lastPresentedAt) < nagInterval {
                return nil
            }
        }

        return DueReminder(job: job, occurrenceID: occurrenceID, scheduledAt: scheduledAt)
    }

    public func nextScheduledDate(after now: Date = Date(), for job: ReminderJob) -> Date? {
        for offset in 0...14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else {
                continue
            }

            if let next = scheduledDates(for: job, on: day).first(where: { $0 > now }) {
                return next
            }
        }

        return nil
    }

    public static func occurrenceID(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return String(
            format: "%04d-%02d-%02dT%02d:%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0,
            components.minute ?? 0
        )
    }

    public func startOfNextDay(after date: Date = Date()) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: start) ?? date.addingTimeInterval(86_400)
    }

    private func intervalDates(for schedule: ReminderSchedule, on day: Date) -> [Date] {
        guard let intervalMinutes = schedule.intervalMinutes, intervalMinutes > 0,
              var cursor = date(on: day, at: schedule.activeStart),
              var end = date(on: day, at: schedule.activeEnd)
        else {
            return []
        }

        if end < cursor, let adjustedEnd = calendar.date(byAdding: .day, value: 1, to: end) {
            end = adjustedEnd
        }

        var dates: [Date] = []
        while cursor <= end {
            dates.append(cursor)
            guard let next = calendar.date(byAdding: .minute, value: intervalMinutes, to: cursor) else {
                break
            }
            cursor = next
        }

        return dates
    }

    private func date(on day: Date, at time: DayTime) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0
        components.nanosecond = 0
        return calendar.date(from: components)
    }
}
