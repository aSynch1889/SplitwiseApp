import SwiftUI
import SwiftData

@main
public struct SplitwiseApp: App {
    @State private var appState = AppState()
    @State private var loc = LocalizationManager.shared
    @State private var cloudSync = CloudSyncMonitor.shared
    @State private var isShowingLaunchScreen: Bool = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("persistence_recovery_notice") private var persistenceRecoveryNotice: Bool = false

    public var sharedModelContainer: ModelContainer

    public init() {
        // Force the Bundle language swizzle to install before any Text renders.
        _ = LocalizationManager.shared
        let result = Self.makeModelContainer()
        self.sharedModelContainer = result.container
        CloudSyncMonitor.shared.isCloudKitStoreActive = result.usedCloudKit
        if result.usedFallback {
            UserDefaults.standard.set(true, forKey: "persistence_recovery_notice")
        }
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
            .environment(cloudSync)
            .environment(\.locale, loc.locale)
            .alert("Local Data Reset", isPresented: $persistenceRecoveryNotice) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The on-device database could not be opened, so BillNest started with a fresh local store. Use Account → Restore Backup if you have a JSON backup.")
            }
            .onAppear {
                cloudSync.startMonitoring()
                // Brief branded splash only — keep under PRD 1.0s perceived launch.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isShowingLaunchScreen = false
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private static func makeModelContainer() -> (container: ModelContainer, usedFallback: Bool, usedCloudKit: Bool) {
        let schema = Schema([
            User.self,
            Group.self,
            Expense.self,
            Settlement.self,
            ActivityLog.self
        ])

        let iCloudEnabled = UserDefaults.standard.object(forKey: CloudSyncMonitor.iCloudEnabledKey) as? Bool ?? true

        if iCloudEnabled {
            let cloudConfig = ModelConfiguration(
                "BillNestCloud",
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(CloudSyncMonitor.iCloudContainerID)
            )
            do {
                let container = try ModelContainer(for: schema, configurations: [cloudConfig])
                return (container, false, true)
            } catch {
                print("CloudKit ModelContainer failed: \(error). Falling back to local store.")
            }
        }

        let diskConfig = ModelConfiguration(
            "BillNestLocal",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return (try ModelContainer(for: schema, configurations: [diskConfig]), false, false)
        } catch {
            print("ModelContainer open failed: \(error). Attempting store reset…")
        }

        // Recovery: delete the default store files, then retry on disk.
        let storeURL = diskConfig.url
        let fm = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            let url = URL(fileURLWithPath: storeURL.path + suffix)
            try? fm.removeItem(at: url)
        }
        do {
            return (try ModelContainer(for: schema, configurations: [diskConfig]), true, false)
        } catch {
            print("ModelContainer recreate after wipe failed: \(error). Falling back to memory.")
        }

        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return (try ModelContainer(for: schema, configurations: [memoryConfig]), true, false)
        } catch {
            fatalError("Could not create ModelContainer even in memory: \(error)")
        }
    }
}
