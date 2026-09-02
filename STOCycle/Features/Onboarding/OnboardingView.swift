import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: CycleStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: Int
    @State private var goals: Set<TrackingGoal> = []
    @State private var lastPeriodStart = Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
    @State private var cycleLength = 28
    @State private var periodLength = 5
    @State private var regularity: CycleRegularity = .unsure
    @State private var hormoneContext: HormoneContext = .preferNotToSay
    @State private var focusSymptoms: Set<Symptom> = []
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @State private var isCompleting = false
    @State private var showingReminderAlert = false

    private let totalSteps = 9

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let requestedStep = arguments
            .drop(while: { $0 != "-uiTestOnboardingStep" })
            .dropFirst()
            .first
            .flatMap(Int.init)
        _step = State(initialValue: min(max(requestedStep ?? 0, 0), 8))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            stepPager

            footer
        }
        .background(STOPageBackground())
        .alert("Notifications stayed off", isPresented: $showingReminderAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can finish setup without reminders and turn them on later in Profile.")
        }
    }

    private var stepPager: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(renderedSteps, id: \.self) { index in
                    stepView(for: index)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .offset(x: reduceMotion ? 0 : CGFloat(index - step) * proxy.size.width)
                        .opacity(reduceMotion && index != step ? 0 : 1)
                        .allowsHitTesting(index == step)
                        .accessibilityHidden(index != step)
                        .zIndex(Double(index))
                }
            }
            .clipped()
        }
    }

    private var renderedSteps: [Int] {
        Array(max(0, step - 1)...min(totalSteps - 1, step + 1))
    }

    @ViewBuilder
    private func stepView(for index: Int) -> some View {
        switch index {
        case 0: welcomeStep
        case 1: goalsStep
        case 2: lastPeriodStep
        case 3: cycleBasicsStep
        case 4: regularityStep
        case 5: hormoneContextStep
        case 6: symptomsStep
        case 7: reminderStep
        default: readyStep
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            if step > 0 {
                Button {
                    move(to: step - 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 42, height: 42)
                        .background(STOTheme.white)
                        .clipShape(Circle())
                }
                .foregroundStyle(STOTheme.blue)
                .accessibilityLabel("Back")
                .accessibilityIdentifier("onboarding.back")
            } else {
                STOBrandMark(compact: true)
            }

            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? STOTheme.rose : STOTheme.sand)
                        .frame(maxWidth: index == step ? 28 : 10)
                        .frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(step + 1) of \(totalSteps)")
        }
        .padding(.horizontal, STOTheme.pagePadding)
        .padding(.top, 12)
        .frame(height: 62)
    }

    private var welcomeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Spacer(minLength: 20)

                ZStack {
                    Circle()
                        .fill(STOTheme.roseSoft)
                        .frame(width: 160, height: 160)
                    Circle()
                        .stroke(STOTheme.rose.opacity(0.22), lineWidth: 2)
                        .frame(width: 204, height: 204)
                    Image(systemName: "calendar.day.timeline.left")
                        .font(.system(size: 62, weight: .semibold))
                        .foregroundStyle(STOTheme.rose)
                }
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 11) {
                    Text("YOUR CYCLE,\nMADE PERSONAL")
                        .font(STOFont.display(41, relativeTo: .largeTitle))
                        .foregroundStyle(STOTheme.rose)
                        .minimumScaleFactor(0.8)
                    Text("A short setup helps STÖ Cycle show the dates, shortcuts, and patterns that matter most to you.")
                        .font(STOFont.body(.title3))
                        .foregroundStyle(STOTheme.blue)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 0) {
                    valueRow(symbol: "calendar.badge.clock", title: "A useful first forecast", detail: "Based on your own recent cycle details")
                    Divider().overlay(STOTheme.divider).padding(.leading, 51)
                    valueRow(symbol: "slider.horizontal.3", title: "Faster daily check-ins", detail: "Your chosen symptoms appear first")
                    Divider().overlay(STOTheme.divider).padding(.leading, 51)
                    valueRow(symbol: "lock.shield.fill", title: "Private by design", detail: "No account, ads, backend, or data sale")
                }
                .padding(.horizontal, 16)
                .background(STOTheme.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            }
            .padding(.horizontal, STOTheme.pagePadding)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    private var goalsStep: some View {
        onboardingScroll(
            title: "What would make this useful?",
            eyebrow: "Your priorities",
            detail: "Choose all that fit. Your selections will shape Today and stay visible in Insights."
        ) {
            VStack(spacing: 11) {
                ForEach(TrackingGoal.allCases) { goal in
                    choiceRow(
                        title: goal.title,
                        detail: goal.detail,
                        symbol: goal.symbol,
                        isSelected: goals.contains(goal),
                        identifier: "onboarding.goal.\(goal.rawValue)"
                    ) {
                        toggle(goal, in: &goals)
                    }
                }
            }
        }
    }

    private var lastPeriodStep: some View {
        onboardingScroll(
            title: "When did your last period start?",
            eyebrow: "Your baseline",
            detail: "This anchors your first cycle day and estimated next period. Future period logs keep it current."
        ) {
            STOCard {
                DatePicker(
                    "Last period start",
                    selection: $lastPeriodStart,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(STOTheme.rose)
                .accessibilityIdentifier("onboarding.lastPeriodDate")
            }

            STOSafetyNote(text: "Predictions are estimates and should not be used as contraception or to diagnose a health condition.")
        }
    }

    private var cycleBasicsStep: some View {
        onboardingScroll(
            title: "A few cycle basics",
            eyebrow: "Your usual timing",
            detail: "Best guesses are completely fine. Your baseline can change later as you build a history."
        ) {
            lengthControl(
                title: "Usual cycle length",
                detail: "First day of one period to the next",
                value: $cycleLength,
                range: 15...60,
                tint: STOTheme.rose,
                identifier: "onboarding.cycleLength"
            )

            lengthControl(
                title: "Usual period length",
                detail: "The number of days you typically bleed",
                value: $periodLength,
                range: 1...min(15, cycleLength - 1),
                tint: STOTheme.blue,
                identifier: "onboarding.periodLength"
            )
        }
        .onChange(of: cycleLength) { _, newValue in
            periodLength = min(periodLength, max(1, newValue - 1))
        }
    }

    private var regularityStep: some View {
        onboardingScroll(
            title: "How predictable is your cycle?",
            eyebrow: "Set expectations",
            detail: "This changes how confidently we describe dates. It never hides your calendar or limits tracking."
        ) {
            VStack(spacing: 11) {
                ForEach(CycleRegularity.allCases) { option in
                    choiceRow(
                        title: option.title,
                        detail: option.detail,
                        symbol: option.symbol,
                        isSelected: regularity == option,
                        identifier: "onboarding.regularity.\(option.rawValue)"
                    ) {
                        regularity = option
                    }
                }
            }
        }
    }

    private var hormoneContextStep: some View {
        onboardingScroll(
            title: "Could anything affect your timing?",
            eyebrow: "Optional context",
            detail: "Some hormone-related situations can make a single predicted date less useful. We only use this to keep guidance appropriately cautious."
        ) {
            VStack(spacing: 10) {
                ForEach(HormoneContext.allCases) { option in
                    choiceRow(
                        title: option.title,
                        detail: option.detail,
                        symbol: hormoneSymbol(for: option),
                        isSelected: hormoneContext == option,
                        identifier: "onboarding.hormone.\(option.rawValue)"
                    ) {
                        hormoneContext = option
                    }
                }
            }

            STOSafetyNote(text: "This answer stays on this device. STÖ Cycle does not diagnose conditions or judge whether a cycle is normal.")
        }
    }

    private var symptomsStep: some View {
        onboardingScroll(
            title: "What do you want close at hand?",
            eyebrow: "Your check-in shortcuts",
            detail: "Choose symptoms you often notice or simply want to watch. They’ll appear first when you log a day."
        ) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 11) {
                ForEach(Symptom.allCases) { symptom in
                    symptomChoice(symptom)
                }
            }
        }
    }

    private var reminderStep: some View {
        onboardingScroll(
            title: "Would a gentle reminder help?",
            eyebrow: "Build the habit",
            detail: "A quick daily check-in creates better patterns. Notifications are optional and stay under your control."
        ) {
            STOCard {
                VStack(spacing: 17) {
                    Toggle(isOn: $reminderEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Daily check-in")
                                    .font(STOFont.body(.headline, weight: .semibold))
                                    .foregroundStyle(STOTheme.ink)
                                Text("One private prompt on this iPhone")
                                    .font(STOFont.body(.caption))
                                    .foregroundStyle(STOTheme.muted)
                            }
                        } icon: {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(STOTheme.rose)
                        }
                    }
                    .tint(STOTheme.rose)
                    .accessibilityIdentifier("onboarding.reminderToggle")

                    if reminderEnabled {
                        Divider().overlay(STOTheme.divider)
                        DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .font(STOFont.body(.subheadline, weight: .semibold))
                            .tint(STOTheme.rose)
                            .accessibilityIdentifier("onboarding.reminderTime")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                valuePoint(symbol: "hand.tap.fill", text: "A reminder opens the same quick daily log")
                valuePoint(symbol: "gearshape.fill", text: "Change the time or turn it off in Profile")
                valuePoint(symbol: "lock.fill", text: "Notification content never includes sensitive details")
            }
            .padding(.horizontal, 4)
        }
    }

    private var readyStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                STOSectionHeader(
                    "Your first cycle view is ready",
                    eyebrow: "Personalized for you",
                    detail: "Here’s what STÖ Cycle will emphasize from day one. You can still use every feature."
                )
                .padding(.top, 24)

                STOCard(background: STOTheme.roseSoft.opacity(0.5)) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ESTIMATED NEXT PERIOD")
                                .font(STOFont.display(13, relativeTo: .caption))
                                .tracking(1)
                                .foregroundStyle(STOTheme.rose)
                            Text(predictedStart.formatted(.dateTime.month(.wide).day()))
                                .font(STOFont.display(34, relativeTo: .title))
                                .foregroundStyle(STOTheme.blue)
                            Text(daysUntilPrediction == 1 ? "About 1 day away" : "About \(daysUntilPrediction) days away")
                                .font(STOFont.body(.caption, weight: .semibold))
                                .foregroundStyle(STOTheme.muted)
                        }
                        Spacer()
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(STOTheme.rose)
                            .frame(width: 58, height: 58)
                            .background(STOTheme.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .accessibilityIdentifier("onboarding.summary")

                STOCard {
                    VStack(alignment: .leading, spacing: 17) {
                        readyRow(symbol: draftProfile.primaryGoal.symbol, title: "Main focus", value: draftProfile.primaryGoal.shortTitle)
                        readyRow(symbol: regularity.symbol, title: "Forecast style", value: regularity.title)
                        readyRow(
                            symbol: "slider.horizontal.3",
                            title: "Quick symptoms",
                            value: focusSymptoms.isEmpty ? "None selected yet" : "\(focusSymptoms.count) pinned first"
                        )
                        readyRow(
                            symbol: reminderEnabled ? "bell.fill" : "bell.slash.fill",
                            title: "Daily reminder",
                            value: reminderEnabled ? reminderTime.formatted(date: .omitted, time: .shortened) : "Off for now"
                        )
                    }
                }

                Text(draftProfile.predictionGuidance)
                    .font(STOFont.body(.subheadline))
                    .foregroundStyle(STOTheme.blue)
                    .padding(.horizontal, 4)
                    .fixedSize(horizontal: false, vertical: true)

                STOSafetyNote(text: "STÖ Cycle supports self-tracking. Forecasts are estimates, not contraception or medical advice. Seek care for severe, sudden, or concerning symptoms.")
            }
            .padding(.horizontal, STOTheme.pagePadding)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    private func onboardingScroll<Content: View>(
        title: String,
        eyebrow: String,
        detail: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                STOSectionHeader(title, eyebrow: eyebrow, detail: detail)
                    .padding(.top, 24)
                content()
            }
            .padding(.horizontal, STOTheme.pagePadding)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    private func valueRow(symbol: String, title: String, detail: String) -> some View {
        HStack(spacing: 13) {
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
                    .font(STOFont.body(.caption))
                    .foregroundStyle(STOTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
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
                    .stroke(isSelected ? STOTheme.rose.opacity(0.55) : STOTheme.divider, lineWidth: isSelected ? 1.5 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    private func lengthControl(
        title: String,
        detail: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        tint: Color,
        identifier: String
    ) -> some View {
        STOCard {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(STOFont.body(.headline, weight: .semibold))
                        .foregroundStyle(STOTheme.ink)
                    Text(detail)
                        .font(STOFont.body(.caption))
                        .foregroundStyle(STOTheme.muted)
                }

                HStack {
                    Button {
                        value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 17, weight: .bold))
                            .frame(width: 46, height: 46)
                            .background(tint.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .disabled(value.wrappedValue <= range.lowerBound)
                    .accessibilityLabel("Decrease \(title.lowercased())")
                    .accessibilityIdentifier("\(identifier).decrement")

                    Spacer()
                    VStack(spacing: 0) {
                        Text("\(value.wrappedValue)")
                            .font(STOFont.display(48, relativeTo: .largeTitle))
                            .foregroundStyle(tint)
                            .contentTransition(.numericText())
                        Text("days")
                            .font(STOFont.body(.caption, weight: .semibold))
                            .foregroundStyle(STOTheme.muted)
                    }
                    Spacer()

                    Button {
                        value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .bold))
                            .frame(width: 46, height: 46)
                            .background(tint.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .disabled(value.wrappedValue >= range.upperBound)
                    .accessibilityLabel("Increase \(title.lowercased())")
                    .accessibilityIdentifier("\(identifier).increment")
                }
                .foregroundStyle(tint)
            }
        }
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
                    .stroke(isSelected ? STOTheme.blue.opacity(0.5) : STOTheme.divider, lineWidth: isSelected ? 1.5 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("onboarding.symptom.\(symptom.rawValue)")
    }

    private func valuePoint(symbol: String, text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(STOFont.body(.subheadline, weight: .medium))
            .foregroundStyle(STOTheme.ink)
            .symbolRenderingMode(.hierarchical)
    }

    private func readyRow(symbol: String, title: String, value: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(STOTheme.rose)
                .frame(width: 38, height: 38)
                .background(STOTheme.roseSoft)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(STOFont.body(.caption, weight: .semibold))
                    .foregroundStyle(STOTheme.muted)
                Text(value)
                    .font(STOFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(STOTheme.ink)
            }
            Spacer(minLength: 0)
        }
    }

    private var footer: some View {
        VStack(spacing: 9) {
            Button(action: primaryAction) {
                Text(isCompleting ? "Setting up…" : primaryButtonTitle)
            }
            .buttonStyle(STOPrimaryButtonStyle(color: step == totalSteps - 1 ? STOTheme.rose : STOTheme.blue))
            .disabled(!canContinue || isCompleting)
            .opacity(canContinue ? 1 : 0.48)
            .accessibilityIdentifier(step == totalSteps - 1 ? "onboarding.finish" : "onboarding.continue")

            Text(footerHint)
                .font(STOFont.body(.caption))
                .foregroundStyle(STOTheme.muted)
                .multilineTextAlignment(.center)
                .frame(minHeight: 17)
        }
        .padding(.horizontal, STOTheme.pagePadding)
        .padding(.top, 11)
        .padding(.bottom, 11)
        .background(.ultraThinMaterial)
    }

    private var primaryButtonTitle: String {
        switch step {
        case 0: "Personalize my cycle"
        case 7: "Review my setup"
        case 8: "See my cycle"
        default: "Continue"
        }
    }

    private var footerHint: String {
        switch step {
        case 0: "About 2 minutes • No account required"
        case 1: goals.isEmpty ? "Choose at least one priority" : "\(goals.count) \(goals.count == 1 ? "priority" : "priorities") selected"
        case 4: "This changes wording, not access to features"
        case 5: "Optional • Prefer not to say is always okay"
        case 6: focusSymptoms.isEmpty ? "Optional • You can skip this" : "\(focusSymptoms.count) symptom shortcuts selected"
        case 7: "Optional • Change this anytime in Profile"
        case 8: "Stored privately on this iPhone"
        default: "You can adjust these details later"
        }
    }

    private var canContinue: Bool {
        step != 1 || !goals.isEmpty
    }

    private var draftProfile: CycleProfile {
        CycleProfile(
            averageCycleLength: cycleLength,
            averagePeriodLength: periodLength,
            lastPeriodStart: lastPeriodStart,
            goals: goals,
            regularity: regularity,
            hormoneContext: hormoneContext,
            focusSymptoms: focusSymptoms
        )
    }

    private var predictedStart: Date {
        store.engine.nextPeriodStart(after: Date(), profile: draftProfile, logs: [])
    }

    private var daysUntilPrediction: Int {
        max(0, store.engine.calendar.dateComponents(
            [.day],
            from: store.engine.day(Date()),
            to: store.engine.day(predictedStart)
        ).day ?? 0)
    }

    private func primaryAction() {
        if step < totalSteps - 1 {
            move(to: step + 1)
        } else {
            finishOnboarding()
        }
    }

    private func move(to newStep: Int) {
        let targetStep = min(max(newStep, 0), totalSteps - 1)
        guard targetStep != step else { return }

        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.28)) {
            step = targetStep
        }
    }

    private func finishOnboarding() {
        guard !isCompleting else { return }
        let profile = draftProfile
        let time = reminderTime

        guard reminderEnabled else {
            store.completeOnboarding(profile: profile, reminders: ReminderSettings(isEnabled: false, time: time))
            return
        }

        isCompleting = true
        Task {
            let success = await ReminderScheduler.update(enabled: true, time: time)
            if success {
                store.completeOnboarding(profile: profile, reminders: ReminderSettings(isEnabled: true, time: time))
            } else {
                reminderEnabled = false
                isCompleting = false
                showingReminderAlert = true
            }
        }
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
