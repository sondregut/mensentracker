import SwiftUI

struct HomeView: View {
    private struct LogDestination: Identifiable {
        let date: Date
        var id: Date { date }
    }

    @EnvironmentObject private var store: CycleStore
    @State private var logDestination: LogDestination?

    private var today: Date { store.engine.day(Date()) }
    private var todayLog: DailyLog? { store.log(on: today) }
    private var phase: CyclePhase {
        store.engine.phase(for: today, profile: store.profile, logs: store.logs)
    }
    private var cycleDay: Int {
        store.engine.cycleDay(for: today, profile: store.profile, logs: store.logs)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                STOPageBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        weekStrip
                        CycleHeroCard(
                            cycleDay: cycleDay,
                            cycleLength: store.profile.averageCycleLength,
                            phase: phase,
                            isLoggedPeriod: todayLog?.isPeriod == true,
                            daysUntilPeriod: store.engine.daysUntilNextPeriod(
                                from: today,
                                profile: store.profile,
                                logs: store.logs
                            ),
                            nextPeriodDate: store.engine.nextPeriodStart(
                                after: today,
                                profile: store.profile,
                                logs: store.logs
                            ),
                            estimateLabel: store.profile.forecastLabel,
                            action: { openLog(on: today) }
                        )

                        personalFocusCard
                        dailyCheckInCard
                        phaseCard
                        STOSafetyNote(text: "Cycle and fertile-window dates are estimates. They are not contraception and cannot confirm ovulation or pregnancy.")
                    }
                    .padding(.horizontal, STOTheme.pagePadding)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $logDestination) { destination in
                DailyLogView(date: destination.date)
                    .environmentObject(store)
            }
        }
    }

    private var personalFocusCard: some View {
        let goal = store.profile.primaryGoal
        return STOCard(background: STOTheme.blueSoft.opacity(0.42)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: goal.symbol)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(STOTheme.blue)
                        .frame(width: 44, height: 44)
                        .background(STOTheme.white.opacity(0.82))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("YOUR FOCUS")
                            .font(STOFont.display(13, relativeTo: .caption))
                            .tracking(1.1)
                            .foregroundStyle(STOTheme.rose)
                        Text(goal.shortTitle)
                            .font(STOFont.display(24, relativeTo: .title3))
                            .foregroundStyle(STOTheme.blue)
                    }
                }

                Text(goal.detail)
                    .font(STOFont.body(.subheadline))
                    .foregroundStyle(STOTheme.ink)

                if !store.profile.focusSymptoms.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(orderedFocusSymptoms.prefix(4)) { symptom in
                            LogPill(title: symptom.title, symbol: symptom.symbol)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("home.personalFocus")
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                STOBrandMark(compact: true)
                Text(today.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(STOFont.body(.caption))
                    .foregroundStyle(STOTheme.muted)
            }
            Spacer()
            PhaseBadge(phase: phase)
        }
        .padding(.top, 14)
    }

    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(-3...3, id: \.self) { offset in
                let date = store.engine.calendar.date(byAdding: .day, value: offset, to: today) ?? today
                let isToday = offset == 0
                let status = store.engine.status(for: date, profile: store.profile, logs: store.logs)

                Button {
                    openLog(on: date)
                } label: {
                    VStack(spacing: 7) {
                        Text(date.formatted(.dateTime.weekday(.narrow)))
                            .font(STOFont.body(.caption2, weight: .semibold))
                            .foregroundStyle(isToday ? STOTheme.rose : STOTheme.muted)
                        Text(date.formatted(.dateTime.day()))
                            .font(STOFont.body(.subheadline, weight: .bold))
                            .foregroundStyle(isToday ? Color.white : STOTheme.ink)
                            .frame(width: 36, height: 36)
                            .background(isToday ? STOTheme.rose : Color.clear)
                            .clipShape(Circle())
                        Circle()
                            .fill(statusColor(status))
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(WeekDayButtonStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(dayAccessibilityLabel(date: date, status: status, isToday: isToday))
                .accessibilityHint("Opens the daily log")
                .accessibilityAddTraits(isToday ? .isSelected : [])
                .accessibilityIdentifier("home.weekDay.\(dateKey(date))")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 13)
        .background(STOTheme.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var dailyCheckInCard: some View {
        STOCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    STOSectionHeader(
                        todayLog?.hasDetails == true ? "Today at a glance" : "How are you today?",
                        eyebrow: "Daily check-in",
                        detail: todayLog?.hasDetails == true ? "Your log is saved privately on this device." : personalizedCheckInDetail
                    )
                    Image(systemName: todayLog?.hasDetails == true ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 27, weight: .semibold))
                        .foregroundStyle(todayLog?.hasDetails == true ? STOTheme.blue : STOTheme.rose)
                }

                if let log = todayLog, log.hasDetails {
                    FlowLayout(spacing: 8) {
                        if log.isPeriod {
                            LogPill(title: log.flow?.title ?? "Period", symbol: "drop.fill")
                        }
                        if let mood = log.mood {
                            LogPill(title: mood.title, symbol: mood.symbol)
                        }
                        if let energy = log.energy {
                            LogPill(title: "Energy \(energy)/5", symbol: "bolt.fill")
                        }
                        ForEach(log.symptoms.sorted { $0.title < $1.title }) { symptom in
                            LogPill(title: symptom.title, symbol: symptom.symbol)
                        }
                    }
                }

                Button(todayLog?.hasDetails == true ? "Edit today’s log" : "Log today") {
                    openLog(on: today)
                }
                .buttonStyle(STOSecondaryButtonStyle())
                .accessibilityIdentifier("home.logToday")
            }
        }
    }

    private var orderedFocusSymptoms: [Symptom] {
        Symptom.allCases.filter(store.profile.focusSymptoms.contains)
    }

    private var personalizedCheckInDetail: String {
        if let first = orderedFocusSymptoms.first {
            if orderedFocusSymptoms.count == 1 {
                return "\(first.title) is pinned first in your symptom check-in."
            }
            return "\(first.title) and your other chosen symptoms are pinned first."
        }
        return switch store.profile.primaryGoal {
        case .predictPeriods: "Logging period days keeps your forecast current."
        case .understandSymptoms: "A few taps now can reveal your symptom patterns later."
        case .planAhead: "A quick log helps future planning estimates reflect your cycle."
        case .buildHistory: "Each check-in adds context to your private cycle record."
        }
    }

    private var phaseCard: some View {
        STOCard(background: phase.color.opacity(0.08)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: phase.icon)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(phase.color)
                        .frame(width: 46, height: 46)
                        .background(phase.color.opacity(0.13))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("CYCLE DAY \(cycleDay)")
                            .font(STOFont.display(13, relativeTo: .caption))
                            .tracking(1.1)
                            .foregroundStyle(STOTheme.rose)
                        Text(phase.title)
                            .font(STOFont.display(25, relativeTo: .title2))
                            .foregroundStyle(STOTheme.blue)
                    }
                }
                Text(phase.insight)
                    .font(STOFont.body(.subheadline))
                    .foregroundStyle(STOTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func statusColor(_ status: CalendarDayStatus) -> Color {
        switch status {
        case .loggedPeriod: STOTheme.rose
        case .predictedPeriod: STOTheme.rose.opacity(0.45)
        case .fertile: STOTheme.blue.opacity(0.55)
        case .ovulation: STOTheme.blue
        case .none: .clear
        }
    }

    private func openLog(on date: Date) {
        logDestination = LogDestination(date: store.engine.day(date))
    }

    private func dateKey(_ date: Date) -> String {
        let components = store.engine.calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d%02d%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private func dayAccessibilityLabel(date: Date, status: CalendarDayStatus, isToday: Bool) -> String {
        let prefix = isToday ? "Today, " : ""
        let suffix: String
        switch status {
        case .loggedPeriod: suffix = ", logged period"
        case .predictedPeriod: suffix = ", predicted period"
        case .fertile: suffix = ", estimated fertile window"
        case .ovulation: suffix = ", estimated ovulation"
        case .none: suffix = ""
        }
        return prefix + date.formatted(date: .complete, time: .omitted) + suffix
    }
}

private struct WeekDayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

private struct LogPill: View {
    let title: String
    let symbol: String

    var body: some View {
        Label(title, systemImage: symbol)
            .font(STOFont.body(.caption, weight: .semibold))
            .foregroundStyle(STOTheme.blue)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(STOTheme.blueSoft.opacity(0.65))
            .clipShape(Capsule())
    }
}

private struct CycleHeroCard: View {
    let cycleDay: Int
    let cycleLength: Int
    let phase: CyclePhase
    let isLoggedPeriod: Bool
    let daysUntilPeriod: Int
    let nextPeriodDate: Date
    let estimateLabel: String
    let action: () -> Void

    private var progress: Double {
        min(max(Double(cycleDay) / Double(max(cycleLength, 1)), 0.02), 1)
    }

    var body: some View {
        STOCard(padding: 0) {
            ZStack {
                LinearGradient(
                    colors: [STOTheme.blush, STOTheme.roseSoft.opacity(0.78), STOTheme.blueSoft.opacity(0.52)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .stroke(STOTheme.white.opacity(0.82), lineWidth: 13)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(colors: [STOTheme.rose, STOTheme.blue], center: .center),
                                style: StrokeStyle(lineWidth: 13, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 3) {
                            Text(isLoggedPeriod ? "PERIOD" : "PERIOD IN")
                                .font(STOFont.display(14, relativeTo: .caption))
                                .tracking(1.2)
                                .foregroundStyle(STOTheme.blue)
                            Text(isLoggedPeriod ? "DAY \(cycleDay)" : "\(daysUntilPeriod)")
                                .font(STOFont.display(isLoggedPeriod ? 39 : 58, relativeTo: .largeTitle))
                                .foregroundStyle(STOTheme.rose)
                                .contentTransition(.numericText())
                            Text(isLoggedPeriod ? phase.shortTitle : (daysUntilPeriod == 1 ? "day" : "days"))
                                .font(STOFont.body(.subheadline, weight: .semibold))
                                .foregroundStyle(STOTheme.muted)
                        }
                    }
                    .frame(width: 220, height: 220)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(isLoggedPeriod ? "Period, cycle day \(cycleDay)" : "Period predicted in \(daysUntilPeriod) days")

                    VStack(spacing: 4) {
                        Text(isLoggedPeriod ? "Your period is logged" : "\(estimateLabel) \(nextPeriodDate.formatted(.dateTime.month(.abbreviated).day()))")
                            .font(STOFont.body(.subheadline, weight: .semibold))
                            .foregroundStyle(STOTheme.blue)
                        Text("Cycle day \(cycleDay) of about \(cycleLength)")
                            .font(STOFont.body(.caption))
                            .foregroundStyle(STOTheme.muted)
                    }

                    Button(isLoggedPeriod ? "Update period" : "Log today", action: action)
                        .buttonStyle(STOPrimaryButtonStyle(color: STOTheme.blue))
                        .accessibilityIdentifier("hero.log")
                }
                .padding(24)
            }
        }
        .frame(minHeight: 410)
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
