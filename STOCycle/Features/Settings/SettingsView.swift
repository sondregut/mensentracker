import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: CycleStore

    @State private var cycleLength = 28
    @State private var periodLength = 5
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var showingResetConfirmation = false
    @State private var showingReminderAlert = false
    @State private var showingProfileEditor = false
    @State private var didLoad = false
    @State private var hasLoadedSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                STOPageBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        profileOverview
                        profileDetails
                        settingsIntroduction
                        cycleSettings
                        reminderSettings
                        privacySection
                        supportSection
                        dataSection
                        appFooter
                    }
                    .padding(.horizontal, STOTheme.pagePadding)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear(perform: loadSettings)
        .sheet(isPresented: $showingProfileEditor) {
            ProfileEditorView(profile: store.profile) { goals, regularity, hormoneContext, focusSymptoms in
                store.updatePersonalization(
                    goals: goals,
                    regularity: regularity,
                    hormoneContext: hormoneContext,
                    focusSymptoms: focusSymptoms
                )
            }
        }
        .alert("Reminders are off", isPresented: $showingReminderAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Notification access wasn’t granted. You can allow it later in the iPhone Settings app.")
        }
        .alert("Delete all cycle data?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete all data", role: .destructive) {
                Task { _ = await ReminderScheduler.update(enabled: false, time: reminderTime) }
                store.resetAllData()
            }
        } message: {
            Text("This permanently removes your profile, logs, and reminder setting from this device.")
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            STOSectionHeader(
                "Profile",
                eyebrow: "Your cycle, your way",
                detail: "Keep the experience useful as your cycle and priorities change."
            )
            Spacer()
            STOBrandMark(compact: true)
        }
        .padding(.top, 18)
    }

    private var profileOverview: some View {
        STOCard(padding: 0, background: STOTheme.roseSoft.opacity(0.34)) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(STOTheme.white.opacity(0.9))
                        Circle()
                            .stroke(STOTheme.rose.opacity(0.16), lineWidth: 1)
                        Image(systemName: "drop.fill")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundStyle(STOTheme.rose)
                            .rotationEffect(.degrees(10))
                    }
                    .frame(width: 62, height: 62)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your cycle profile")
                            .font(STOFont.display(23, relativeTo: .title3))
                            .foregroundStyle(STOTheme.blue)
                        Label("Private on this iPhone", systemImage: "lock.fill")
                            .font(STOFont.body(.caption, weight: .semibold))
                            .foregroundStyle(STOTheme.muted)
                    }
                    Spacer(minLength: 0)
                }

                Divider().overlay(STOTheme.rose.opacity(0.13))

                HStack(spacing: 0) {
                    profileMetric(value: "\(store.profile.averageCycleLength)", label: "day cycle")
                    profileMetricDivider
                    profileMetric(value: "\(store.profile.averagePeriodLength)", label: "day period")
                    profileMetricDivider
                    profileMetric(value: "\(store.profile.focusSymptoms.count)", label: "symptoms")
                }

                Button {
                    showingProfileEditor = true
                } label: {
                    Label("Edit cycle profile", systemImage: "pencil")
                }
                .buttonStyle(STOPrimaryButtonStyle(color: STOTheme.rose))
                .accessibilityIdentifier("profile.edit")
            }
            .padding(18)
        }
    }

    private var profileDetails: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionLabel("ABOUT YOUR CYCLE")

            STOCard(padding: 0) {
                VStack(spacing: 0) {
                    profileInfoRow(
                        symbol: store.profile.primaryGoal.symbol,
                        title: "Tracking focus",
                        value: goalSummary,
                        identifier: "profile.goalSummary"
                    )
                    profileDivider
                    profileInfoRow(
                        symbol: store.profile.regularity.symbol,
                        title: "Cycle pattern",
                        value: store.profile.regularity.title,
                        identifier: "profile.regularitySummary"
                    )
                    profileDivider
                    profileInfoRow(
                        symbol: "heart.text.square.fill",
                        title: "Hormone context",
                        value: store.profile.hormoneContext.title,
                        identifier: "profile.hormoneSummary"
                    )
                    profileDivider
                    profileInfoRow(
                        symbol: "waveform.path.ecg",
                        title: "Symptom shortcuts",
                        value: symptomSummary,
                        identifier: "profile.symptomSummary"
                    )
                }
            }
        }
    }

    private var settingsIntroduction: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionLabel("SETTINGS")
            Text("Fine-tune forecasts, check-ins, and what stays on this device.")
                .font(STOFont.body(.subheadline))
                .foregroundStyle(STOTheme.muted)
        }
        .padding(.top, 2)
    }

    private var cycleSettings: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("CYCLE BASELINE")
                .font(STOFont.display(14, relativeTo: .caption))
                .tracking(1.1)
                .foregroundStyle(STOTheme.rose)

            STOCard(padding: 0) {
                VStack(spacing: 0) {
                    settingStepper(
                        title: "Cycle length",
                        detail: "First day to first day",
                        value: $cycleLength,
                        range: 15...60,
                        symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                        identifier: "settings.cycleStepper"
                    )
                    Divider().overlay(STOTheme.divider).padding(.leading, 67)
                    settingStepper(
                        title: "Period length",
                        detail: "Typical bleeding days",
                        value: $periodLength,
                        range: 1...min(15, max(cycleLength - 1, 1)),
                        symbol: "drop.fill",
                        identifier: "settings.periodStepper"
                    )
                }
            }
        }
        .onChange(of: cycleLength) { _, newValue in
            guard didLoad else { return }
            periodLength = min(periodLength, max(1, newValue - 1))
            saveCycleSettings()
        }
        .onChange(of: periodLength) { _, _ in
            guard didLoad else { return }
            saveCycleSettings()
        }
    }

    private var reminderSettings: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("REMINDERS")
                .font(STOFont.display(14, relativeTo: .caption))
                .tracking(1.1)
                .foregroundStyle(STOTheme.rose)

            STOCard {
                VStack(spacing: 16) {
                    Toggle(isOn: $reminderEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Daily check-in")
                                    .font(STOFont.body(.headline, weight: .semibold))
                                    .foregroundStyle(STOTheme.ink)
                                Text("A gentle prompt to log how you feel")
                                    .font(STOFont.body(.caption))
                                    .foregroundStyle(STOTheme.muted)
                            }
                        } icon: {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(STOTheme.rose)
                        }
                    }
                    .tint(STOTheme.rose)
                    .accessibilityIdentifier("settings.reminderToggle")

                    if reminderEnabled {
                        Divider().overlay(STOTheme.divider)
                        DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .font(STOFont.body(.subheadline, weight: .semibold))
                            .foregroundStyle(STOTheme.ink)
                            .tint(STOTheme.rose)
                            .accessibilityIdentifier("settings.reminderTime")
                    }
                }
            }
        }
        .onChange(of: reminderEnabled) { _, enabled in
            guard didLoad else { return }
            updateReminder(enabled: enabled)
        }
        .onChange(of: reminderTime) { _, _ in
            guard didLoad, reminderEnabled else { return }
            updateReminder(enabled: true)
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("PRIVACY")
                .font(STOFont.display(14, relativeTo: .caption))
                .tracking(1.1)
                .foregroundStyle(STOTheme.rose)

            STOCard(background: STOTheme.blueSoft.opacity(0.45)) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(STOTheme.blue)
                        .frame(width: 46, height: 46)
                        .background(STOTheme.white.opacity(0.8))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Local-first health data")
                            .font(STOFont.body(.headline, weight: .semibold))
                            .foregroundStyle(STOTheme.ink)
                        Text("Your profile and logs stay in this app on this device. There is no account, cloud sync, ad tracking, or data sale in this MVP.")
                            .font(STOFont.body(.subheadline))
                            .foregroundStyle(STOTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("HEALTH & SUPPORT")
                .font(STOFont.display(14, relativeTo: .caption))
                .tracking(1.1)
                .foregroundStyle(STOTheme.rose)

            STOCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("When to seek care", systemImage: "cross.case.fill")
                        .font(STOFont.body(.headline, weight: .semibold))
                        .foregroundStyle(STOTheme.blue)
                    Text("Seek urgent medical help for severe or sudden pelvic pain, very heavy bleeding, fainting or dizziness—especially if pregnancy is possible. Contact a clinician when symptoms worsen or disrupt everyday life.")
                        .font(STOFont.body(.subheadline))
                        .foregroundStyle(STOTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    Link(destination: URL(string: "https://www.stostore.no/")!) {
                        Label("Visit STÖ", systemImage: "arrow.up.right")
                            .font(STOFont.body(.subheadline, weight: .semibold))
                            .foregroundStyle(STOTheme.rose)
                    }
                    .accessibilityIdentifier("settings.visitSTO")
                }
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("YOUR DATA")
                .font(STOFont.display(14, relativeTo: .caption))
                .tracking(1.1)
                .foregroundStyle(STOTheme.rose)

            STOCard(padding: 0) {
                VStack(spacing: 0) {
                    ShareLink(
                        item: store.exportText(),
                        subject: Text("STÖ Cycle data export"),
                        message: Text("Your private STÖ Cycle data in JSON format.")
                    ) {
                        settingsActionRow(symbol: "square.and.arrow.up", title: "Export my data", color: STOTheme.blue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.export")

                    Divider().overlay(STOTheme.divider).padding(.leading, 66)

                    Button {
                        showingResetConfirmation = true
                    } label: {
                        settingsActionRow(symbol: "trash.fill", title: "Delete all data", color: .red)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.delete")
                }
            }
        }
    }

    private var appFooter: some View {
        VStack(spacing: 6) {
            STOBrandMark(compact: true)
            Text("Version 1.0 • MVP")
                .font(STOFont.body(.caption))
                .foregroundStyle(STOTheme.muted)
            Text("Tracking support, not medical advice")
                .font(STOFont.body(.caption2))
                .foregroundStyle(STOTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(STOFont.display(14, relativeTo: .caption))
            .tracking(1.1)
            .foregroundStyle(STOTheme.rose)
    }

    private func profileMetric(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(STOFont.display(28, relativeTo: .title2))
                .foregroundStyle(STOTheme.blue)
                .monospacedDigit()
            Text(label)
                .font(STOFont.body(.caption2, weight: .semibold))
                .foregroundStyle(STOTheme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private var profileMetricDivider: some View {
        Rectangle()
            .fill(STOTheme.rose.opacity(0.14))
            .frame(width: 1, height: 34)
    }

    private var profileDivider: some View {
        Divider()
            .overlay(STOTheme.divider)
            .padding(.leading, 66)
    }

    private func profileInfoRow(
        symbol: String,
        title: String,
        value: String,
        identifier: String
    ) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(STOTheme.blue)
                .frame(width: 38, height: 38)
                .background(STOTheme.blueSoft.opacity(0.78))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(STOFont.body(.caption, weight: .semibold))
                    .foregroundStyle(STOTheme.muted)
                Text(value)
                    .font(STOFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(STOTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(identifier)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private var goalSummary: String {
        let selected = TrackingGoal.allCases.filter(store.profile.goals.contains)
        guard let first = selected.first else { return TrackingGoal.predictPeriods.shortTitle }
        guard selected.count > 1 else { return first.shortTitle }
        return "\(first.shortTitle) + \(selected.count - 1) more"
    }

    private var symptomSummary: String {
        let selected = Symptom.allCases.filter(store.profile.focusSymptoms.contains)
        guard !selected.isEmpty else { return "No shortcuts selected" }
        let visible = selected.prefix(2).map(\.title).joined(separator: ", ")
        let remaining = selected.count - min(selected.count, 2)
        return remaining > 0 ? "\(visible) + \(remaining) more" : visible
    }

    private func settingStepper(
        title: String,
        detail: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        symbol: String,
        identifier: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(STOTheme.rose)
                .frame(width: 38, height: 38)
                .background(STOTheme.roseSoft)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(STOFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(STOTheme.ink)
                Text(detail)
                    .font(STOFont.body(.caption2))
                    .foregroundStyle(STOTheme.muted)
            }
            Spacer(minLength: 5)
            Stepper(value: value, in: range) {
                Text("\(value.wrappedValue) days")
                    .font(STOFont.body(.subheadline, weight: .bold))
                    .foregroundStyle(STOTheme.blue)
                    .monospacedDigit()
                    .frame(minWidth: 62, alignment: .trailing)
            }
            .labelsHidden()
            .accessibilityIdentifier(identifier)
            Text("\(value.wrappedValue)d")
                .font(STOFont.body(.subheadline, weight: .bold))
                .foregroundStyle(STOTheme.blue)
                .monospacedDigit()
                .frame(width: 34)
        }
        .padding(15)
    }

    private func settingsActionRow(symbol: String, title: String, color: Color) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            Text(title)
                .font(STOFont.body(.subheadline, weight: .semibold))
                .foregroundStyle(color)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(STOTheme.muted.opacity(0.55))
        }
        .padding(15)
        .contentShape(Rectangle())
    }

    private func loadSettings() {
        guard !hasLoadedSettings else { return }
        hasLoadedSettings = true
        cycleLength = store.profile.averageCycleLength
        periodLength = store.profile.averagePeriodLength
        reminderEnabled = store.state.reminders.isEnabled
        reminderTime = store.state.reminders.time
        Task { @MainActor in
            await Task.yield()
            await Task.yield()
            didLoad = true
        }
    }

    private func saveCycleSettings() {
        store.updateProfile(cycleLength: cycleLength, periodLength: periodLength)
    }

    private func updateReminder(enabled: Bool) {
        let time = reminderTime
        Task {
            let success = await ReminderScheduler.update(enabled: enabled, time: time)
            if success {
                store.updateReminders(enabled: enabled, time: time)
            } else {
                reminderEnabled = false
                store.updateReminders(enabled: false, time: time)
                showingReminderAlert = true
            }
        }
    }
}

private struct ProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (Set<TrackingGoal>, CycleRegularity, HormoneContext, Set<Symptom>) -> Void

    @State private var goals: Set<TrackingGoal>
    @State private var regularity: CycleRegularity
    @State private var hormoneContext: HormoneContext
    @State private var focusSymptoms: Set<Symptom>

    init(
        profile: CycleProfile,
        onSave: @escaping (Set<TrackingGoal>, CycleRegularity, HormoneContext, Set<Symptom>) -> Void
    ) {
        self.onSave = onSave
        _goals = State(initialValue: profile.goals)
        _regularity = State(initialValue: profile.regularity)
        _hormoneContext = State(initialValue: profile.hormoneContext)
        _focusSymptoms = State(initialValue: profile.focusSymptoms)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                STOPageBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        editorHeader
                        goalsSection
                        regularitySection
                        hormoneSection
                        symptomsSection
                        STOSafetyNote(text: "These details personalize wording and shortcuts. They do not diagnose a condition or make cycle forecasts certain.")
                    }
                    .padding(.horizontal, STOTheme.pagePadding)
                    .padding(.top, 16)
                    .padding(.bottom, 38)
                }
            }
            .accessibilityIdentifier("profile.editor")
            .navigationTitle("Edit cycle profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(STOTheme.cream.opacity(0.96), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(STOTheme.blue)
                        .accessibilityIdentifier("profile.editor.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(goals, regularity, hormoneContext, focusSymptoms)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(STOTheme.rose)
                    .disabled(goals.isEmpty)
                    .accessibilityIdentifier("profile.editor.save")
                }
            }
        }
    }

    private var editorHeader: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("MAKE IT FEEL LIKE YOURS")
                .font(STOFont.display(13, relativeTo: .caption))
                .tracking(1.1)
                .foregroundStyle(STOTheme.rose)
            Text("Tune your experience")
                .font(STOFont.display(28, relativeTo: .title2))
                .foregroundStyle(STOTheme.blue)
            Text("Update what you want to learn, the context around your cycle, and the symptoms you reach for most.")
                .font(STOFont.body(.subheadline))
                .foregroundStyle(STOTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var goalsSection: some View {
        editorSection(
            title: "YOUR GOALS",
            detail: goals.isEmpty ? "Choose at least one to save." : "Choose all that matter right now."
        ) {
            VStack(spacing: 10) {
                ForEach(TrackingGoal.allCases) { goal in
                    choiceRow(
                        title: goal.title,
                        detail: goal.detail,
                        symbol: goal.symbol,
                        isSelected: goals.contains(goal),
                        identifier: "profile.goal.\(goal.rawValue)"
                    ) {
                        toggle(goal, in: &goals)
                    }
                }
            }
        }
    }

    private var regularitySection: some View {
        editorSection(
            title: "CYCLE PATTERN",
            detail: "This helps the app describe forecast confidence honestly."
        ) {
            VStack(spacing: 10) {
                ForEach(CycleRegularity.allCases) { option in
                    choiceRow(
                        title: option.title,
                        detail: option.detail,
                        symbol: option.symbol,
                        isSelected: regularity == option,
                        identifier: "profile.regularity.\(option.rawValue)"
                    ) {
                        regularity = option
                    }
                }
            }
        }
    }

    private var hormoneSection: some View {
        editorSection(
            title: "HORMONE CONTEXT",
            detail: "Optional. This only adjusts guidance about cycle timing."
        ) {
            VStack(spacing: 10) {
                ForEach(HormoneContext.allCases) { option in
                    choiceRow(
                        title: option.title,
                        detail: option.detail,
                        symbol: hormoneSymbol(for: option),
                        isSelected: hormoneContext == option,
                        identifier: "profile.hormone.\(option.rawValue)"
                    ) {
                        hormoneContext = option
                    }
                }
            }
        }
    }

    private var symptomsSection: some View {
        editorSection(
            title: "SYMPTOM SHORTCUTS",
            detail: focusSymptoms.isEmpty
                ? "Optional. Pick symptoms to keep them easy to find."
                : "\(focusSymptoms.count) selected for quicker daily logging."
        ) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(Symptom.allCases) { symptom in
                    symptomChoice(symptom)
                }
            }
        }
    }

    private func editorSection<Content: View>(
        title: String,
        detail: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(STOFont.display(14, relativeTo: .caption))
                    .tracking(1.05)
                    .foregroundStyle(STOTheme.rose)
                Text(detail)
                    .font(STOFont.body(.caption))
                    .foregroundStyle(STOTheme.muted)
            }
            content()
        }
    }

    private func choiceRow(
        title: String,
        detail: String,
        symbol: String,
        isSelected: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : STOTheme.blue)
                    .frame(width: 42, height: 42)
                    .background(isSelected ? STOTheme.rose : STOTheme.blueSoft)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(STOFont.body(.subheadline, weight: .semibold))
                        .foregroundStyle(STOTheme.ink)
                    Text(detail)
                        .font(STOFont.body(.caption))
                        .foregroundStyle(STOTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? STOTheme.rose : STOTheme.sand)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? STOTheme.roseSoft.opacity(0.42) : STOTheme.white)
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? STOTheme.rose.opacity(0.55) : STOTheme.divider,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(ProfilePressButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    private func symptomChoice(_ symptom: Symptom) -> some View {
        let isSelected = focusSymptoms.contains(symptom)
        return Button {
            toggle(symptom, in: &focusSymptoms)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: symptom.symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : STOTheme.blue)
                        .frame(width: 39, height: 39)
                        .background(isSelected ? STOTheme.blue : STOTheme.blueSoft)
                        .clipShape(Circle())
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? STOTheme.rose : STOTheme.sand)
                }
                Text(symptom.title)
                    .font(STOFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(STOTheme.ink)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .background(isSelected ? STOTheme.blueSoft.opacity(0.48) : STOTheme.white)
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(
                        isSelected ? STOTheme.blue.opacity(0.5) : STOTheme.divider,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        }
        .buttonStyle(ProfilePressButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("profile.symptom.\(symptom.rawValue)")
    }

    private func toggle<Value: Hashable>(_ value: Value, in set: inout Set<Value>) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }

    private func hormoneSymbol(for context: HormoneContext) -> String {
        switch context {
        case .none: "checkmark.circle.fill"
        case .hormonalContraception: "pills.fill"
        case .postpartum: "figure.and.child.holdinghands"
        case .perimenopause: "waveform.path"
        case .fertilityTreatment: "cross.case.fill"
        case .preferNotToSay: "hand.raised.fill"
        }
    }
}

private struct ProfilePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.13), value: configuration.isPressed)
    }
}
