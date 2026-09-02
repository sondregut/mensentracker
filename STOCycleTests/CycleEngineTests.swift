import XCTest
@testable import STOCycle

final class CycleEngineTests: XCTestCase {
    private var calendar: Calendar!
    private var engine: CycleEngine!

    override func setUp() {
        super.setUp()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        self.calendar = calendar
        self.engine = CycleEngine(calendar: calendar)
    }

    func testCycleDayAndPhasesUseConfiguredBaseline() {
        let profile = CycleProfile(
            averageCycleLength: 28,
            averagePeriodLength: 5,
            lastPeriodStart: date(2026, 1, 1)
        )

        XCTAssertEqual(engine.cycleDay(for: date(2026, 1, 1), profile: profile, logs: []), 1)
        XCTAssertEqual(engine.phase(for: date(2026, 1, 1), profile: profile, logs: []), .menstruation)
        XCTAssertEqual(engine.phase(for: date(2026, 1, 6), profile: profile, logs: []), .follicular)
        XCTAssertEqual(engine.phase(for: date(2026, 1, 14), profile: profile, logs: []), .ovulation)
        XCTAssertEqual(engine.phase(for: date(2026, 1, 20), profile: profile, logs: []), .luteal)
        XCTAssertEqual(engine.cycleDay(for: date(2026, 1, 29), profile: profile, logs: []), 1)
    }

    func testCalendarStatusDistinguishesLoggedAndPredictedDays() {
        let profile = CycleProfile(
            averageCycleLength: 28,
            averagePeriodLength: 5,
            lastPeriodStart: date(2026, 1, 1)
        )
        let logs = [
            DailyLog(date: date(2026, 1, 1), isPeriod: true, flow: .medium),
            DailyLog(date: date(2026, 1, 2), isPeriod: true, flow: .medium)
        ]

        XCTAssertEqual(engine.status(for: date(2026, 1, 2), profile: profile, logs: logs), .loggedPeriod)
        XCTAssertEqual(engine.status(for: date(2026, 1, 3), profile: profile, logs: logs), .predictedPeriod)
        XCTAssertEqual(engine.status(for: date(2026, 1, 9), profile: profile, logs: logs), .fertile)
        XCTAssertEqual(engine.status(for: date(2026, 1, 14), profile: profile, logs: logs), .ovulation)
        XCTAssertEqual(engine.status(for: date(2026, 1, 20), profile: profile, logs: logs), .none)
    }

    func testNextPeriodDateAndCountdown() {
        let profile = CycleProfile(
            averageCycleLength: 28,
            averagePeriodLength: 5,
            lastPeriodStart: date(2026, 1, 1)
        )

        XCTAssertEqual(engine.nextPeriodStart(after: date(2026, 1, 10), profile: profile, logs: []), date(2026, 1, 29))
        XCTAssertEqual(engine.daysUntilNextPeriod(from: date(2026, 1, 10), profile: profile, logs: []), 19)
    }

    func testPeriodRangesAndPersonalAverages() {
        let starts = [date(2026, 1, 1), date(2026, 1, 29), date(2026, 2, 26)]
        var logs: [DailyLog] = []
        for start in starts {
            for offset in 0..<5 {
                logs.append(DailyLog(date: calendar.date(byAdding: .day, value: offset, to: start)!, isPeriod: true))
            }
        }

        let periods = engine.periodRanges(from: logs)
        XCTAssertEqual(periods.count, 3)
        XCTAssertEqual(engine.averageCycleLength(from: periods, fallback: 30), 28)
        XCTAssertEqual(engine.averagePeriodLength(from: periods, fallback: 7), 5)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
