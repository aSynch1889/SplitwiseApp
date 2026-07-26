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
    public var selectedLanguage: String { // "en", "zh-Hans", "zh-Hant"
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "app_selected_language")
        }
    }

    public init(currentUserId: UUID = UUID()) {
        self.currentUserId = currentUserId
        self.selectedCurrency = UserDefaults.standard.string(forKey: "app_selected_currency") ?? "USD"
        self.colorSchemePreference = UserDefaults.standard.string(forKey: "app_color_scheme") ?? "system"
        self.selectedLanguage = UserDefaults.standard.string(forKey: "app_selected_language") ?? "zh-Hans"
    }

    public var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
