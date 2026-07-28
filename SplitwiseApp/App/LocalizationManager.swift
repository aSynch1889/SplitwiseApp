import Foundation
import SwiftUI

/// A language the app supports for in-app switching.
public struct AppLanguage: Identifiable, Hashable {
    public let code: String        // e.g. "en", "zh-Hans"
    public let nativeName: String  // shown in the language picker
    public var id: String { code }
}

/// Single source of truth for the app's runtime language.
///
/// iOS resolves `Text("…")` (and other `LocalizedStringKey`-based views) from
/// `Bundle.main` using the *system* locale, which an app cannot change at runtime.
/// To switch language **without restarting**, `Bundle+Localization.swift` swizzles
/// `Bundle.localizedString(forKey:value:table:)` and reads the target language from
/// this manager. SwiftUI re-resolves every string because the root view is rebuilt
/// via `.id(currentLanguage)` (see `SplitwiseApp`).
@Observable
public final class LocalizationManager {
    public static let shared = LocalizationManager()

    /// Languages offered in Account → Language, in display order.
    public static let supported: [AppLanguage] = [
        AppLanguage(code: "en",      nativeName: "English"),
        AppLanguage(code: "zh-Hans", nativeName: "简体中文"),
        AppLanguage(code: "zh-Hant", nativeName: "繁體中文"),
        AppLanguage(code: "ja",      nativeName: "日本語"),
        AppLanguage(code: "ko",      nativeName: "한국어"),
    ]

    private static let storageKey = "app_selected_language"

    public private(set) var currentLanguage: String

    /// Locale matching the selected language, for `.environment(\.locale)`.
    public var locale: Locale { Locale(identifier: currentLanguage) }

    /// Native name of the currently selected language (for the Account row).
    public var currentNativeName: String {
        Self.supported.first { $0.code == currentLanguage }?.nativeName ?? currentLanguage
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        if let stored, Self.supported.contains(where: { $0.code == stored }) {
            currentLanguage = stored
        } else {
            currentLanguage = "en" // English is the app default
        }
        // Install the Bundle swizzle exactly once, before any Text renders.
        Bundle.applyLanguageSwizzle()
    }

    /// Switch the app language live (no restart required).
    public func setLanguage(_ code: String) {
        guard code != currentLanguage,
              Self.supported.contains(where: { $0.code == code }) else { return }
        currentLanguage = code
        UserDefaults.standard.set(code, forKey: Self.storageKey)
        // The Bundle swizzle reads `currentLanguage` directly; the SwiftUI tree
        // rebuild is triggered by `.id(currentLanguage)` on the root view.
    }
}
