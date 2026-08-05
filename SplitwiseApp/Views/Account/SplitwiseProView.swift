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

                        Text("BillNest Pro")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        Text("Unlock high-power features to manage shared expenses like a pro.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 10)

                    // Pro Features List — pass LocalizedStringKey literals (not String vars)
                    VStack(alignment: .leading, spacing: 16) {
                        proFeatureRow(
                            icon: "doc.text.viewfinder",
                            title: "OCR Receipt Scanning",
                            desc: "Scan receipts automatically with Vision AI and convert items to split expenses."
                        )
                        proFeatureRow(
                            icon: "dollarsign.arrow.circlepath",
                            title: "Multi-Currency Conversion",
                            desc: "Convert amounts across 10+ currencies using in-app rates."
                        )
                        proFeatureRow(
                            icon: "doc.badge.plus",
                            title: "PDF & CSV Statements",
                            desc: "Export high-quality PDF reports for taxes, business trips, and roommates."
                        )
                        proFeatureRow(
                            icon: "chart.pie.fill",
                            title: "Advanced Analytics Charts",
                            desc: "Detailed monthly spending trends and category insights with Swift Charts."
                        )
                        proFeatureRow(
                            icon: "arrow.triangle.merge",
                            title: "Debt Simplification",
                            desc: "Reduce transfers for your groups using balance netting."
                        )
                        proFeatureRow(
                            icon: "nosign",
                            title: "Ad-Free Experience",
                            desc: "Enjoy clean, distraction-free expense tracking."
                        )
                    }
                    .padding()
                    .background(ColorTheme.cardBackground)
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Subscription Plans Cards
                    VStack(spacing: 14) {
                        planCard(
                            title: "Pro Monthly",
                            price: { planPriceView(for: ProSubscriptionManager.monthlyProID, fallback: "$2.99 / month") },
                            badge: { planBadgeView(for: ProSubscriptionManager.monthlyProID, fallback: "Auto-Renewable") },
                            isPopular: false
                        ) {
                            purchasePlan(productID: ProSubscriptionManager.monthlyProID)
                        }

                        planCard(
                            title: "Pro Annual",
                            price: { planPriceView(for: ProSubscriptionManager.yearlyProID, fallback: "$29.99 / year") },
                            badge: { planBadgeView(for: ProSubscriptionManager.yearlyProID, fallback: "Best Value") },
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
            .navigationTitle("BillNest Pro")
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

    @ViewBuilder
    private func planPriceView(for productID: String, fallback: LocalizedStringKey) -> some View {
        if let product = product(for: productID), let subscription = product.subscription {
            let period = subscription.subscriptionPeriod
            HStack(spacing: 4) {
                Text(product.displayPrice)
                Text("/")
                periodUnitText(unit: period.unit, value: period.value)
            }
        } else if let product = product(for: productID) {
            Text(product.displayPrice)
        } else {
            Text(fallback)
        }
    }

    @ViewBuilder
    private func periodUnitText(unit: Product.SubscriptionPeriod.Unit, value: Int) -> some View {
        switch unit {
        case .day:
            if value == 1 {
                Text("day")
            } else {
                Text("\(value) days")
            }
        case .week:
            if value == 1 {
                Text("week")
            } else {
                Text("\(value) weeks")
            }
        case .month:
            if value == 1 {
                Text("month")
            } else {
                Text("\(value) months")
            }
        case .year:
            if value == 1 {
                Text("year")
            } else {
                Text("\(value) years")
            }
        @unknown default:
            Text("period")
        }
    }

    @ViewBuilder
    private func planBadgeView(for productID: String, fallback: LocalizedStringKey) -> some View {
        if let offer = product(for: productID)?.subscription?.introductoryOffer {
            switch offer.paymentMode {
            case .freeTrial:
                freeTrialBadgeText(period: offer.period)
            case .payAsYouGo, .payUpFront:
                Text("Intro Offer")
            default:
                Text("Intro Offer")
            }
        } else {
            Text(fallback)
        }
    }

    @ViewBuilder
    private func freeTrialBadgeText(period: Product.SubscriptionPeriod) -> some View {
        Text("\(localizedTrialUnit(for: period)) Free Trial")
    }

    private func localizedTrialUnit(for period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            return period.value == 1
                ? Bundle.main.localizedString(forKey: "Day", value: nil, table: nil)
                : String(format: Bundle.main.localizedString(forKey: "%lld-Day", value: nil, table: nil), period.value)
        case .week:
            return period.value == 1
                ? Bundle.main.localizedString(forKey: "Week", value: nil, table: nil)
                : String(format: Bundle.main.localizedString(forKey: "%lld-Week", value: nil, table: nil), period.value)
        case .month:
            return period.value == 1
                ? Bundle.main.localizedString(forKey: "Month", value: nil, table: nil)
                : String(format: Bundle.main.localizedString(forKey: "%lld-Month", value: nil, table: nil), period.value)
        case .year:
            return period.value == 1
                ? Bundle.main.localizedString(forKey: "Year", value: nil, table: nil)
                : String(format: Bundle.main.localizedString(forKey: "%lld-Year", value: nil, table: nil), period.value)
        @unknown default:
            return Bundle.main.localizedString(forKey: "Trial", value: nil, table: nil)
        }
    }

    private func proFeatureRow(icon: String, title: LocalizedStringKey, desc: LocalizedStringKey) -> some View {
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

    private func planCard<Price: View, Badge: View>(
        title: LocalizedStringKey,
        @ViewBuilder price: () -> Price,
        @ViewBuilder badge: () -> Badge,
        isPopular: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        badge()
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isPopular ? Color.orange : ColorTheme.brandTeal)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }

                    price()
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
                    proManager.errorMessage = String(
                        localized: "Purchase failed: \(error.localizedDescription)"
                    )
                }
            }
        } else {
            proManager.errorMessage = String(localized: "Products unavailable. Please try again later.")
            Task {
                await proManager.fetchProducts()
            }
        }
    }
}
