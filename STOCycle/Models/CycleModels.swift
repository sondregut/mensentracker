import Foundation
import SwiftUI

enum CyclePhase: String, Codable, CaseIterable, Identifiable {
    case menstruation
    case follicular
    case ovulation
    case luteal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .menstruation: "Menstruation"
        case .follicular: "Follicular phase"
        case .ovulation: "Around ovulation"
        case .luteal: "Luteal phase"
        }
    }

    var shortTitle: String {
        switch self {
        case .menstruation: "Period"
        case .follicular: "Follicular"
        case .ovulation: "Ovulation"
        case .luteal: "Luteal"
        }
    }

    var insight: String {
        switch self {
        case .menstruation:
            "Your period is here. Energy can feel lower, so gentle plans and extra rest may feel right."
        case .follicular:
            "Estrogen commonly rises through this phase. Some people notice steadier energy and mood."
        case .ovulation:
            "This is an estimated window, not a guarantee. Body signs and timing vary from cycle to cycle."
        case .luteal:
            "Hormones shift before a period. Tracking symptoms can help you notice your own recurring patterns."
        }
    }

    var color: Color {
        switch self {
        case .menstruation: STOTheme.rose
        case .follicular: Color(hex: 0xD798A8)
        case .ovulation: STOTheme.blue
        case .luteal: Color(hex: 0x8BA9B8)
        }
    }

    var icon: String {
        switch self {
        case .menstruation: "drop.fill"
        case .follicular: "sparkles"
        case .ovulation: "circle.hexagongrid.fill"
        case .luteal: "moon.stars.fill"
        }
    }
}

enum FlowLevel: String, Codable, CaseIterable, Identifiable {
    case light
    case medium
    case heavy

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var drops: Int {
        switch self {
        case .light: 1
        case .medium: 2
        case .heavy: 3
        }
    }
}

enum Mood: String, Codable, CaseIterable, Identifiable {
    case low
    case sensitive
    case okay
    case calm
    case good

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .low: "cloud.rain.fill"
        case .sensitive: "heart.fill"
        case .okay: "circle.lefthalf.filled"
        case .calm: "wind"
        case .good: "sun.max.fill"
        }
    }
}

enum Symptom: String, Codable, CaseIterable, Identifiable {
    case cramps
    case headache
    case bloating
    case fatigue
    case backPain
    case tenderBreasts
    case acne
    case nausea
    case cravings
    case insomnia

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cramps: "Cramps"
        case .headache: "Headache"
        case .bloating: "Bloating"
        case .fatigue: "Fatigue"
        case .backPain: "Back pain"
        case .tenderBreasts: "Tender breasts"
        case .acne: "Acne"
        case .nausea: "Nausea"
        case .cravings: "Cravings"
        case .insomnia: "Poor sleep"
        }
    }

    var symbol: String {
        switch self {
        case .cramps: "bolt.heart.fill"
        case .headache: "brain.head.profile"
        case .bloating: "circle.dotted"
        case .fatigue: "battery.25percent"
        case .backPain: "figure.mind.and.body"
        case .tenderBreasts: "heart.circle.fill"
        case .acne: "sparkle"
        case .nausea: "waveform.path.ecg"
        case .cravings: "fork.knife"
        case .insomnia: "moon.zzz.fill"
        }
    }
}

enum TrackingGoal: String, Codable, CaseIterable, Identifiable {
    case predictPeriods
    case understandSymptoms
    case planAhead
    case buildHistory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .predictPeriods: "Know when my period may start"
        case .understandSymptoms: "Understand symptoms and mood"
        case .planAhead: "Plan around my cycle"
        case .buildHistory: "Build a clearer cycle history"
        }
    }

    var shortTitle: String {
        switch self {
        case .predictPeriods: "Period forecasts"
        case .understandSymptoms: "Symptom patterns"
        case .planAhead: "Planning ahead"
        case .buildHistory: "Cycle history"
        }
    }

    var detail: String {
        switch self {
        case .predictPeriods: "See an estimated start date and cycle day."
        case .understandSymptoms: "Notice what tends to show up together over time."
        case .planAhead: "Keep upcoming cycle dates visible for busy weeks."
        case .buildHistory: "Create a private record you can look back on."
        }
    }

    var symbol: String {
        switch self {
        case .predictPeriods: "calendar.badge.clock"
        case .understandSymptoms: "waveform.path.ecg"
        case .planAhead: "calendar.badge.checkmark"
        case .buildHistory: "chart.xyaxis.line"
        }
    }
}

