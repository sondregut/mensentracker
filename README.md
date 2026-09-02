# STÖ Cycle

A private, local-first period tracker MVP for iPhone, built with SwiftUI. There is no account, authentication, backend, analytics SDK, or cloud sync.

## MVP features

- Nine-screen, value-first onboarding for goals, cycle timing, regularity, optional health context, symptom shortcuts, and reminders
- Personalized Today view with cycle phase, cycle day, next-period estimate, and a goal-aware daily focus
- Monthly calendar for logged periods, predicted periods, fertile window, and estimated ovulation
- Daily logging for bleeding and flow, symptoms, mood, energy, and notes
- Insights for cycle history, averages, commonly logged symptoms, and saved tracking priorities
- Optional on-device notification reminder
- Local JSON export and complete data deletion
- Accessibility labels, Dynamic Type-aware typography, and reduced-motion support
- End-to-end UI tests that tap every app control, including system handoffs and both reminder-permission outcomes

Cycle predictions are estimates only. The app is not contraception, does not confirm pregnancy or ovulation, and is not medical advice.

## Run

Open `STOCycle.xcodeproj` in Xcode 26 or later and run the `STOCycle` scheme on an iPhone simulator running iOS 17 or later.

The project is generated from `project.yml` with XcodeGen:

```sh
xcodegen generate
```

Run all tests from Xcode, or with:

```sh
xcodebuild test \
  -project STOCycle.xcodeproj \
  -scheme STOCycle \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
