import Foundation
import SwiftUI

/// Paid capabilities that must be gated behind an active Pro entitlement (or DEBUG mock).
public enum ProFeature: String, CaseIterable, Identifiable {
    case receiptOCR
    case exportReports
    case advancedCharts
    case debtSimplification
    case itemizedSplit

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .receiptOCR: return "Receipt OCR"
        case .exportReports: return "PDF & CSV Export"
        case .advancedCharts: return "Advanced Charts"
        case .debtSimplification: return "Debt Simplification"
        case .itemizedSplit: return "Itemized Splits"
        }
    }

    public var subtitle: String {
        switch self {
        case .receiptOCR: return "Scan receipts with on-device Vision OCR."
        case .exportReports: return "Export group statements as PDF or CSV."
        case .advancedCharts: return "View category, trend, and group analytics."
        case .debtSimplification: return "Reduce transfers with simplified balances."
        case .itemizedSplit: return "Assign receipt line items to members."
        }
    }
}

@Observable
public final class PaywallPresenter {
    public static let shared = PaywallPresenter()
    public var isPresented: Bool = false
    public var lockedFeature: ProFeature?

    private init() {}

    @MainActor
    public func present(for feature: ProFeature? = nil) {
        lockedFeature = feature
        isPresented = true
    }
}

public enum ProAccess {
    public static var isPro: Bool {
        ProSubscriptionManager.shared.isPro
    }

    /// Runs `action` when Pro is active; otherwise presents the paywall.
    @MainActor
    public static func require(_ feature: ProFeature, perform action: () -> Void) {
        if isPro {
            action()
        } else {
            PaywallPresenter.shared.present(for: feature)
        }
    }
}

public struct ProBadge: View {
    public init() {}

    public var body: some View {
        Text("PRO")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}
