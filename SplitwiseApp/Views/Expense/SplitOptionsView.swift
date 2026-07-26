import SwiftUI

public struct SplitOptionsView: View {
    @Environment(\.dismiss) private var dismiss

    public let totalAmount: Double
    public let currency: String
    public let members: [User]

    @Binding public var splitMethod: SplitMethod
    @Binding public var splits: [ExpenseSplit]

    @State private var tempSplits: [ExpenseSplit] = []

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Split Method Switcher Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SplitMethod.allCases) { method in
                            Button {
                                splitMethod = method
                                recalculateSplits(for: method)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(method.symbol)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    Text(method.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(splitMethod == method ? ColorTheme.brandTeal : ColorTheme.cardBackground)
                                .foregroundColor(splitMethod == method ? .white : .primary)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(ColorTheme.viewBackground)

                Divider()

                // Active Split Configuration View
                ScrollView {
                    VStack(spacing: 16) {
                        switch splitMethod {
                        case .equal:
                            equalSplitView
                        case .exact:
                            exactSplitView
                        case .percentage:
                            percentageSplitView
                        case .shares:
                            sharesSplitView
                        case .itemized:
                            itemizedSplitView
                        }
                    }
                    .padding()
                }
                .background(ColorTheme.viewBackground)
            }
            .navigationTitle("Split Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                if splits.isEmpty {
                    recalculateSplits(for: splitMethod)
                } else {
                    tempSplits = splits
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Split") {
                        splits = tempSplits
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.brandTeal)
                }
            }
        }
    }

    // MARK: - 1. Equal Split View
    private var equalSplitView: some View {
        VStack(spacing: 12) {
            Text("Split Equally (\(CurrencyFormatter.format(totalAmount / Double(max(1, members.count)), currency: currency)) / person)")
                .font(.headline)
                .foregroundColor(.secondary)

            ForEach(tempSplits) { split in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(ColorTheme.brandTeal)
                    Text(split.userName)
                        .fontWeight(.medium)
                    Spacer()
                    Text(CurrencyFormatter.format(split.amount, currency: currency))
                        .fontWeight(.semibold)
                }
                .padding(12)
                .background(ColorTheme.cardBackground)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - 2. Exact Amounts View
    private var exactSplitView: some View {
        let currentSum = tempSplits.reduce(0.0) { $0 + $1.amount }
        let remaining = totalAmount - currentSum

        return VStack(spacing: 12) {
            HStack {
                Text("Total: \(CurrencyFormatter.format(totalAmount, currency: currency))")
                Spacer()
                Text("Remaining: \(CurrencyFormatter.format(remaining, currency: currency))")
                    .foregroundColor(abs(remaining) < 0.01 ? ColorTheme.owedGreen : ColorTheme.owesOrange)
                    .fontWeight(.bold)
            }
            .font(.subheadline)
            .padding(.horizontal, 4)

            ForEach(0..<tempSplits.count, id: \.self) { i in
                HStack {
                    Text(tempSplits[i].userName)
                        .fontWeight(.medium)
                    Spacer()
                    Text(CurrencyFormatter.symbol(for: currency))
                        .foregroundColor(.secondary)
                    TextField("0.00", value: $tempSplits[i].amount, format: .number)
                        #if canImport(UIKit)
                        .keyboardType(.decimalPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(12)
                .background(ColorTheme.cardBackground)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - 3. Percentage View
    private var percentageSplitView: some View {
        let currentPct = tempSplits.reduce(0.0) { $0 + $1.percentage }

        return VStack(spacing: 12) {
            HStack {
                Text("Total: 100%")
                Spacer()
                Text("Current: \(String(format: "%.1f", currentPct))%")
                    .foregroundColor(abs(currentPct - 100.0) < 0.1 ? ColorTheme.owedGreen : ColorTheme.owesOrange)
                    .fontWeight(.bold)
            }
            .font(.subheadline)

            ForEach(0..<tempSplits.count, id: \.self) { i in
                HStack {
                    Text(tempSplits[i].userName)
                        .fontWeight(.medium)
                    Spacer()
                    TextField("0", value: $tempSplits[i].percentage, format: .number)
                        #if canImport(UIKit)
                        .keyboardType(.decimalPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: tempSplits[i].percentage) { _, newValue in
                            tempSplits[i].amount = (totalAmount * newValue) / 100.0
                        }
                    Text("%")
                        .foregroundColor(.secondary)

                    Text("(\(CurrencyFormatter.format(tempSplits[i].amount, currency: currency)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .trailing)
                }
                .padding(12)
                .background(ColorTheme.cardBackground)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - 4. Shares View
    private var sharesSplitView: some View {
        let totalShares = tempSplits.reduce(0) { $0 + $1.shares }

        return VStack(spacing: 12) {
            Text("Total Shares: \(totalShares)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(0..<tempSplits.count, id: \.self) { i in
                HStack {
                    Text(tempSplits[i].userName)
                        .fontWeight(.medium)
                    Spacer()
                    Stepper("\(tempSplits[i].shares) share(s)", value: $tempSplits[i].shares, in: 0...50)
                        .onChange(of: tempSplits[i].shares) { _, _ in
                            recalculateShares()
                        }
                    Text("(\(CurrencyFormatter.format(tempSplits[i].amount, currency: currency)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(12)
                .background(ColorTheme.cardBackground)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - 5. Itemized View (Splitwise Pro Feature)
    private var itemizedSplitView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "receipt.fill")
                    .foregroundColor(ColorTheme.brandTeal)
                Text("Itemized Receipt Breakdown")
                    .font(.headline)
            }

            ForEach(tempSplits) { split in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(split.userName)
                            .font(.headline)
                        Spacer()
                        Text("Assigned Total: \(CurrencyFormatter.format(split.amount, currency: currency))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.brandTeal)
                    }

                    if let items = split.itemizedItems, !items.isEmpty {
                        ForEach(items) { item in
                            HStack {
                                Text("• \(item.title)")
                                    .font(.caption)
                                Spacer()
                                Text(CurrencyFormatter.format(item.price, currency: currency))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(12)
                .background(ColorTheme.cardBackground)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Calculation Helpers
    private func recalculateSplits(for method: SplitMethod) {
        let count = Double(max(1, members.count))
        let equalShare = totalAmount / count

        tempSplits = members.map { member in
            ExpenseSplit(
                userId: member.id,
                userName: member.name,
                amount: (method == .equal) ? equalShare : (totalAmount / count),
                percentage: (100.0 / count),
                shares: 1,
                paidShare: 0.0
            )
        }
    }

    private func recalculateShares() {
        let totalShares = tempSplits.reduce(0) { $0 + $1.shares }
        guard totalShares > 0 else { return }

        for i in 0..<tempSplits.count {
            let portion = Double(tempSplits[i].shares) / Double(totalShares)
            tempSplits[i].amount = totalAmount * portion
        }
    }
}
