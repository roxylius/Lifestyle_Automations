import Foundation
import GlassRemindersCore

protocol ReminderPresenting: AnyObject {
    func present(_ dueReminder: DueReminder)
}

final class ReminderScheduler {
    private let store: ReminderStore
    private weak var presenter: ReminderPresenting?
    private let calculator = ScheduleCalculator()
    private var timer: Timer?

    init(store: ReminderStore, presenter: ReminderPresenting) {
        self.store = store
        self.presenter = presenter
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.evaluateNow()
        }
        evaluateNow()
    }

    func evaluateNow() {
        evaluate(at: Date())
    }

    func presentTest(jobID: String) {
        guard let job = store.jobs.first(where: { $0.id == jobID }) else {
            return
        }

        let due = DueReminder(
            job: job,
            occurrenceID: "manual-\(UUID().uuidString)",
            scheduledAt: Date(),
            isTest: true
        )
        presenter?.present(due)
    }

    private func evaluate(at now: Date) {
        for job in store.jobs where job.enabled {
            guard let due = calculator.dueReminder(for: job, state: store.state, now: now) else {
                continue
            }

            store.markPresented(jobID: job.id, occurrenceID: due.occurrenceID, at: now)
            presenter?.present(due)
            return
        }
    }
}
