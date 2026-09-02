import SwiftUI

struct AppContainerView: View {
    @EnvironmentObject private var store: CycleStore

    var body: some View {
        ZStack {
            STOPageBackground()

            if store.hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: store.hasCompletedOnboarding)
    }
}
