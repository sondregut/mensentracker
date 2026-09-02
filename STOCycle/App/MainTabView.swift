import SwiftUI

enum AppTab: String, CaseIterable {
    case today
    case calendar
    case insights
    case profile

    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .today: "circle.circle.fill"
        case .calendar: "calendar"
        case .insights: "chart.xyaxis.line"
        case .profile: "person.crop.circle.fill"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: CycleStore
    @State private var selection: AppTab
    @State private var showingLaunchLog: Bool

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        let requested = arguments
            .drop(while: { $0 != "-uiTestTab" })
            .dropFirst()
            .first
            .flatMap(AppTab.init(rawValue:))
        _selection = State(initialValue: requested ?? .today)
        _showingLaunchLog = State(initialValue: arguments.contains("-uiTestShowLog"))
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tag(AppTab.today)
                .tabItem { Label(AppTab.today.title, systemImage: AppTab.today.symbol) }

            CycleCalendarView()
                .tag(AppTab.calendar)
                .tabItem { Label(AppTab.calendar.title, systemImage: AppTab.calendar.symbol) }

            InsightsView()
                .tag(AppTab.insights)
                .tabItem { Label(AppTab.insights.title, systemImage: AppTab.insights.symbol) }

            ProfileView()
                .tag(AppTab.profile)
                .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.symbol) }
        }
        .tint(STOTheme.rose)
        .toolbarBackground(STOTheme.cream.opacity(0.96), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(isPresented: $showingLaunchLog) {
            DailyLogView(date: Date())
                .environmentObject(store)
        }
    }
}
