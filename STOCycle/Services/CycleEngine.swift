import Foundation

struct CycleEngine {
    var calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func day(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func sameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    func log(on date: Date, in logs: [DailyLog]) -> DailyLog? {
        logs.first { sameDay($0.date, date) }
    }

    func periodRanges(from logs: [DailyLog]) -> [CyclePeriod] {
        let dates = logs
            .filter(\.isPeriod)
            .map { day($0.date) }
            .sorted()

        guard let first = dates.first else { return [] }

        var result: [CyclePeriod] = []
        var rangeStart = first
        var previous = first

        for date in dates.dropFirst() {
            let gap = calendar.dateComponents([.day], from: previous, to: date).day ?? 0
            if gap > 1 {
                result.append(CyclePeriod(start: rangeStart, end: previous))
                rangeStart = date
            }
            previous = date
        }

        result.append(CyclePeriod(start: rangeStart, end: previous))
        return result.sorted { $0.start > $1.start }
    }

    func anchorDate(for date: Date, profile: CycleProfile, logs: [DailyLog]) -> Date {
        let target = day(date)
        let latestLoggedStart = periodRanges(from: logs)
            .map(\.start)
            .filter { $0 <= target }
            .max()

        return latestLoggedStart ?? day(profile.lastPeriodStart)
    }

    func cycleDay(for date: Date, profile: CycleProfile, logs: [DailyLog]) -> Int {
        let anchor = anchorDate(for: date, profile: profile, logs: logs)
        let distance = calendar.dateComponents([.day], from: anchor, to: day(date)).day ?? 0
        let length = max(profile.averageCycleLength, 1)
        let normalized = ((distance % length) + length) % length
        return normalized + 1
    }

    func phase(for date: Date, profile: CycleProfile, logs: [DailyLog]) -> CyclePhase {
        let cycleDay = cycleDay(for: date, profile: profile, logs: logs)
        let periodLength = profile.averagePeriodLength
        let ovulationDay = max(profile.averageCycleLength - 14, periodLength + 2)

        if cycleDay <= periodLength { return .menstruation }
        if abs(cycleDay - ovulationDay) <= 1 { return .ovulation }
        if cycleDay < ovulationDay - 1 { return .follicular }
        return .luteal
    }

    func status(for date: Date, profile: CycleProfile, logs: [DailyLog]) -> CalendarDayStatus {
        if log(on: date, in: logs)?.isPeriod == true { return .loggedPeriod }

        let cycleDay = cycleDay(for: date, profile: profile, logs: logs)
        if cycleDay <= profile.averagePeriodLength { return .predictedPeriod }

        let ovulationDay = max(profile.averageCycleLength - 14, profile.averagePeriodLength + 2)
        if cycleDay == ovulationDay { return .ovulation }
        if cycleDay >= ovulationDay - 5 && cycleDay <= ovulationDay + 1 { return .fertile }
        return .none
    }

    func nextPeriodStart(after date: Date, profile: CycleProfile, logs: [DailyLog]) -> Date {
        let target = day(date)
        let cycleDay = cycleDay(for: target, profile: profile, logs: logs)
        let daysUntil = profile.averageCycleLength - cycleDay + 1
        return calendar.date(byAdding: .day, value: daysUntil, to: target) ?? target
    }

    func daysUntilNextPeriod(from date: Date, profile: CycleProfile, logs: [DailyLog]) -> Int {
        let target = day(date)
        let next = nextPeriodStart(after: target, profile: profile, logs: logs)
        return max(calendar.dateComponents([.day], from: target, to: next).day ?? 0, 0)
    }

    func periodLength(_ period: CyclePeriod) -> Int {
        (calendar.dateComponents([.day], from: period.start, to: period.end).day ?? 0) + 1
    }

    func averageCycleLength(from periods: [CyclePeriod], fallback: Int) -> Int {
        let ascending = periods.sorted { $0.start < $1.start }
        let lengths = zip(ascending, ascending.dropFirst()).compactMap { first, second in
            calendar.dateComponents([.day], from: first.start, to: second.start).day
        }.filter { (15...60).contains($0) }

        guard !lengths.isEmpty else { return fallback }
        return Int((Double(lengths.reduce(0, +)) / Double(lengths.count)).rounded())
    }

    func averagePeriodLength(from periods: [CyclePeriod], fallback: Int) -> Int {
        let lengths = periods.map(periodLength).filter { (1...15).contains($0) }
        guard !lengths.isEmpty else { return fallback }
        return Int((Double(lengths.reduce(0, +)) / Double(lengths.count)).rounded())
    }
}
