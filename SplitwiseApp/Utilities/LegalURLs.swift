import Foundation

/// Public legal document URLs hosted on GitHub Pages (BillNest-Legal).
public enum LegalURLs {
    public static let siteRoot = URL(string: "https://asynch1889.github.io/BillNest-Legal/")!

    public static func privacyPolicy(languageCode: String = LocalizationManager.shared.currentLanguage) -> URL {
        if languageCode.hasPrefix("zh") {
            return URL(string: "https://asynch1889.github.io/BillNest-Legal/privacy-zh.html")!
        }
        return URL(string: "https://asynch1889.github.io/BillNest-Legal/privacy.html")!
    }

    public static func termsOfService(languageCode: String = LocalizationManager.shared.currentLanguage) -> URL {
        if languageCode.hasPrefix("zh") {
            return URL(string: "https://asynch1889.github.io/BillNest-Legal/terms-zh.html")!
        }
        return URL(string: "https://asynch1889.github.io/BillNest-Legal/terms.html")!
    }
}
