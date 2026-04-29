import XCTest
@testable import GlassRemindersCore

final class ScheduleCalculatorTests: XCTestCase {
    private var calendar: Calendar!
    private var calculator: ScheduleCalculator!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calculator = ScheduleCalculator(calendar: calendar)
    }

    func testWaterDefaultRunsEveryNinetyMinutesInsideActiveWindow() {
        let job = DefaultReminderFactory.waterReminder()
        let day = date(year: 2026, month: 4, day: 29, hour: 12, minute: 0)

        let dates = calculator.scheduledDates(for: job, on: day)
        let times = dates.map { timeString($0) }

        XCTAssertEqual(times, [
            "08:00",
            "09:30",
            "11:00",
            "12:30",
            "14:00",
            "15:30",
            "17:00",
            "18:30",
            "20:00",
            "21:30"
        ])
    }

    func testEyeDropDefaultCombinesEveryThreeHoursWithFixedTimesAndDedupes() {
        let job = DefaultReminderFactory.eyeDropsReminder()
        let day = date(year: 2026, month: 4, day: 29, hour: 12, minute: 0)

        let dates = calculator.scheduledDates(for: job, on: day)
        let times = dates.map { timeString($0) }

        XCTAssertEqual(times, [
            "08:00",
            "11:00",
            "13:15",
            "14:00",
            "17:00",
            "20:00",
            "20:30"
        ])
    }

    func testDueReminderRepeatsOnlyAfterNagIntervalUntilAcknowledged() {
        let job = DefaultReminderFactory.waterReminder()
        let dueAt = date(year: 2026, month: 4, day: 29, hour: 9, minute: 31)
        let occurrence = "2026-04-29T09:30"

        var state = ReminderState()
        var due = calculator.dueReminder(for: job, state: state, now: dueAt)
        XCTAssertEqual(due?.occurrenceID, occurrence)

        state.activeOccurrenceIDs[job.id] = occurrence
        state.lastPresentedAt[job.id] = dueAt
        due = calculator.dueReminder(
            for: job,
            state: state,
            now: date(year: 2026, month: 4, day: 29, hour: 9, minute: 34)
        )
        XCTAssertNil(due)

        due = calculator.dueReminder(
            for: job,
            state: state,
            now: date(year: 2026, month: 4, day: 29, hour: 9, minute: 36)
        )
        XCTAssertEqual(due?.occurrenceID, occurrence)

        state.acknowledgedOccurrenceIDs[job.id] = occurrence
        due = calculator.dueReminder(
            for: job,
            state: state,
            now: date(year: 2026, month: 4, day: 29, hour: 9, minute: 45)
        )
        XCTAssertNil(due)
    }

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }

    private func timeString(_ date: Date) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
