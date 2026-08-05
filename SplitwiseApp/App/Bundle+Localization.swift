import Foundation

/// Enables live, no-restart language switching by redirecting `Bundle.main`'s
/// string lookups to the user-selected language's `.lproj`.
///
/// A String Catalog compiles to per-language `<lang>.lproj/Localizable.strings`
/// at build time. SwiftUI resolves `LocalizedStringKey` through
/// `Bundle.main.localizedString(forKey:value:table:)`, governed by the system
/// locale list — which an app cannot change at runtime. Swizzling that public
/// method lets us redirect lookup in-process without restarting the app.
extension Bundle {

    /// Install the swizzle exactly once. Thread-safe via Swift's lazy static `let`.
    static func applyLanguageSwizzle() {
        _ = swizzleOnce
    }

    private static let swizzleOnce: Void = {
        let originalSelector = #selector(Bundle.localizedString(forKey: value: table:))
        let swizzledSelector = #selector(Bundle.ln_localizedString(forKey: value: table:))

        guard
            let original = class_getInstanceMethod(Bundle.self, originalSelector),
            let swizzled = class_getInstanceMethod(Bundle.self, swizzledSelector)
        else { return }

        method_exchangeImplementations(original, swizzled)
    }()

    /// Swizzled in for `localizedString(forKey:value:table:)`.
    ///
    /// Because the implementations are exchanged, calling `ln_localizedString`
    /// here actually invokes the *original* implementation on the receiver —
    /// this is what lets us delegate to a language sub-bundle without recursing.
    @objc func ln_localizedString(forKey key: String, value: String?, table: String?) -> String {
        let language = LocalizationManager.shared.currentLanguage

        // Redirect only lookups on the main bundle to the selected language's lproj.
        // Sub-bundles (self !== .main) fall straight through to the original impl,
        // which avoids infinite recursion.
        if self === Bundle.main,
           let lprojPath = Bundle.main.path(forResource: language, ofType: "lproj"),
           let lprojBundle = Bundle(path: lprojPath) {
            return lprojBundle.ln_localizedString(forKey: key, value: value, table: table)
        }

        return self.ln_localizedString(forKey: key, value: value, table: table)
    }
}
