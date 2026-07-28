import SwiftUI
import SwiftData

@main
public struct SplitwiseApp: App {
    @State private var appState = AppState()
    @State private var loc = LocalizationManager.shared
    @State private var isShowingLaunchScreen: Bool = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    public var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Group.self,
            Expense.self,
            Settlement.self,
            ActivityLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    public init() {
        // Force the Bundle language swizzle to install before any Text renders.
        _ = LocalizationManager.shared
    }

    public var body: some Scene {
        WindowGroup {
            ZStack {
                if isShowingLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                } else if !hasCompletedOnboarding {
                    OnboardingView()
                        .transition(.opacity)
                } else {
                    MainView()
                        .id(loc.currentLanguage)
                        .preferredColorScheme(appState.preferredColorScheme)
                        .transition(.opacity)
                }
            }
            .environment(loc)
            .environment(appState)
            .environment(\.locale, loc.locale)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isShowingLaunchScreen = false
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
