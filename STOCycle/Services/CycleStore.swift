import Combine
import Foundation

@MainActor
final class CycleStore: ObservableObject {
    @Published private(set) var state: AppState

    let engine: CycleEngine

    private let defaults: UserDefaults
    private let storageKey = "sto.cycle.app-state.v1"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaults: UserDefaults = .standard,
        engine: CycleEngine = CycleEngine(),
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.defaults = defaults
        self.engine = engine
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if arguments.contains("-uiTestReset") {
            defaults.removeObject(forKey: storageKey)
        }

        if arguments.contains("-uiTestOnboarded") || arguments.contains("-demoData") {
            var demoState = AppState.demo()
            if arguments.contains("-uiTestReminderEnabled") {
                demoState.reminders = ReminderSettings(isEnabled: true, time: demoState.reminders.time)
            }
            self.state = demoState
        } else if let data = defaults.data(forKey: storageKey),
                  let decoded = try? decoder.decode(AppState.self, from: data) {
            self.state = decoded
        } else {
            self.state = AppState()
        }
    }

    var profile: CycleProfile { state.profile }
    var logs: [DailyLog] { state.logs }
    var hasCompletedOnboarding: Bool { state.hasCompletedOnboarding }

    func completeOnboarding(
        profile: CycleProfile,
        reminders: ReminderSettings = ReminderSettings()
    ) {
        var next = state
        next.profile = profile
        next.reminders = reminders
        next.hasCompletedOnboarding = true

        let start = engine.day(profile.lastPeriodStart)
        next.logs.removeAll { log in
            let distance = engine.calendar.dateComponents([.day], from: start, to: engine.day(log.date)).day ?? -1
            return (0..<profile.averagePeriodLength).contains(distance)
        }

        for offset in 0..<profile.averagePeriodLength {
            guard let date = engine.calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            next.logs.append(
                DailyLog(
                    date: date,
                    isPeriod: true
                )
            )
        }

        state = next
        persist()
    }

    func log(on date: Date) -> DailyLog? {
        engine.log(on: date, in: state.logs)
    }

    func save(_ log: DailyLog) {
        var next = state
        let normalized = engine.day(log.date)
        var normalizedLog = log
        normalizedLog.date = normalized
        if !normalizedLog.isPeriod { normalizedLog.flow = nil }

        if let index = next.logs.firstIndex(where: { engine.sameDay($0.date, normalized) }) {
            if normalizedLog.hasDetails {
                next.logs[index] = normalizedLog
            } else {
                next.logs.remove(at: index)
            }
        } else if normalizedLog.hasDetails {
            next.logs.append(normalizedLog)
        }

        next.logs.sort { $0.date < $1.date }
        state = next
        persist()
    }

    func updateProfile(cycleLength: Int, periodLength: Int) {
        var next = state
        next.profile.averageCycleLength = min(max(cycleLength, 15), 60)
        next.profile.averagePeriodLength = min(max(periodLength, 1), min(15, next.profile.averageCycleLength - 1))
        state = next
        persist()
    }

    func updatePersonalization(
        goals: Set<TrackingGoal>,
        regularity: CycleRegularity,
        hormoneContext: HormoneContext,
        focusSymptoms: Set<Symptom>
    ) {
        var next = state
        next.profile.goals = goals.isEmpty ? [.predictPeriods] : goals
        next.profile.regularity = regularity
        next.profile.hormoneContext = hormoneContext
        next.profile.focusSymptoms = focusSymptoms
        state = next
        persist()
    }

    func updateReminders(enabled: Bool, time: Date) {
        var next = state
        next.reminders = ReminderSettings(isEnabled: enabled, time: time)
        state = next
        persist()
    }

    func resetAllData() {
        state = AppState()
        defaults.removeObject(forKey: storageKey)
    }

    func exportText() -> String {
        guard let data = try? encoder.encode(state),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    private func persist() {
        guard let data = try? encoder.encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
