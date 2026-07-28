import SwiftUI

@Observable
public final class AppState {
    public var currentUserId: UUID
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

    public init(currentUserId: UUID = UUID()) {
        self.currentUserId = currentUserId
        self.selectedCurrency = UserDefaults.standard.string(forKey: "app_selected_currency") ?? "USD"
        self.colorSchemePreference = UserDefaults.standard.string(forKey: "app_color_scheme") ?? "system"
        self.selectedTabRaw = (UserDefaults.standard.object(forKey: "app_selected_tab") as? Int) ?? 0
    }

    public var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
