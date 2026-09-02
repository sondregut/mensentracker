import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var store: CycleStore
    @State private var selectedPhase: CyclePhase?
    private let requestedPhaseCard: String?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        requestedPhaseCard = arguments
            .drop(while: { $0 != "-uiTestPhaseCard" })
            .dropFirst()
            .first
    }

    private var periods: [CyclePeriod] {
        store.engine.periodRanges(from: store.logs)
    }

    private var averageCycleLength: Int {
        store.engine.averageCycleLength(from: periods, fallback: store.profile.averageCycleLength)
    }

    private var averagePeriodLength: Int {
        store.engine.averagePeriodLength(from: periods, fallback: store.profile.averagePeriodLength)
    }

    private var currentPhase: CyclePhase {
        store.engine.phase(for: Date(), profile: store.profile, logs: store.logs)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                STOPageBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        metricGrid
                        personalizationCard
                        patternCard
                        historySection
                        phaseGuide
                        STOSafetyNote(text: "Insights summarize what you log and are not a diagnosis. Contact a qualified clinician about symptoms that worry you or disrupt daily life.")
                    }
                    .padding(.horizontal, STOTheme.pagePadding)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedPhase) { phase in
                PhaseDetailSheet(
                    phase: phase,
                    isCurrentEstimate: phase == currentPhase,
                    timing: phaseTiming(phase)
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
        }
    }

    private var personalizationCard: some View {
        STOCard(background: STOTheme.blueSoft.opacity(0.38)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    STOSectionHeader(
                        "Your priorities",
                        eyebrow: "Your setup",
                        detail: store.profile.predictionGuidance
                    )
                    Image(systemName: store.profile.primaryGoal.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(STOTheme.blue)
                        .frame(width: 44, height: 44)
                        .background(STOTheme.white.opacity(0.82))
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 9) {
                    ForEach(TrackingGoal.allCases.filter(store.profile.goals.contains)) { goal in
                        Label(goal.shortTitle, systemImage: goal.symbol)
                            .font(STOFont.body(.subheadline, weight: .semibold))
                            .foregroundStyle(STOTheme.ink)
                    }
                }

                if !store.profile.focusSymptoms.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Symptom.allCases.filter(store.profile.focusSymptoms.contains)) { symptom in
                                Label(symptom.title, systemImage: symptom.symbol)
                                    .font(STOFont.body(.caption, weight: .semibold))
                                    .foregroundStyle(STOTheme.blue)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 8)
                                    .background(STOTheme.white.opacity(0.86))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("insights.personalization")
    }

    private var header: some View {
        STOSectionHeader(
            "Your patterns",
            eyebrow: "Insights",
            detail: "A simple view of what your own logs are beginning to show."
        )
        .padding(.top, 18)
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            STOMetricCard(
                value: "\(averageCycleLength) days",
                label: periods.count >= 2 ? "Average cycle" : "Cycle setting",
                symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                tint: STOTheme.rose
            )
            STOMetricCard(
                value: "\(averagePeriodLength) days",
                label: periods.isEmpty ? "Period setting" : "Average period",
                symbol: "drop.fill",
                tint: STOTheme.blue
            )
            STOMetricCard(
                value: "Day \(store.engine.cycleDay(for: Date(), profile: store.profile, logs: store.logs))",
                label: "Current cycle day",
                symbol: "calendar.day.timeline.left",
                tint: STOTheme.blue
            )
            STOMetricCard(
                value: "\(loggedDaysThisCycle)",
                label: "Check-ins this cycle",
                symbol: "checkmark.circle.fill",
                tint: STOTheme.rose
            )
        }
    }

    private var patternCard: some View {
        STOCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    STOSectionHeader("Symptom snapshot", eyebrow: "Last 90 days")
                    Spacer()
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(STOTheme.rose)
                        .frame(width: 44, height: 44)
                        .background(STOTheme.roseSoft)
                        .clipShape(Circle())
                }

                if topSymptoms.isEmpty {
                    Text("Log symptoms on a few days and their frequency will appear here.")
                        .font(STOFont.body(.subheadline))
                        .foregroundStyle(STOTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(spacing: 14) {
                        ForEach(topSymptoms, id: \.symptom) { item in
                            symptomBar(symptom: item.symptom, count: item.count, maximum: topSymptoms.first?.count ?? 1)
                        }
                    }
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            STOSectionHeader(
                "Cycle history",
                eyebrow: "Your record",
                detail: periods.count < 2 ? "Two completed periods are needed for a personal cycle average." : "Recent periods, newest first."
            )

            if periods.isEmpty {
                EmptyStateCard(
                    symbol: "calendar.badge.plus",
                    title: "No periods logged yet",
                    message: "Mark period days from Today or Calendar to begin your history."
                )
            } else {
                STOCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(periods.prefix(6).enumerated()), id: \.element.id) { index, period in
                            cycleHistoryRow(period: period)
                                .padding(17)
                            if index < min(periods.count, 6) - 1 {
                                Divider().overlay(STOTheme.divider)
                                    .padding(.leading, 64)
                            }
                        }
                    }
                }
            }
        }
    }

    private var phaseGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
            STOSectionHeader(
                "Cycle phases",
                eyebrow: "A gentle guide",
                detail: "Bodies vary. Use these as context—not rules for how you should feel."
            )

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CyclePhase.allCases) { phase in
                            phaseCard(phase)
                                .id(phase.rawValue)
                        }
                    }
                    .padding(.vertical, 1)
                }
                .accessibilityIdentifier("insights.phaseCarousel")
                .onAppear {
                    guard let requestedPhaseCard else { return }
                    DispatchQueue.main.async {
                        proxy.scrollTo(requestedPhaseCard, anchor: .center)
                    }
                }
            }
        }
    }

    private func phaseCard(_ phase: CyclePhase) -> some View {
        let isCurrent = phase == currentPhase

        return Button {
            selectedPhase = phase
        } label: {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Image(systemName: phase.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(phase.color)
                        .frame(width: 44, height: 44)
                        .background(phase.color.opacity(0.12))
                        .clipShape(Circle())
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(STOTheme.blue)
                        .frame(width: 30, height: 30)
                        .background(STOTheme.blueSoft.opacity(0.58))
                        .clipShape(Circle())
                }

                Text(phase.title)
                    .font(STOFont.display(23, relativeTo: .title3))
                    .foregroundStyle(STOTheme.blue)

                Text(phase.insight)
                    .font(STOFont.body(.caption))
                    .foregroundStyle(STOTheme.muted)
                    .lineLimit(4)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Text(isCurrent ? "CURRENT • OPEN GUIDE" : "OPEN GUIDE")
                        .font(STOFont.display(11, relativeTo: .caption2))
                        .tracking(0.7)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(phase.color)
            }
            .padding(17)
            .frame(width: 240, height: 232, alignment: .topLeading)
            .background(isCurrent ? phase.color.opacity(0.11) : STOTheme.white)
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(isCurrent ? phase.color.opacity(0.55) : STOTheme.divider, lineWidth: isCurrent ? 1.5 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        }
        .buttonStyle(PhaseGuideButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(phase.title). \(phase.insight)")
        .accessibilityHint(isCurrent ? "Current estimated phase. Opens the phase guide." : "Opens the phase guide")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
        .accessibilityIdentifier("insights.phase.\(phase.rawValue)")
    }

    private func phaseTiming(_ phase: CyclePhase) -> String {
        let cycleLength = max(store.profile.averageCycleLength, 1)
        let periodLength = min(max(store.profile.averagePeriodLength, 1), cycleLength)
        let ovulationDay = min(max(cycleLength - 14, periodLength + 2), cycleLength)

        switch phase {
        case .menstruation:
            return periodLength == 1
                ? "Estimated around cycle day 1 from your settings"
                : "Estimated around cycle days 1–\(periodLength) from your settings"
        case .follicular:
            let start = min(periodLength + 1, cycleLength)
            let end = max(start, min(ovulationDay - 2, cycleLength))
            return start == end
                ? "Estimated around cycle day \(start) from your settings"
                : "Estimated around cycle days \(start)–\(end) from your settings"
        case .ovulation:
            let start = max(1, ovulationDay - 1)
            let end = min(cycleLength, ovulationDay + 1)
            return "Estimated window around cycle days \(start)–\(end)"
        case .luteal:
            let start = min(max(ovulationDay + 2, periodLength + 1), cycleLength)
            return start == cycleLength
                ? "Estimated around cycle day \(cycleLength) from your settings"
                : "Estimated around cycle days \(start)–\(cycleLength) from your settings"
        }
    }

    private var loggedDaysThisCycle: Int {
        let anchor = store.engine.anchorDate(for: Date(), profile: store.profile, logs: store.logs)
        return store.logs.filter { $0.date >= anchor && $0.date <= Date() && $0.hasDetails }.count
    }

    private var topSymptoms: [(symptom: Symptom, count: Int)] {
        let cutoff = store.engine.calendar.date(byAdding: .day, value: -90, to: Date()) ?? .distantPast
        var counts: [Symptom: Int] = [:]
        for log in store.logs where log.date >= cutoff {
            for symptom in log.symptoms {
                counts[symptom, default: 0] += 1
            }
        }
        let mapped: [(symptom: Symptom, count: Int)] = counts.map { entry in
            (symptom: entry.key, count: entry.value)
        }
        let sorted = mapped.sorted { lhs, rhs in
            if lhs.count == rhs.count {
                return lhs.symptom.title < rhs.symptom.title
            }
            return lhs.count > rhs.count
        }
        return Array(sorted.prefix(4))
    }

    private func symptomBar(symptom: Symptom, count: Int, maximum: Int) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(symptom.title, systemImage: symptom.symbol)
                    .font(STOFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(STOTheme.ink)
                Spacer()
                Text("\(count) \(count == 1 ? "day" : "days")")
                    .font(STOFont.body(.caption, weight: .semibold))
                    .foregroundStyle(STOTheme.muted)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(STOTheme.sand.opacity(0.6))
                    Capsule()
                        .fill(LinearGradient(colors: [STOTheme.rose, STOTheme.blue], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(count) / CGFloat(max(maximum, 1)))
                }
            }
            .frame(height: 8)
            .accessibilityHidden(true)
        }
    }

    private func cycleHistoryRow(period: CyclePeriod) -> some View {
        HStack(spacing: 13) {
            Image(systemName: "drop.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(STOTheme.rose)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(period.start.formatted(.dateTime.month(.wide).day()))
                    .font(STOFont.body(.headline, weight: .semibold))
                    .foregroundStyle(STOTheme.ink)
                Text("\(store.engine.periodLength(period))-day period")
                    .font(STOFont.body(.caption))
                    .foregroundStyle(STOTheme.muted)
            }
            Spacer()
            if let previous = periods.first(where: { $0.start < period.start }) {
                let length = store.engine.calendar.dateComponents([.day], from: previous.start, to: period.start).day ?? 0
                Text("\(length)-day cycle")
                    .font(STOFont.body(.caption, weight: .semibold))
                    .foregroundStyle(STOTheme.blue)
            } else {
                Text("First record")
                    .font(STOFont.body(.caption, weight: .semibold))
                    .foregroundStyle(STOTheme.muted)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PhaseGuideButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

private struct PhaseDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let phase: CyclePhase
    let isCurrentEstimate: Bool
    let timing: String

    var body: some View {
        NavigationStack {
            ZStack {
                STOPageBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header

                        Divider().overlay(STOTheme.divider)

                        guideSection(
                            title: "What this estimate means",
                            symbol: "book.pages",
                            detail: phase.insight
                        )

                        VStack(alignment: .leading, spacing: 14) {
                            STOSectionHeader(
                                "Useful things to log",
                                eyebrow: "Build your own pattern",
                                detail: "These are prompts, not expectations. Track only what feels relevant to you."
                            )

                            ForEach(Array(prompts.enumerated()), id: \.offset) { _, prompt in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: prompt.symbol)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(phase.color)
                                        .frame(width: 36, height: 36)
                                        .background(phase.color.opacity(0.12))
                                        .clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(prompt.title)
                                            .font(STOFont.body(.subheadline, weight: .semibold))
                                            .foregroundStyle(STOTheme.ink)
                                        Text(prompt.detail)
                                            .font(STOFont.body(.caption))
                                            .foregroundStyle(STOTheme.muted)
                                    }
                                }
                            }
                        }

                        STOSafetyNote(text: "Phase timing is estimated from your cycle settings and period logs. It cannot confirm ovulation, pregnancy, or a health condition and should not be used as contraception.")
                    }
                    .padding(.horizontal, STOTheme.pagePadding)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Phase guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(STOFont.body(.body, weight: .semibold))
                        .foregroundStyle(STOTheme.blue)
                        .accessibilityIdentifier("insights.phaseDetail.close")
                }
            }
        }
        .accessibilityIdentifier("insights.phaseDetail.\(phase.rawValue)")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: phase.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(phase.color)
                    .frame(width: 62, height: 62)
                    .background(phase.color.opacity(0.13))
                    .clipShape(Circle())
                Spacer()
                if isCurrentEstimate {
                    Label("Current estimate", systemImage: "location.fill")
                        .font(STOFont.body(.caption, weight: .semibold))
                        .foregroundStyle(phase.color)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(phase.color.opacity(0.11))
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(phase.title)
                    .font(STOFont.display(36, relativeTo: .largeTitle))
                    .foregroundStyle(STOTheme.blue)
                Text(timing)
                    .font(STOFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(phase.color)
            }
        }
    }

    private func guideSection(title: String, symbol: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(title, systemImage: symbol)
                .font(STOFont.display(22, relativeTo: .title3))
                .foregroundStyle(STOTheme.blue)
            Text(detail)
                .font(STOFont.body(.body))
                .foregroundStyle(STOTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var prompts: [(symbol: String, title: String, detail: String)] {
        switch phase {
        case .menstruation:
            return [
                ("drop.fill", "Bleeding and flow", "Log period days and the closest flow level."),
                ("waveform.path.ecg", "Comfort", "Note cramps, headaches, back pain, or other symptoms."),
                ("battery.50percent", "Energy", "A quick energy check-in can reveal your own rhythm over time.")
            ]
        case .follicular:
            return [
                ("battery.75percent", "Energy", "Record how your energy actually feels rather than how it is supposed to feel."),
                ("heart.fill", "Mood", "Notice calm, sensitive, low, okay, or good days without judging them."),
                ("slider.horizontal.3", "Symptoms", "Logging changes consistently makes later comparisons more useful.")
            ]
        case .ovulation:
            return [
                ("calendar.badge.clock", "Timing", "Treat this as a broad estimate, especially when cycles vary."),
                ("waveform.path", "Body signs", "Log any discomfort or symptom changes you personally notice."),
                ("heart.fill", "Mood and energy", "Your own check-ins matter more than a generic phase description.")
            ]
        case .luteal:
            return [
                ("heart.fill", "Mood", "Track sensitivity or mood changes if they are meaningful to you."),
                ("bed.double.fill", "Sleep and energy", "Fatigue and insomnia logs can make recurring timing easier to spot."),
                ("waveform.path.ecg", "Symptoms", "Bloating, cravings, headaches, and breast tenderness may be useful to compare.")
            ]
        }
    }
}