enum CycleRegularity: String, Codable, CaseIterable, Identifiable {
    case predictable
    case someVariation
    case irregular
    case unsure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .predictable: "Usually predictable"
        case .someVariation: "Varies by about a week"
        case .irregular: "Often hard to predict"
        case .unsure: "I’m not sure yet"
        }
    }

    var detail: String {
        switch self {
        case .predictable: "Starts are usually within a few days of expected."
        case .someVariation: "Timing moves around, but there is some pattern."
        case .irregular: "The gap between periods changes a lot."
        case .unsure: "We’ll learn from future period logs."
        }
    }

    var symbol: String {
        switch self {
        case .predictable: "equal.circle.fill"
        case .someVariation: "waveform"
        case .irregular: "shuffle"
        case .unsure: "questionmark.circle.fill"
        }
    }
}

enum HormoneContext: String, Codable, CaseIterable, Identifiable {
    case none
    case preferNotToSay
    case hormonalContraception
    case postpartum
    case perimenopause
    case fertilityTreatment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "None of these"
        case .hormonalContraception: "Hormonal contraception"
        case .postpartum: "Postpartum or breastfeeding"
        case .perimenopause: "Perimenopause"
        case .fertilityTreatment: "Fertility treatment"
        case .preferNotToSay: "Prefer not to say"
        }
    }

    var detail: String {
        switch self {
        case .none: "No current hormone-related context to add."
        case .hormonalContraception: "Pill, implant, hormonal IUD, patch, ring, or injection."
        case .postpartum: "Recent birth or breastfeeding can change cycle timing."
        case .perimenopause: "Cycle timing may be changing through this transition."
        case .fertilityTreatment: "Treatment can change bleeding and cycle timing."
        case .preferNotToSay: "You can still use every tracking feature."
        }
    }

    var mayAffectTiming: Bool {
        switch self {
        case .hormonalContraception, .postpartum, .perimenopause, .fertilityTreatment: true
        case .none, .preferNotToSay: false
        }
    }
}

