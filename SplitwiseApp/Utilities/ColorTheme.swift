import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum ColorTheme {
    public static let brandTeal = Color(red: 28/255, green: 194/255, blue: 159/255)
    public static let brandTealDark = Color(red: 20/255, green: 150/255, blue: 122/255)
    public static let owedGreen = Color(red: 46/255, green: 196/255, blue: 182/255)
    public static let owesOrange = Color(red: 255/255, green: 107/255, blue: 107/255)

    #if canImport(UIKit)
    public static let cardBackground = Color(uiColor: UIColor.secondarySystemGroupedBackground)
    public static let viewBackground = Color(uiColor: UIColor.systemGroupedBackground)
    #else
    public static let cardBackground = Color.gray.opacity(0.1)
    public static let viewBackground = Color.black.opacity(0.05)
    #endif

    public static func balanceColor(for amount: Double) -> Color {
        if amount > 0.001 {
            return owedGreen
        } else if amount < -0.001 {
            return owesOrange
        } else {
            return .secondary
        }
    }
}
