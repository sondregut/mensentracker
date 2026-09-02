import SwiftUI

struct DailyLogView: View {
    @EnvironmentObject private var store: CycleStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var notesFocused: Bool

    let date: Date
    @State private var draft: DailyLog
    @State private var didLoad = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    init(date: Date) {
        self.date = date
        _draft = State(initialValue: DailyLog(date: date))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                STOPageBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        dateHeader
                        periodSection
                        moodSection
                        symptomsSection
                        energySection
                        notesSection
                        STOSafetyNote(text: "Your log is private and stored only on this device. Symptoms can have many causes; this app does not diagnose them.")
                    }
                    .padding(.horizontal, STOTheme.pagePadding)
                    .padding(.bottom, 96)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Daily log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(STOTheme.blue)
                        .accessibilityIdentifier("log.cancel")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Save log") {
                    store.save(draft)
                    dismiss()
                }
                .buttonStyle(STOPrimaryButtonStyle(color: STOTheme.rose))
                .padding(.horizontal, STOTheme.pagePadding)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .accessibilityIdentifier("log.save")
            }
        }
        .onAppear {
            guard !didLoad else { return }
            draft = store.log(on: date) ?? DailyLog(date: date)
            didLoad = true
        }
    }

    private var dateHeader: some View {
        VStack(spacing: 7) {
            Text(date.formatted(.dateTime.weekday(.wide)))
                .font(STOFont.display(15, relativeTo: .caption))
                .tracking(1.1)
                .foregroundStyle(STOTheme.rose)
                .textCase(.uppercase)
            Text(date.formatted(.dateTime.month(.wide).day().year()))
                .font(STOFont.display(31, relativeTo: .title))
                .foregroundStyle(STOTheme.blue)
            let day = store.engine.cycleDay(for: date, profile: store.profile, logs: store.logs)
            PhaseBadge(phase: store.engine.phase(for: date, profile: store.profile, logs: store.logs))
                .accessibilityHint("Cycle day \(day)")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }

    private var periodSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            STOSectionHeader("Period", detail: "Mark bleeding and choose the closest flow level.")

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    draft.isPeriod.toggle()
                    if draft.isPeriod, draft.flow == nil { draft.flow = .medium }
                    if !draft.isPeriod { draft.flow = nil }
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(draft.isPeriod ? Color.white : STOTheme.rose)
                        .frame(width: 46, height: 46)
                        .background(draft.isPeriod ? STOTheme.rose : STOTheme.roseSoft)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(draft.isPeriod ? "Period logged" : "Log period")
                            .font(STOFont.body(.headline, weight: .semibold))
                            .foregroundStyle(STOTheme.ink)
                        Text(draft.isPeriod ? "Tap to remove it from this day" : "Tap if you’re bleeding today")
                            .font(STOFont.body(.caption))
                            .foregroundStyle(STOTheme.muted)
                    }
                    Spacer()
                    Image(systemName: draft.isPeriod ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(draft.isPeriod ? STOTheme.rose : STOTheme.sand)
                }
                .padding(16)
                .background(STOTheme.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(draft.isPeriod ? STOTheme.rose.opacity(0.55) : STOTheme.divider, lineWidth: 1.2)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("log.periodToggle")

            if draft.isPeriod {
                HStack(spacing: 10) {
                    ForEach(FlowLevel.allCases) { flow in
                        Button {
                            draft.flow = flow
                        } label: {
                            VStack(spacing: 8) {
                                HStack(spacing: 2) {
                                    ForEach(0..<flow.drops, id: \.self) { _ in
                                        Image(systemName: "drop.fill")
                                    }
                                }
                                .font(.system(size: 14, weight: .semibold))
                                Text(flow.title)
                                    .font(STOFont.body(.caption, weight: .semibold))
                            }
                            .foregroundStyle(draft.flow == flow ? Color.white : STOTheme.rose)
                            .frame(maxWidth: .infinity, minHeight: 78)
                            .background(draft.flow == flow ? STOTheme.rose : STOTheme.white)
                            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 17, style: .continuous)
                                    .stroke(STOTheme.rose.opacity(0.28), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(draft.flow == flow ? .isSelected : [])
                        .accessibilityIdentifier("log.flow.\(flow.rawValue)")
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            STOSectionHeader("Mood", detail: "Choose the closest match. You can leave this blank.")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Mood.allCases) { mood in
                        STOIconTile(
                            title: mood.title,
                            symbol: mood.symbol,
                            isSelected: draft.mood == mood,
                            color: STOTheme.blue
                        ) {
                            draft.mood = draft.mood == mood ? nil : mood
                        }
                        .frame(width: 94)
                        .accessibilityIdentifier("log.mood.\(mood.rawValue)")
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            STOSectionHeader(
                "Symptoms",
                detail: store.profile.focusSymptoms.isEmpty
                    ? "Select anything you noticed today."
                    : "Your onboarding shortcuts appear first. Select anything you noticed today."
            )
            LazyVGrid(columns: columns, spacing: 11) {
                ForEach(orderedSymptoms) { symptom in
                    Button {
                        if draft.symptoms.contains(symptom) {
                            draft.symptoms.remove(symptom)
                        } else {
                            draft.symptoms.insert(symptom)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: symptom.symbol)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(draft.symptoms.contains(symptom) ? Color.white : STOTheme.blue)
                                .frame(width: 34, height: 34)
                                .background(draft.symptoms.contains(symptom) ? STOTheme.blue : STOTheme.blueSoft)
                                .clipShape(Circle())
                            Text(symptom.title)
                                .font(STOFont.body(.caption, weight: .semibold))
                                .foregroundStyle(STOTheme.ink)
                                .lineLimit(2)
                            if store.profile.focusSymptoms.contains(symptom) {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(STOTheme.rose)
                                    .accessibilityHidden(true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(11)
                        .frame(maxWidth: .infinity, minHeight: 59, alignment: .leading)
                        .background(draft.symptoms.contains(symptom) ? STOTheme.blueSoft.opacity(0.42) : STOTheme.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .stroke(draft.symptoms.contains(symptom) ? STOTheme.blue.opacity(0.55) : STOTheme.divider, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(draft.symptoms.contains(symptom) ? .isSelected : [])
                    .accessibilityIdentifier("log.symptom.\(symptom.rawValue)")
                }
            }
        }
    }

    private var orderedSymptoms: [Symptom] {
        let focused = Symptom.allCases.filter(store.profile.focusSymptoms.contains)
        let remaining = Symptom.allCases.filter { !store.profile.focusSymptoms.contains($0) }
        return focused + remaining
    }

    private var energySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            STOSectionHeader("Energy", detail: "1 is depleted, 5 is full of energy.")
            HStack(spacing: 9) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        draft.energy = draft.energy == level ? nil : level
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: level <= (draft.energy ?? 0) ? "bolt.fill" : "bolt")
                                .font(.system(size: 18, weight: .bold))
                            Text("\(level)")
                                .font(STOFont.body(.caption, weight: .bold))
                        }
                        .foregroundStyle(draft.energy == level ? Color.white : STOTheme.rose)
                        .frame(maxWidth: .infinity, minHeight: 68)
                        .background(draft.energy == level ? STOTheme.rose : STOTheme.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Energy \(level) of 5")
                    .accessibilityAddTraits(draft.energy == level ? .isSelected : [])
                    .accessibilityIdentifier("log.energy.\(level)")
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            STOSectionHeader("Notes", detail: "Anything else worth remembering?")
            TextEditor(text: $draft.notes)
                .font(STOFont.body(.body))
                .foregroundStyle(STOTheme.ink)
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(minHeight: 128)
                .background(STOTheme.white)
                .overlay(alignment: .topLeading) {
                    if draft.notes.isEmpty && !notesFocused {
                        Text("Sleep, medication, movement, context…")
                            .font(STOFont.body(.body))
                            .foregroundStyle(STOTheme.muted.opacity(0.7))
                            .padding(.horizontal, 17)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(notesFocused ? STOTheme.rose.opacity(0.55) : STOTheme.divider, lineWidth: 1)
                }
                .focused($notesFocused)
                .accessibilityIdentifier("log.notes")
        }
    }
}
