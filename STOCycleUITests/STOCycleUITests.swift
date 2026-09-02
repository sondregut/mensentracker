import XCTest

@MainActor
final class STOCycleUITests: XCTestCase {
    private let existenceTimeout: TimeInterval = 5

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingCompletesIntoToday() {
        let app = launch(arguments: ["-uiTestReset"])

        tap("onboarding.continue", in: app)
        tap("onboarding.goal.predictPeriods", in: app)
        for _ in 0..<7 {
            tap("onboarding.continue", in: app)
        }
        tap("onboarding.finish", in: app)

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: existenceTimeout))
        XCTAssertTrue(element("hero.log", in: app).exists)
        XCTAssertTrue(element("home.personalFocus", in: app).exists)
    }

    func testOnboardingBackReturnsToPreviousQuestion() {
        let app = launch(arguments: ["-uiTestReset", "-uiTestOnboardingStep", "2"])

        XCTAssertTrue(app.staticTexts["When did your last period start?"].waitForExistence(timeout: existenceTimeout))
        tap("onboarding.back", in: app)

        XCTAssertTrue(app.staticTexts["What would make this useful?"].waitForExistence(timeout: existenceTimeout))
        XCTAssertFalse(app.staticTexts["When did your last period start?"].exists)
    }

    func testEveryOnboardingControlResponds() {
        let app = launch(arguments: ["-uiTestReset"])

        tap("onboarding.continue", in: app)

        for goal in ["predictPeriods", "understandSymptoms", "planAhead", "buildHistory"] {
            revealAndTap("onboarding.goal.\(goal)", in: app)
            XCTAssertTrue(element("onboarding.goal.\(goal)", in: app).isSelected)
        }

        tap("onboarding.back", in: app)
        XCTAssertTrue(app.staticTexts["YOUR CYCLE,\nMADE PERSONAL"].waitForExistence(timeout: existenceTimeout))
        tap("onboarding.continue", in: app)
        tap("onboarding.continue", in: app)

        let datePicker = element("onboarding.lastPeriodDate", in: app)
        XCTAssertTrue(datePicker.waitForExistence(timeout: existenceTimeout))
        datePicker.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.72)).tap()

        tap("onboarding.back", in: app)
        XCTAssertTrue(app.staticTexts["What would make this useful?"].waitForExistence(timeout: existenceTimeout))
        tap("onboarding.continue", in: app)
        tap("onboarding.continue", in: app)

        tap("onboarding.cycleLength.decrement", in: app)
        tap("onboarding.cycleLength.increment", in: app)
        revealAndTap("onboarding.periodLength.decrement", in: app)
        tap("onboarding.periodLength.increment", in: app)

        tap("onboarding.back", in: app)
        XCTAssertTrue(app.staticTexts["When did your last period start?"].waitForExistence(timeout: existenceTimeout))
        tap("onboarding.continue", in: app)
        tap("onboarding.continue", in: app)

        for option in ["predictable", "someVariation", "irregular", "unsure"] {
            revealAndTap("onboarding.regularity.\(option)", in: app)
            XCTAssertTrue(element("onboarding.regularity.\(option)", in: app).isSelected)
        }
        tap("onboarding.continue", in: app)

        for option in [
            "none", "hormonalContraception", "postpartum", "perimenopause",
            "fertilityTreatment", "preferNotToSay"
        ] {
            revealAndTap("onboarding.hormone.\(option)", in: app)
            XCTAssertTrue(element("onboarding.hormone.\(option)", in: app).isSelected)
        }
        tap("onboarding.continue", in: app)

        let symptoms = [
            "cramps", "headache", "bloating", "fatigue", "backPain",
            "tenderBreasts", "acne", "nausea", "cravings", "insomnia"
        ]
        for symptom in symptoms {
            revealAndTap("onboarding.symptom.\(symptom)", in: app)
            XCTAssertTrue(element("onboarding.symptom.\(symptom)", in: app).isSelected)
        }
        tap("onboarding.continue", in: app)

        tap("onboarding.reminderToggle", in: app)
        let reminderTime = element("onboarding.reminderTime", in: app)
        XCTAssertTrue(reminderTime.waitForExistence(timeout: existenceTimeout))
        reminderTime.tap()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.18)).tap()
        tap("onboarding.reminderToggle", in: app)
        XCTAssertFalse(reminderTime.waitForExistence(timeout: 2))
        tap("onboarding.continue", in: app)

        XCTAssertTrue(element("onboarding.summary", in: app).waitForExistence(timeout: existenceTimeout))
        tap("onboarding.back", in: app)
        XCTAssertTrue(element("onboarding.reminderToggle", in: app).waitForExistence(timeout: existenceTimeout))
        tap("onboarding.continue", in: app)
        tap("onboarding.finish", in: app)

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: existenceTimeout))
        XCTAssertTrue(element("home.personalFocus", in: app).waitForExistence(timeout: existenceTimeout))
    }

    func testEveryHomeCalendarAndTabButtonResponds() {
        let app = launch(arguments: ["-uiTestOnboarded"])

        tapEveryHomeWeekDay(in: app)

        tap("hero.log", in: app)
        XCTAssertTrue(app.navigationBars["Daily log"].waitForExistence(timeout: existenceTimeout))
        tap("log.cancel", in: app)

        revealAndTap("home.logToday", in: app)
        XCTAssertTrue(app.navigationBars["Daily log"].waitForExistence(timeout: existenceTimeout))
        tap("log.cancel", in: app)

        app.tabBars.buttons["Calendar"].tap()
        XCTAssertTrue(app.staticTexts["Your calendar"].waitForExistence(timeout: existenceTimeout))

        tap("calendar.previousMonth", in: app)
        tap("calendar.nextMonth", in: app)
        tap("calendar.today", in: app)

        tapEveryDayInCurrentMonth(in: app)

        revealAndTap("calendar.logSelected", in: app)
        XCTAssertTrue(app.navigationBars["Daily log"].waitForExistence(timeout: existenceTimeout))
        tap("log.cancel", in: app)

        app.tabBars.buttons["Insights"].tap()
        XCTAssertTrue(app.staticTexts["Your patterns"].waitForExistence(timeout: existenceTimeout))

        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Profile"].waitForExistence(timeout: existenceTimeout))

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(element("hero.log", in: app).waitForExistence(timeout: existenceTimeout))
    }

    func testEveryDailyLogButtonCanBeChangedAndSaved() {
        let app = launch(arguments: ["-uiTestOnboarded", "-uiTestShowLog"])

        XCTAssertTrue(app.navigationBars["Daily log"].waitForExistence(timeout: existenceTimeout))
        tap("log.periodToggle", in: app)

        for flow in ["light", "medium", "heavy"] {
            tap("log.flow.\(flow)", in: app)
            XCTAssertTrue(element("log.flow.\(flow)", in: app).isSelected)
        }

        for mood in ["low", "sensitive", "okay"] {
            revealAndTap("log.mood.\(mood)", in: app)
        }
        element("log.mood.okay", in: app).swipeLeft()
        for mood in ["calm", "good"] {
            revealAndTap("log.mood.\(mood)", in: app)
        }
        XCTAssertTrue(element("log.mood.good", in: app).isSelected)

        let symptoms = [
            "cramps", "headache", "bloating", "fatigue", "backPain",
            "tenderBreasts", "acne", "nausea", "cravings", "insomnia"
        ]
        for symptom in symptoms {
            revealAndTap("log.symptom.\(symptom)", in: app)
        }

        for level in 1...5 {
            revealAndTap("log.energy.\(level)", in: app)
        }
        XCTAssertTrue(element("log.energy.5", in: app).isSelected)

        let notes = element("log.notes", in: app)
        reveal(notes, in: app)
        notes.tap()
        notes.typeText(" Full interaction audit completed.")

        tap("log.save", in: app)
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: existenceTimeout))

        revealAndTap("home.logToday", in: app, swipeUp: true)
        XCTAssertTrue(app.navigationBars["Daily log"].waitForExistence(timeout: existenceTimeout))
        XCTAssertTrue(element("log.periodToggle", in: app).waitForExistence(timeout: existenceTimeout))
        tap("log.cancel", in: app)
    }

    func testEveryCyclePhaseCardOpensItsGuide() {
        let phases = ["menstruation", "follicular", "ovulation", "luteal"]

        for phase in phases {
            let app = launch(arguments: [
                "-uiTestOnboarded", "-uiTestTab", "insights", "-uiTestPhaseCard", phase
            ])
            let card = element("insights.phase.\(phase)", in: app)
            reveal(card, in: app, attempts: 16)

            XCTAssertTrue(card.isHittable, "Phase card could not be reached: \(phase)")
            card.tap()
            let detail = element("insights.phaseDetail.\(phase)", in: app)
            XCTAssertTrue(
                detail.waitForExistence(timeout: existenceTimeout),
                "Phase guide did not open: \(phase)"
            )
            tap("insights.phaseDetail.close", in: app)
            XCTAssertTrue(app.navigationBars["Phase guide"].waitForNonExistence(timeout: 10))
        }
    }

    func testEveryProfileEditorControlResponds() {
        let app = launch(arguments: ["-uiTestOnboarded", "-uiTestTab", "profile"])

        XCTAssertTrue(app.staticTexts["Profile"].waitForExistence(timeout: existenceTimeout))
        tap("profile.edit", in: app)
        XCTAssertTrue(app.navigationBars["Edit cycle profile"].waitForExistence(timeout: existenceTimeout))
        tap("profile.editor.cancel", in: app)
        XCTAssertTrue(app.navigationBars["Edit cycle profile"].waitForNonExistence(timeout: existenceTimeout))

        tap("profile.edit", in: app)

        for goal in ["predictPeriods", "understandSymptoms", "planAhead", "buildHistory"] {
            let control = element("profile.goal.\(goal)", in: app)
            reveal(control, in: app)
            let wasSelected = control.isSelected
            control.tap()
            XCTAssertEqual(control.isSelected, !wasSelected, "Goal did not change: \(goal)")
        }

        for option in ["predictable", "someVariation", "irregular", "unsure"] {
            let control = element("profile.regularity.\(option)", in: app)
            reveal(control, in: app)
            control.tap()
            XCTAssertTrue(control.isSelected, "Cycle pattern did not select: \(option)")
        }

        for option in [
            "none", "preferNotToSay", "hormonalContraception", "postpartum",
            "perimenopause", "fertilityTreatment"
        ] {
            let control = element("profile.hormone.\(option)", in: app)
            reveal(control, in: app)
            control.tap()
            XCTAssertTrue(control.isSelected, "Hormone context did not select: \(option)")
        }

        for symptom in [
            "cramps", "headache", "bloating", "fatigue", "backPain",
            "tenderBreasts", "acne", "nausea", "cravings", "insomnia"
        ] {
            let control = element("profile.symptom.\(symptom)", in: app)
            reveal(control, in: app)
            let wasSelected = control.isSelected
            control.tap()
            XCTAssertEqual(control.isSelected, !wasSelected, "Symptom did not change: \(symptom)")
        }

        tap("profile.editor.save", in: app)
        XCTAssertTrue(app.navigationBars["Edit cycle profile"].waitForNonExistence(timeout: existenceTimeout))
        XCTAssertEqual(element("profile.goalSummary", in: app).label, "Planning ahead + 1 more")
        XCTAssertEqual(element("profile.regularitySummary", in: app).label, "I’m not sure yet")
        XCTAssertEqual(element("profile.hormoneSummary", in: app).label, "Fertility treatment")
        XCTAssertEqual(element("profile.symptomSummary", in: app).label, "Cramps, Back pain + 5 more")
    }

    func testEveryProfileSettingsButtonAndSystemHandoffResponds() {
        let app = launch(arguments: ["-uiTestOnboarded", "-uiTestReminderEnabled", "-uiTestTab", "profile"])

        XCTAssertTrue(app.staticTexts["Profile"].waitForExistence(timeout: existenceTimeout))

        let cycleStepper = app.steppers["settings.cycleStepper"]
        XCTAssertTrue(cycleStepper.waitForExistence(timeout: existenceTimeout))
        reveal(cycleStepper, in: app)
        tap("settings.cycleStepper-Increment", in: app)
        XCTAssertTrue(app.staticTexts["29d"].waitForExistence(timeout: existenceTimeout))
        tap("settings.cycleStepper-Decrement", in: app)
        XCTAssertTrue(app.staticTexts["28d"].waitForExistence(timeout: existenceTimeout))

        let periodStepper = app.steppers["settings.periodStepper"]
        XCTAssertTrue(periodStepper.waitForExistence(timeout: existenceTimeout))
        reveal(periodStepper, in: app)
        tap("settings.periodStepper-Increment", in: app)
        XCTAssertTrue(app.staticTexts["6d"].waitForExistence(timeout: existenceTimeout))
        tap("settings.periodStepper-Decrement", in: app)
        XCTAssertTrue(app.staticTexts["5d"].waitForExistence(timeout: existenceTimeout))

        let reminderTime = element("settings.reminderTime", in: app)
        reveal(reminderTime, in: app)
        reminderTime.tap()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.18)).tap()
        tap("settings.reminderToggle", in: app)

        revealAndTap("settings.visitSTO", in: app)
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 10))
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: existenceTimeout))

        revealAndTap("settings.export", in: app)
        dismissShareSheet(in: app)

        revealAndTap("settings.delete", in: app)
        let cancelAlert = app.alerts["Delete all cycle data?"]
        XCTAssertTrue(cancelAlert.waitForExistence(timeout: existenceTimeout))
        cancelAlert.buttons["Cancel"].tap()

        revealAndTap("settings.delete", in: app)
        let confirmAlert = app.alerts["Delete all cycle data?"]
        XCTAssertTrue(confirmAlert.waitForExistence(timeout: existenceTimeout))
        confirmAlert.buttons["Delete all data"].tap()

        XCTAssertTrue(app.staticTexts["YOUR CYCLE,\nMADE PERSONAL"].waitForExistence(timeout: existenceTimeout))
    }

    func testReminderPermissionButtonSchedulesAndCancels() {
        let app = launch(arguments: ["-uiTestOnboarded", "-uiTestTab", "profile"])

        addUIInterruptionMonitor(withDescription: "Notification permission") { alert in
            if alert.buttons["Allow"].exists {
                alert.buttons["Allow"].tap()
                return true
            }
            return false
        }

        tap("settings.reminderToggle", in: app)
        app.tap()

        let reminderTime = element("settings.reminderTime", in: app)
        XCTAssertTrue(reminderTime.waitForExistence(timeout: 8), "Enabling reminders should reveal the time control")
        tap("settings.reminderToggle", in: app)
        XCTAssertFalse(reminderTime.waitForExistence(timeout: 2))
    }

    func testReminderDenialAlertCanBeDismissed() {
        let app = launch(arguments: [
            "-uiTestOnboarded", "-uiTestTab", "profile", "-uiTestDenyReminder"
        ])

        tap("settings.reminderToggle", in: app)

        let alert = app.alerts["Reminders are off"]
        XCTAssertTrue(alert.waitForExistence(timeout: existenceTimeout))
        let okay = alert.buttons["OK"]
        XCTAssertTrue(okay.isHittable)
        okay.tap()

        XCTAssertFalse(alert.waitForExistence(timeout: 2))
        XCTAssertFalse(element("settings.reminderTime", in: app).exists)
    }

    func testDailyLogCanMarkPeriodAndSave() {
        let app = launch(arguments: ["-uiTestOnboarded", "-uiTestShowLog"])

        XCTAssertTrue(app.navigationBars["Daily log"].waitForExistence(timeout: existenceTimeout))
        tap("log.periodToggle", in: app)
        tap("log.save", in: app)

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: existenceTimeout))
        XCTAssertTrue(element("hero.log", in: app).waitForExistence(timeout: existenceTimeout))
    }

    private func launch(arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func tap(_ identifier: String, in app: XCUIApplication) {
        let matches = app.descendants(matching: .any).matching(identifier: identifier)
        XCTAssertTrue(matches.firstMatch.waitForExistence(timeout: existenceTimeout), "Missing control: \(identifier)")

        let deadline = Date().addingTimeInterval(existenceTimeout)
        repeat {
            if let target = matches.allElementsBoundByIndex.first(where: \.isHittable) {
                target.tap()
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline

        XCTFail("Control is not hittable: \(identifier)")
    }

    private func revealAndTap(
        _ identifier: String,
        in app: XCUIApplication,
        swipeUp: Bool = true
    ) {
        let target = element(identifier, in: app)
        reveal(target, in: app, swipeUp: swipeUp)
        target.tap()
    }

    private func reveal(
        _ target: XCUIElement,
        in app: XCUIApplication,
        swipeUp: Bool = true,
        attempts: Int = 10
    ) {
        for _ in 0..<attempts {
            if target.exists, target.isHittable { return }
            swipeUp ? app.swipeUp() : app.swipeDown()
        }
        XCTAssertTrue(target.exists, "Control did not enter the accessibility tree: \(target)")
        XCTAssertTrue(target.isHittable, "Control could not be scrolled into view: \(target)")
    }

    private func tapEveryDayInCurrentMonth(in app: XCUIApplication) {
        let calendar = Calendar.autoupdatingCurrent
        let today = Date()
        guard let range = calendar.range(of: .day, in: .month, for: today) else {
            XCTFail("Could not calculate current month")
            return
        }

        let baseComponents = calendar.dateComponents([.year, .month], from: today)
        for day in range {
            var components = baseComponents
            components.day = day
            guard let date = calendar.date(from: components) else {
                XCTFail("Could not construct day \(day)")
                return
            }
            let identifier = "calendar.day.\(dateKey(date, calendar: calendar))"
            revealAndTap(identifier, in: app)
            XCTAssertTrue(element(identifier, in: app).isSelected, "Calendar day did not select: \(identifier)")
        }
    }

    private func tapEveryHomeWeekDay(in app: XCUIApplication) {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: Date())

        for offset in -3...3 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else {
                XCTFail("Could not construct week-strip date at offset \(offset)")
                return
            }

            tap("home.weekDay.\(dateKey(date, calendar: calendar))", in: app)
            XCTAssertTrue(app.navigationBars["Daily log"].waitForExistence(timeout: existenceTimeout))
            tap("log.cancel", in: app)
        }
    }

    private func dateKey(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d%02d%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private func dismissShareSheet(in app: XCUIApplication) {
        let popoverDismissRegion = element("PopoverDismissRegion", in: app)
        if popoverDismissRegion.waitForExistence(timeout: existenceTimeout) {
            popoverDismissRegion.tap()
            return
        }

        let close = app.buttons["Close"]
        if close.waitForExistence(timeout: existenceTimeout) {
            close.tap()
            return
        }

        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: existenceTimeout), "Share sheet did not provide a dismiss button")
        cancel.tap()
    }
}
