import SwiftUI
import StoreKit

public struct SplitwiseProView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc
    @Bindable var proManager = ProSubscriptionManager.shared

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Banner
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }

                        Text("Splitwise Pro")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Text("Unlock high-power features to manage shared expenses like a pro.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 10)

                    // Pro Features List
                    VStack(alignment: .leading, spacing: 16) {
                        proFeatureRow(icon: "doc.text.viewfinder", title: "OCR Receipt Scanning", desc: "Scan receipts automatically with Vision AI and convert items to split expenses.")
                        proFeatureRow(icon: "dollarsign.arrow.circlepath", title: "Multi-Currency Conversion", desc: "Convert amounts across 10+ currencies using in-app rates.")
                        proFeatureRow(icon: "doc.badge.plus", title: "PDF & CSV Statements", desc: "Export high-quality PDF reports for taxes, business trips, and roommates.")
                        proFeatureRow(icon: "chart.pie.fill", title: "Advanced Analytics Charts", desc: "Detailed monthly spending trends and category insights with Swift Charts.")
                        proFeatureRow(icon: "arrow.triangle.merge", title: "Debt Simplification", desc: "Reduce transfers for your groups using balance netting.")
                        proFeatureRow(icon: "nosign", title: "Ad-Free Experience", desc: "Enjoy clean, distraction-free expense tracking.")
                    }
                    .padding()
                    .background(ColorTheme.cardBackground)
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Subscription Plans Cards
                    VStack(spacing: 14) {
                        planCard(
                            title: "Pro Monthly",
                            price: displayPrice(
                                for: ProSubscriptionManager.monthlyProID,
                                fallback: "$2.99 / month"
                            ),
                            badge: introductoryBadge(for: ProSubscriptionManager.monthlyProID) ?? "Auto-Renewable",
                            isPopular: false
                        ) {
                            purchasePlan(productID: ProSubscriptionManager.monthlyProID)
                        }

                        planCard(
                            title: "Pro Annual",
                            price: displayPrice(
                                for: ProSubscriptionManager.yearlyProID,
                                fallback: "$29.99 / year"
                            ),
                            badge: introductoryBadge(for: ProSubscriptionManager.yearlyProID) ?? "Best Value",
                            isPopular: true
                        ) {
                            purchasePlan(productID: ProSubscriptionManager.yearlyProID)
                        }
                    }
                    .padding(.horizontal)

                    // Restore & legal
                    VStack(spacing: 12) {
                        Button("Restore Purchases") {
                            Task {
                                await proManager.restorePurchases()
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.brandTeal)

                        if let errorMessage = proManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        #if DEBUG
                        Toggle("Simulator Mock Pro Mode", isOn: $proManager.isMockPro)
                            .tint(ColorTheme.brandTeal)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(ColorTheme.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        #endif

                        Text("Subscription automatically renews unless cancelled in Apple ID Settings at least 24 hours before the end of the current period. Payment is charged to your Apple ID.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: LegalURLs.privacyPolicy(languageCode: loc.currentLanguage))
                            Text("·")
                                .foregroundColor(.secondary)
                            Link("Terms of Service", destination: LegalURLs.termsOfService(languageCode: loc.currentLanguage))
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.brandTeal)
                        .padding(.top, 2)
                    }
                    .padding(.bottom, 30)
                }
            }
            .background(ColorTheme.viewBackground)
            .navigationTitle("Splitwise Pro")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.brandTeal)
                }
            }
            .task {
                if proManager.products.isEmpty {
                    await proManager.fetchProducts()
                }
            }
        }
    }

    private func product(for id: String) -> Product? {
        proManager.products.first(where: { $0.id == id })
    }

    private func displayPrice(for productID: String, fallback: String) -> String {
        guard let product = product(for: productID) else { return fallback }
        if let subscription = product.subscription {
            let period = subscription.subscriptionPeriod
            let unitLabel: String
            switch period.unit {
            case .day: unitLabel = period.value == 1 ? "day" : "\(period.value) days"
            case .week: unitLabel = period.value == 1 ? "week" : "\(period.value) weeks"
            case .month: unitLabel = period.value == 1 ? "month" : "\(period.value) months"
            case .year: unitLabel = period.value == 1 ? "year" : "\(period.value) years"
            @unknown default: unitLabel = "period"
            }
            return "\(product.displayPrice) / \(unitLabel)"
        }
        return product.displayPrice
    }

    private func introductoryBadge(for productID: String) -> String? {
        guard let offer = product(for: productID)?.subscription?.introductoryOffer else { return nil }
        switch offer.paymentMode {
        case .freeTrial:
            let period = offer.period
            let unit: String
            switch period.unit {
            case .day: unit = period.value == 1 ? "Day" : "\(period.value)-Day"
            case .week: unit = period.value == 1 ? "Week" : "\(period.value)-Week"
            case .month: unit = period.value == 1 ? "Month" : "\(period.value)-Month"
            case .year: unit = period.value == 1 ? "Year" : "\(period.value)-Year"
            @unknown default: unit = "Trial"
            }
            return "\(unit) Free Trial"
        case .payAsYouGo, .payUpFront:
            return "Intro Offer"
        default:
            return "Intro Offer"
        }
    }

    private func proFeatureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(ColorTheme.brandTeal.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ColorTheme.brandTeal)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func planCard(title: String, price: String, badge: String, isPopular: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isPopular ? Color.orange : ColorTheme.brandTeal)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }

                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.brandTeal)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(ColorTheme.brandTeal)
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isPopular ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
    }

    private func purchasePlan(productID: String) {
        if let product = proManager.products.first(where: { $0.id == productID }) {
            Task {
                do {
                    _ = try await proManager.purchase(product)
                } catch {
                    proManager.errorMessage = "Purchase failed: \(error.localizedDescription)"
                }
            }
        } else {
            proManager.errorMessage = "Products unavailable. Please try again later."
            Task {
                await proManager.fetchProducts()
            }
        }
    }
}
