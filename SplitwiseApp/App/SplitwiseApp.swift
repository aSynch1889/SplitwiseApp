import SwiftUI
import SwiftData

@main
public struct SplitwiseApp: App {
    @State private var appState = AppState()

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

    public init() {}

    public var body: some Scene {
        WindowGroup {
            MainView()
                .environment(appState)
                .preferredColorScheme(appState.preferredColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
