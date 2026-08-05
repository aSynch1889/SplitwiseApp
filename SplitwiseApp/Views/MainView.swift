import SwiftUI
import SwiftData

public struct MainView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var selectedSidebarItem: SidebarItem? = .groups
    @State private var showingGlobalAddExpense = false

    // Persisted across the language-switch rebuild so the user stays on their tab.
    private var selectedTabBinding: Binding<TabItem> {
        Binding(
            get: { TabItem(rawValue: appState.selectedTabRaw) ?? .groups },
            set: { appState.selectedTabRaw = $0.rawValue }
        )
    }

    public enum TabItem: Int, CaseIterable, Identifiable {
        case groups = 0
        case friends = 1
        case activity = 2
        case analytics = 3
        case account = 4

        public var id: Int { rawValue }

        public var title: String {
            switch self {
            case .groups: return "Groups"
            case .friends: return "Friends"
            case .activity: return "Activity"
            case .analytics: return "Analytics"
            case .account: return "Account"
            }
        }

        public var iconName: String {
            switch self {
            case .groups: return "person.3.fill"
            case .friends: return "person.2.fill"
            case .activity: return "bell.fill"
            case .analytics: return "chart.bar.xaxis"
            case .account: return "person.crop.circle.fill"
            }
        }
    }

    public enum SidebarItem: String, CaseIterable, Identifiable {
        case groups = "Groups"
        case friends = "Friends"
        case activity = "Activity"
        case analytics = "Analytics"
        case account = "Account"

        public var id: String { rawValue }

        public var iconName: String {
            switch self {
            case .groups: return "person.3.fill"
            case .friends: return "person.2.fill"
            case .activity: return "bell.fill"
            case .analytics: return "chart.bar.xaxis"
            case .account: return "person.crop.circle.fill"
            }
        }
    }

    public var body: some View {
        SwiftUI.Group {
            if horizontalSizeClass == .regular {
                // iPad Adaptive NavigationSplitView
                NavigationSplitView {
                    List(selection: $selectedSidebarItem) {
                        Section("Splitwise") {
                            ForEach(SidebarItem.allCases) { item in
                                NavigationLink(value: item) {
                                    Label(LocalizedStringKey(item.rawValue), systemImage: item.iconName)
                                }
                            }
                        }

                        Section {
                            Button {
                                showingGlobalAddExpense = true
                            } label: {
                                Label("Add Expense", systemImage: "plus.circle.fill")
                                    .fontWeight(.semibold)
                                    .foregroundColor(ColorTheme.brandTeal)
                            }
                        }
                    }
                    .listStyle(.sidebar)
                    .navigationTitle("Splitwise")
                } detail: {
                    switch selectedSidebarItem ?? .groups {
                    case .groups:
                        GroupListView()
                    case .friends:
                        FriendsListView()
                    case .activity:
                        ActivityFeedView()
                    case .analytics:
                        ChartsView()
                    case .account:
                        AccountView()
                    }
                }
            } else {
                // iPhone Adaptive TabView
                TabView(selection: selectedTabBinding) {
                    GroupListView()
                        .tabItem {
                            Label(LocalizedStringKey(TabItem.groups.title), systemImage: TabItem.groups.iconName)
                        }
                        .tag(TabItem.groups)

                    FriendsListView()
                        .tabItem {
                            Label(LocalizedStringKey(TabItem.friends.title), systemImage: TabItem.friends.iconName)
                        }
                        .tag(TabItem.friends)

                    ActivityFeedView()
                        .tabItem {
                            Label(LocalizedStringKey(TabItem.activity.title), systemImage: TabItem.activity.iconName)
                        }
                        .tag(TabItem.activity)

                    ChartsView()
                        .tabItem {
                            Label(LocalizedStringKey(TabItem.analytics.title), systemImage: TabItem.analytics.iconName)
                        }
                        .tag(TabItem.analytics)

                    AccountView()
                        .tabItem {
                            Label(LocalizedStringKey(TabItem.account.title), systemImage: TabItem.account.iconName)
                        }
                        .tag(TabItem.account)
                }
                .tint(ColorTheme.brandTeal)
            }
        }
        .onAppear {
            SampleData.populateIfEmpty(context: modelContext)
            appState.resolveCurrentUser(from: modelContext)
        }
        .sheet(isPresented: $showingGlobalAddExpense) {
            AddExpenseView()
        }
    }
}
