import SwiftUI
import StoreKit

public struct SplitwiseProView: View {
    @Environment(\.dismiss) private var dismiss
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
                        proFeatureRow(icon: "dollarsign.arrow.circlepath", title: "Real-time Multi-Currency", desc: "Automatic rate conversion across 10+ currencies.")
                        proFeatureRow(icon: "doc.badge.plus", title: "PDF & CSV Statements", desc: "Export high-quality PDF reports for taxes, business trips, and roommates.")
                        proFeatureRow(icon: "chart.pie.fill", title: "Advanced Analytics Charts", desc: "Detailed monthly spending trends and category insights with Swift Charts.")
                        proFeatureRow(icon: "arrow.triangle.merge", title: "Automatic Debt Simplification", desc: "Minimize transfers for all your groups using graph min-flow algorithms.")
                        proFeatureRow(icon: "nosign", title: "100% Ad-Free Experience", desc: "Enjoy clean, distraction-free expense tracking.")
                    }
                    .padding()
                    .background(ColorTheme.cardBackground)
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Subscription Plans Cards
                    VStack(spacing: 14) {
                        planCard(
                            title: "Pro Monthly",
                            price: "$2.99 / month",
                            badge: "7-Day Free Trial",
                            isPopular: false
                        ) {
                            purchasePlan(productID: ProSubscriptionManager.monthlyProID)
                        }

                        planCard(
                            title: "Pro Annual",
                            price: "$29.99 / year",
                            badge: "Save 16%",
                            isPopular: true
                        ) {
                            purchasePlan(productID: ProSubscriptionManager.yearlyProID)
                        }
                    }
                    .padding(.horizontal)

                    // Restore & Mock Demo Switcher
                    VStack(spacing: 12) {
                        Button("Restore Purchases") {
                            Task {
                                await proManager.restorePurchases()
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.brandTeal)

                        Toggle("Simulator Mock Pro Mode", isOn: $proManager.isMockPro)
                            .tint(ColorTheme.brandTeal)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(ColorTheme.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)

                        Text("Subscription automatically renews unless cancelled in Apple ID Settings at least 24h before end of period. Terms of Service & Privacy Policy apply.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
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
                _ = try? await proManager.purchase(product)
            }
        } else {
            // Enable mock Pro for simulator demo
            proManager.isMockPro = true
        }
    }
}
