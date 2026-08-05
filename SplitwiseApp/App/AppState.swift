import SwiftUI
import SwiftData

@Observable
public final class AppState {
    private static let currentUserIdKey = "app_current_user_id"

    public var currentUserId: UUID {
        didSet {
            UserDefaults.standard.set(currentUserId.uuidString, forKey: Self.currentUserIdKey)
        }
    }
    public var selectedCurrency: String {
        didSet {
            UserDefaults.standard.set(selectedCurrency, forKey: "app_selected_currency")
        }
    }
    public var colorSchemePreference: String { // "system", "light", "dark"
        didSet {
            UserDefaults.standard.set(colorSchemePreference, forKey: "app_color_scheme")
        }
    }
    /// Active main tab, persisted so it survives the language-switch view rebuild.
    public var selectedTabRaw: Int {
        didSet {
            UserDefaults.standard.set(selectedTabRaw, forKey: "app_selected_tab")
        }
    }

    public init(currentUserId: UUID? = nil) {
        let resolvedId: UUID
        if let currentUserId {
            resolvedId = currentUserId
        } else if let stored = UserDefaults.standard.string(forKey: Self.currentUserIdKey),
                  let uuid = UUID(uuidString: stored) {
            resolvedId = uuid
        } else {
            resolvedId = UUID()
        }
        self.currentUserId = resolvedId
        // didSet does not run during init — persist explicitly.
        UserDefaults.standard.set(resolvedId.uuidString, forKey: Self.currentUserIdKey)
        self.selectedCurrency = UserDefaults.standard.string(forKey: "app_selected_currency") ?? "USD"
        self.colorSchemePreference = UserDefaults.standard.string(forKey: "app_color_scheme") ?? "system"
        self.selectedTabRaw = (UserDefaults.standard.object(forKey: "app_selected_tab") as? Int) ?? 0
    }

    /// Resolve `currentUserId` from SwiftData (`User.isCurrentUser`) so balances and "You" labels stay correct across launches.
    @MainActor
    public func resolveCurrentUser(from context: ModelContext) {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.isCurrentUser }
        )
        if let me = try? context.fetch(descriptor).first {
            if currentUserId != me.id {
                currentUserId = me.id
            }
            return
        }

        // Fallback: if a persisted ID still matches a user, adopt it and mark as current.
        let allUsers = (try? context.fetch(FetchDescriptor<User>())) ?? []
        if let matched = allUsers.first(where: { $0.id == currentUserId }) {
            matched.isCurrentUser = true
            do {
                try context.save()
            } catch {
                print("AppState: failed to mark current user — \(error.localizedDescription)")
            }
            return
        }
    }

    public var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
