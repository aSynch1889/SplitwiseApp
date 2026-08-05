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

    /// Resolve `currentUserId` from SwiftData (`User.isCurrentUser`) so balances and "You" labels stay correct across launches / iCloud merges.
    @MainActor
    public func resolveCurrentUser(from context: ModelContext) {
        let allUsers = (try? context.fetch(FetchDescriptor<User>())) ?? []
        guard !allUsers.isEmpty else { return }

        // Prefer the locally persisted ID after CloudKit merges multiple device profiles.
        if let matched = allUsers.first(where: { $0.id == currentUserId }) {
            var changed = false
            for user in allUsers {
                let shouldBeCurrent = user.id == matched.id
                if user.isCurrentUser != shouldBeCurrent {
                    user.isCurrentUser = shouldBeCurrent
                    changed = true
                }
            }
            if changed {
                do { try context.save() } catch {
                    print("AppState: failed to normalize current user — \(error.localizedDescription)")
                }
            }
            return
        }

        let flagged = allUsers.filter(\.isCurrentUser)
        if let me = flagged.sorted(by: { $0.createdAt < $1.createdAt }).first {
            currentUserId = me.id
            if flagged.count > 1 {
                for user in allUsers where user.id != me.id && user.isCurrentUser {
                    user.isCurrentUser = false
                }
                do { try context.save() } catch {
                    print("AppState: failed to demote extra current users — \(error.localizedDescription)")
                }
            }
            return
        }

        if let first = allUsers.sorted(by: { $0.createdAt < $1.createdAt }).first {
            first.isCurrentUser = true
            currentUserId = first.id
            do { try context.save() } catch {
                print("AppState: failed to mark current user — \(error.localizedDescription)")
            }
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
