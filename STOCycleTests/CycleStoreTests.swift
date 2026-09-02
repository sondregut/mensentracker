import XCTest
@testable import STOCycle

final class CycleStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "STOCycleTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    @MainActor
    func testOnboardingSeedsPeriodAndPersistsProfile() {
        let store = CycleStore(defaults: defaults, arguments: [])
        let profile = CycleProfile(
            averageCycleLength: 31,
            averagePeriodLength: 4,
            lastPeriodStart: Date(timeIntervalSince1970: 1_700_000_000),
            goals: [.planAhead, .understandSymptoms],
            regularity: .someVariation,
            hormoneContext: .hormonalContraception,
            focusSymptoms: [.cramps, .headache]
        )
        let reminder = ReminderSettings(
            isEnabled: true,
            time: Date(timeIntervalSince1970: 1_700_010_000)
        )

        store.completeOnboarding(profile: profile, reminders: reminder)

        XCTAssertTrue(store.hasCompletedOnboarding)
        XCTAssertEqual(store.profile, profile)
        XCTAssertEqual(store.state.reminders, reminder)
        XCTAssertEqual(store.logs.filter(\.isPeriod).count, 4)

        let restored = CycleStore(defaults: defaults, arguments: [])
        XCTAssertTrue(restored.hasCompletedOnboarding)
        XCTAssertEqual(restored.profile, profile)
        XCTAssertEqual(restored.state.reminders, reminder)
        XCTAssertEqual(restored.logs.filter(\.isPeriod).count, 4)
    }

    func testLegacyProfileDecodesWithSafePersonalizationDefaults() throws {
        let legacyJSON = """
        {
          "averageCycleLength": 30,
          "averagePeriodLength": 6,
          "lastPeriodStart": "2023-11-14T22:13:20Z"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let profile = try decoder.decode(CycleProfile.self, from: legacyJSON)

        XCTAssertEqual(profile.averageCycleLength, 30)
        XCTAssertEqual(profile.averagePeriodLength, 6)
        XCTAssertEqual(profile.goals, [.predictPeriods])
        XCTAssertEqual(profile.regularity, .unsure)
        XCTAssertEqual(profile.hormoneContext, .preferNotToSay)
        XCTAssertTrue(profile.focusSymptoms.isEmpty)
    }

    @MainActor
    func testSavingAndClearingDailyLog() {
        let store = CycleStore(defaults: defaults, arguments: [])
        let date = Date(timeIntervalSince1970: 1_710_000_000)
        var log = DailyLog(date: date, symptoms: [.cramps], mood: .okay, energy: 2)

        store.save(log)
        XCTAssertEqual(store.log(on: date)?.symptoms, [.cramps])

        log.symptoms = []
        log.mood = nil
        log.energy = nil
        store.save(log)
        XCTAssertNil(store.log(on: date))
    }

    @MainActor
    func testProfilePersonalizationUpdatesAndPersists() {
        let store = CycleStore(defaults: defaults, arguments: ["-demoData"])

        store.updatePersonalization(
            goals: [.planAhead, .buildHistory],
            regularity: .irregular,
            hormoneContext: .perimenopause,
            focusSymptoms: [.cramps, .insomnia]
        )

        XCTAssertEqual(store.profile.goals, [.planAhead, .buildHistory])
        XCTAssertEqual(store.profile.regularity, .irregular)
        XCTAssertEqual(store.profile.hormoneContext, .perimenopause)
        XCTAssertEqual(store.profile.focusSymptoms, [.cramps, .insomnia])

        let restored = CycleStore(defaults: defaults, arguments: [])
        XCTAssertEqual(restored.profile.goals, [.planAhead, .buildHistory])
        XCTAssertEqual(restored.profile.regularity, .irregular)
        XCTAssertEqual(restored.profile.hormoneContext, .perimenopause)
        XCTAssertEqual(restored.profile.focusSymptoms, [.cramps, .insomnia])
    }

    @MainActor
    func testResetReturnsToOnboarding() {
        let store = CycleStore(defaults: defaults, arguments: ["-demoData"])
        XCTAssertTrue(store.hasCompletedOnboarding)

        store.resetAllData()

        XCTAssertFalse(store.hasCompletedOnboarding)
        XCTAssertTrue(store.logs.isEmpty)
    }
}
