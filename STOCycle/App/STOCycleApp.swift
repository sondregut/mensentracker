import SwiftUI

@main
struct STOCycleApp: App {
    @StateObject private var store = CycleStore()

    var body: some Scene {
        WindowGroup {
            AppContainerView()
                .environmentObject(store)
                .preferredColorScheme(.light)
                .tint(STOTheme.rose)
        }
    }
}
