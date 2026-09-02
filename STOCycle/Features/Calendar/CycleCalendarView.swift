import SwiftUI

struct CycleCalendarView: View {
    @EnvironmentObject private var store: CycleStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()
    @State private var showingLog = false

    private var calendar: Calendar { store.engine.calendar }

    var body: some View {
        NavigationStack {
            ZStack {
                STOPageBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        calendarCard
                        legend
                        selectedDayCard
                        STOSafetyNote(text: "Predicted periods and fertile windows are estimates based on your cycle settings and logs. They are not contraception.")
                    }
                    .padding(.horizontal, STOTheme.pagePadding)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingLog) {
                DailyLogView(date: selectedDate)
                    .environmentObject(store)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            STOSectionHeader(
                "Your calendar",
                eyebrow: "Cycle map",
                detail: "Logged days are solid. Forecasts are softly outlined."
            )
            Button {
                moveToToday()
            } label: {
                Text("Today")
                    .font(STOFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(STOTheme.blue)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(STOTheme.white)
                    .clipShape(Capsule())
            }
            .accessibilityIdentifier("calendar.today")
        }
        .padding(.top, 18)
    }

    private var calendarCard: some View {
        STOCard(padding: 16) {
            VStack(spacing: 17) {
                HStack {
                    monthButton(symbol: "chevron.left", accessibilityLabel: "Previous month") {
                        moveMonth(by: -1)
                    }
                    .accessibilityIdentifier("calendar.previousMonth")
                    Spacer()
                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(STOFont.display(28, relativeTo: .title2))
                        .foregroundStyle(STOTheme.blue)
                        .contentTransition(.numericText())
                    Spacer()
                    monthButton(symbol: "chevron.right", accessibilityLabel: "Next month") {
                        moveMonth(by: 1)
                    }
                    .accessibilityIdentifier("calendar.nextMonth")
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 7) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol.uppercased())
                            .font(STOFont.display(12, relativeTo: .caption2))
                            .foregroundStyle(STOTheme.muted)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(monthGridDates, id: \.self) { date in
                        CalendarDayCell(
                            date: date,
                            status: store.engine.status(for: date, profile: store.profile, logs: store.logs),
                            isInDisplayedMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasLog: store.log(on: date)?.hasDetails == true
                        ) {
                            selectedDate = date
                            if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
                                displayedMonth = date
                            }
                        }
                        .accessibilityIdentifier("calendar.day.\(dateKey(date))")
                    }
                }
            }
        }
    }

    private var legend: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
            legendItem("Logged", color: STOTheme.rose, style: .solid)
            legendItem("Predicted", color: STOTheme.rose, style: .outline)
            legendItem("Fertile estimate", color: STOTheme.blue, style: .soft)
            legendItem("Ovulation estimate", color: STOTheme.blue, style: .ring)
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Calendar legend")
    }

    private var selectedDayCard: some View {
        let phase = store.engine.phase(for: selectedDate, profile: store.profile, logs: store.logs)
        let cycleDay = store.engine.cycleDay(for: selectedDate, profile: store.profile, logs: store.logs)
        let log = store.log(on: selectedDate)

        return STOCard {
            VStack(alignment: .leading, spacing: 17) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                            .font(STOFont.display(26, relativeTo: .title2))
                            .foregroundStyle(STOTheme.blue)
                        Text("Cycle day \(cycleDay)")
                            .font(STOFont.body(.caption, weight: .semibold))
                            .foregroundStyle(STOTheme.muted)
                    }
                    Spacer()
                    PhaseBadge(phase: phase)
                }

                Divider().overlay(STOTheme.divider)

                if let log, log.hasDetails {
                    VStack(alignment: .leading, spacing: 11) {
                        if log.isPeriod {
                            detailRow(symbol: "drop.fill", title: "Period", value: log.flow?.title ?? "Logged", color: STOTheme.rose)
                        }
                        if let mood = log.mood {
                            detailRow(symbol: mood.symbol, title: "Mood", value: mood.title, color: STOTheme.blue)
                        }
                        if let energy = log.energy {
                            detailRow(symbol: "bolt.fill", title: "Energy", value: "\(energy) of 5", color: STOTheme.rose)
                        }
                        if !log.symptoms.isEmpty {
                            detailRow(
                                symbol: "waveform.path.ecg",
                                title: "Symptoms",
                                value: log.symptoms.map(\.title).sorted().joined(separator: ", "),
                                color: STOTheme.blue
                            )
                        }
                    }
                } else {
                    HStack(spacing: 11) {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(STOTheme.rose)
                        Text("Nothing logged for this day yet.")
                            .font(STOFont.body(.subheadline))
                            .foregroundStyle(STOTheme.muted)
                    }
                }

                Button(log?.hasDetails == true ? "Edit this day" : "Log this day") {
                    showingLog = true
                }
                .buttonStyle(STOPrimaryButtonStyle(color: STOTheme.blue))
                .accessibilityIdentifier("calendar.logSelected")
            }
        }
    }

    private func monthButton(symbol: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(STOTheme.blue)
                .frame(width: 42, height: 42)
                .background(STOTheme.blueSoft.opacity(0.58))
                .clipShape(Circle())
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private func moveMonth(by offset: Int) {
        let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) ?? displayedMonth
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
            displayedMonth = newMonth
            selectedDate = calendar.date(from: calendar.dateComponents([.year, .month], from: newMonth)) ?? newMonth
        }
    }

    private func moveToToday() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
            displayedMonth = Date()
            selectedDate = Date()
        }
    }

    private var monthGridDates: [Date] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let weekday = calendar.dateComponents([.weekday], from: monthStart).weekday else {
            return []
        }

        let leading = (weekday - calendar.firstWeekday + 7) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -leading, to: monthStart) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let index = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[index...] + symbols[..<index])
    }

    private func detailRow(symbol: String, title: String, value: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.11))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(STOFont.body(.caption, weight: .semibold))
                    .foregroundStyle(STOTheme.muted)
                Text(value)
                    .font(STOFont.body(.subheadline, weight: .medium))
                    .foregroundStyle(STOTheme.ink)
            }
        }
    }

    private enum LegendStyle { case solid, outline, soft, ring }

    private func legendItem(_ title: String, color: Color, style: LegendStyle) -> some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(style == .solid ? color : (style == .soft ? color.opacity(0.16) : Color.clear))
                if style == .outline {
                    Circle().stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                } else if style == .ring {
                    Circle().stroke(color, lineWidth: 2)
                    Circle().fill(color).frame(width: 4, height: 4)
                }
            }
            .frame(width: 15, height: 15)
            Text(title)
                .font(STOFont.body(.caption, weight: .medium))
                .foregroundStyle(STOTheme.muted)
        }
    }

    private func dateKey(_ date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let status: CalendarDayStatus
    let isInDisplayedMonth: Bool
    let isSelected: Bool
    let isToday: Bool
    let hasLog: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                background

                Text(date.formatted(.dateTime.day()))
                    .font(STOFont.body(.subheadline, weight: isToday || isSelected ? .bold : .medium))
                    .foregroundStyle(foregroundColor)

                if hasLog && status != .loggedPeriod {
                    Circle()
                        .fill(STOTheme.rose)
                        .frame(width: 5, height: 5)
                        .offset(y: 15)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if isSelected {
                    Circle().stroke(STOTheme.blue, lineWidth: 2.5)
                }
            }
            .opacity(isInDisplayedMonth ? 1 : 0.28)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var background: some View {
        switch status {
        case .loggedPeriod:
            Circle().fill(STOTheme.rose)
        case .predictedPeriod:
            Circle().fill(STOTheme.roseSoft.opacity(0.7))
                .overlay { Circle().stroke(STOTheme.rose, style: StrokeStyle(lineWidth: 1.3, dash: [3, 2])) }
        case .fertile:
            Circle().fill(STOTheme.blueSoft)
        case .ovulation:
            Circle().fill(STOTheme.white)
                .overlay {
                    Circle().stroke(STOTheme.blue, lineWidth: 2)
                    Circle().fill(STOTheme.blue).frame(width: 5, height: 5)
                }
        case .none:
            Circle().fill(isToday ? STOTheme.sand.opacity(0.65) : Color.clear)
        }
    }

    private var foregroundColor: Color {
        if status == .loggedPeriod { return .white }
        if !isInDisplayedMonth { return STOTheme.muted }
        if status == .fertile || status == .ovulation { return STOTheme.blue }
        return STOTheme.ink
    }

    private var accessibilityLabel: String {
        var parts = [date.formatted(date: .complete, time: .omitted)]
        if isToday { parts.append("today") }
        switch status {
        case .loggedPeriod: parts.append("logged period")
        case .predictedPeriod: parts.append("predicted period")
        case .fertile: parts.append("estimated fertile window")
        case .ovulation: parts.append("estimated ovulation")
        case .none: break
        }
        if hasLog { parts.append("has a daily log") }
        return parts.joined(separator: ", ")
    }
}