struct DailyLog: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var isPeriod: Bool
    var flow: FlowLevel?
    var symptoms: Set<Symptom>
    var mood: Mood?
    var energy: Int?
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date,
        isPeriod: Bool = false,
        flow: FlowLevel? = nil,
        symptoms: Set<Symptom> = [],
        mood: Mood? = nil,
        energy: Int? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.isPeriod = isPeriod
        self.flow = flow
        self.symptoms = symptoms
        self.mood = mood
        self.energy = energy
        self.notes = notes
    }

    var hasDetails: Bool {
        isPeriod || !symptoms.isEmpty || mood != nil || energy != nil || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct CycleProfile: Codable, Equatable {
    var averageCycleLength: Int
    var averagePeriodLength: Int
    var lastPeriodStart: Date
    var goals: Set<TrackingGoal>
    var regularity: CycleRegularity
    var hormoneContext: HormoneContext
    var focusSymptoms: Set<Symptom>

    init(
        averageCycleLength: Int = 28,
        averagePeriodLength: Int = 5,
        lastPeriodStart: Date = Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
        goals: Set<TrackingGoal> = [.predictPeriods],
        regularity: CycleRegularity = .unsure,
        hormoneContext: HormoneContext = .preferNotToSay,
        focusSymptoms: Set<Symptom> = []
    ) {
        self.averageCycleLength = averageCycleLength
        self.averagePeriodLength = averagePeriodLength
        self.lastPeriodStart = lastPeriodStart
        self.goals = goals.isEmpty ? [.predictPeriods] : goals
        self.regularity = regularity
        self.hormoneContext = hormoneContext
        self.focusSymptoms = focusSymptoms
    }

    var primaryGoal: TrackingGoal {
        TrackingGoal.allCases.first(where: goals.contains) ?? .predictPeriods
    }

    var predictionGuidance: String {
        if hormoneContext.mayAffectTiming {
            return "Your current hormone context can shift bleeding patterns, so forecasts stay clearly labeled as estimates."
        }
        switch regularity {
        case .predictable:
            return "Your usual timing gives the first forecast a useful baseline. Logging each period keeps it current."
        case .someVariation:
            return "Your timing can move by several days, so use the forecast as a planning window rather than an exact date."
        case .irregular:
            return "Your cycle can vary considerably. Logs will build a record, but a single predicted date may be less reliable."
        case .unsure:
            return "This is an early estimate. Future period logs will show how much your timing tends to vary."
        }
    }

    var forecastLabel: String {
        if hormoneContext.mayAffectTiming { return "Early estimate" }
        return switch regularity {
        case .predictable: "Estimated start"
        case .someVariation: "Planning estimate"
        case .irregular: "Rough estimate"
        case .unsure: "Early estimate"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case averageCycleLength
        case averagePeriodLength
        case lastPeriodStart
        case goals
        case regularity
        case hormoneContext
        case focusSymptoms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        averageCycleLength = try container.decodeIfPresent(Int.self, forKey: .averageCycleLength) ?? 28
        averagePeriodLength = try container.decodeIfPresent(Int.self, forKey: .averagePeriodLength) ?? 5
        lastPeriodStart = try container.decodeIfPresent(Date.self, forKey: .lastPeriodStart)
            ?? Calendar.current.date(byAdding: .day, value: -10, to: Date())
            ?? Date()
        let decodedGoals = try container.decodeIfPresent(Set<TrackingGoal>.self, forKey: .goals) ?? [.predictPeriods]
        goals = decodedGoals.isEmpty ? [.predictPeriods] : decodedGoals
        regularity = try container.decodeIfPresent(CycleRegularity.self, forKey: .regularity) ?? .unsure
        hormoneContext = try container.decodeIfPresent(HormoneContext.self, forKey: .hormoneContext) ?? .preferNotToSay
        focusSymptoms = try container.decodeIfPresent(Set<Symptom>.self, forKey: .focusSymptoms) ?? []
    }
}

struct ReminderSettings: Codable, Equatable {
    var isEnabled = false
    var time = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
}

struct AppState: Codable, Equatable {
    var hasCompletedOnboarding = false
    var profile = CycleProfile()
    var logs: [DailyLog] = []
    var reminders = ReminderSettings()

    static func demo(referenceDate: Date = Date(), calendar: Calendar = .current) -> AppState {
        let today = calendar.startOfDay(for: referenceDate)
        let start = calendar.date(byAdding: .day, value: -11, to: today) ?? today
        var logs: [DailyLog] = []

        for offset in 0..<5 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            logs.append(DailyLog(date: date, isPeriod: true, flow: offset == 0 ? .medium : (offset == 1 ? .heavy : .light)))
        }

        logs.append(
            DailyLog(
                date: today,
                symptoms: [.bloating, .fatigue],
                mood: .calm,
                energy: 3,
                notes: "Taking today a little slower."
            )
        )

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            logs.append(DailyLog(date: yesterday, symptoms: [.headache], mood: .okay, energy: 4))
        }

        return AppState(
            hasCompletedOnboarding: true,
            profile: CycleProfile(
                averageCycleLength: 28,
                averagePeriodLength: 5,
                lastPeriodStart: start,
                goals: [.predictPeriods, .understandSymptoms],
                regularity: .someVariation,
                hormoneContext: .none,
                focusSymptoms: [.bloating, .fatigue, .headache]
            ),
            logs: logs,
            reminders: ReminderSettings()
        )
    }
}

enum CalendarDayStatus: Equatable {
    case none
    case loggedPeriod
    case predictedPeriod
    case fertile
    case ovulation
}

struct CyclePeriod: Identifiable, Equatable {
    let start: Date
    let end: Date

    var id: Date { start }
}
