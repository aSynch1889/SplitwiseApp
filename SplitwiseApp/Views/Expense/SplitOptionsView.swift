import SwiftUI

public struct SplitOptionsView: View {
    @Environment(\.dismiss) private var dismiss

    public let totalAmount: Double
    public let currency: String
    public let members: [User]

    @Binding public var splitMethod: SplitMethod
    @Binding public var splits: [ExpenseSplit]

    @State private var draftMethod: SplitMethod = .equal
    @State private var tempSplits: [ExpenseSplit] = []
    @State private var validationError: String?

    private var canSaveSplit: Bool {
        SplitMath.isValid(method: draftMethod, total: totalAmount, splits: tempSplits)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SplitMethod.allCases) { method in
                            Button {
                                draftMethod = method
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
                                .background(draftMethod == method ? ColorTheme.brandTeal : ColorTheme.cardBackground)
                                .foregroundColor(draftMethod == method ? .white : .primary)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(ColorTheme.viewBackground)

                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        switch draftMethod {
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
                draftMethod = splitMethod
                if splits.isEmpty {
                    recalculateSplits(for: draftMethod)
                } else {
                    tempSplits = splits
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Split") {
                        guard canSaveSplit else {
                            validationError = SplitMath.validationMessage(
                                method: draftMethod,
                                total: totalAmount,
                                splits: tempSplits
                            )
                            return
                        }
                        splitMethod = draftMethod
                        splits = tempSplits
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.brandTeal)
                    .disabled(!canSaveSplit)
                }
            }
            .alert("Invalid Split", isPresented: Binding(
                get: { validationError != nil },
                set: { if !$0 { validationError = nil } }
            )) {
                Button("OK", role: .cancel) { validationError = nil }
            } message: {
                Text(validationError ?? "")
            }
        }
    }

    private var equalSplitView: some View {
        VStack(spacing: 12) {
            Text("Split Equally (remainder cents assigned to first members)")
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

    private var sharesSplitView: some View {
        let totalShares = tempSplits.reduce(0) { $0 + $1.shares }

        return VStack(spacing: 12) {
            Text("Total Shares: \(totalShares)")
                .font(.subheadline)
                .foregroundColor(totalShares > 0 ? .secondary : ColorTheme.owesOrange)

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

    private var itemizedSplitView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "receipt.fill")
                    .foregroundColor(ColorTheme.brandTeal)
                Text("Itemized Receipt Breakdown")
                    .font(.headline)
            }

            Text("Assign items from OCR or Options. Save requires item totals to match the expense.")
                .font(.caption)
                .foregroundColor(.secondary)

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
                    } else {
                        Text("No items assigned yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(ColorTheme.cardBackground)
                .cornerRadius(12)
            }
        }
    }

    private func recalculateSplits(for method: SplitMethod) {
        switch method {
        case .equal:
            tempSplits = SplitMath.buildEqualSplits(members: members, total: totalAmount, payerId: nil)
        case .shares:
            tempSplits = members.map {
                ExpenseSplit(userId: $0.id, userName: $0.name, amount: 0, percentage: 0, shares: 1)
            }
            recalculateShares()
        case .itemized:
            if tempSplits.contains(where: { ($0.itemizedItems ?? []).isEmpty == false }) {
                // Keep existing item assignments when switching back to itemized.
                return
            }
            let count = Double(max(1, members.count))
            tempSplits = members.map { member in
                ExpenseSplit(
                    userId: member.id,
                    userName: member.name,
                    amount: totalAmount / count,
                    percentage: 100.0 / count,
                    shares: 1,
                    paidShare: 0.0
                )
            }
        default:
            let count = Double(max(1, members.count))
            tempSplits = members.map { member in
                ExpenseSplit(
                    userId: member.id,
                    userName: member.name,
                    amount: totalAmount / count,
                    percentage: 100.0 / count,
                    shares: 1,
                    paidShare: 0.0
                )
            }
        }
    }

    private func recalculateShares() {
        let totalShares = tempSplits.reduce(0) { $0 + $1.shares }
        guard totalShares > 0 else {
            for i in 0..<tempSplits.count {
                tempSplits[i].amount = 0
            }
            return
        }

        let amounts = SplitMath.equalAmounts(total: totalAmount, count: totalShares)
        // Map share units to amounts: distribute by share count using proportional cents.
        var cursor = 0
        for i in 0..<tempSplits.count {
            let shareCount = tempSplits[i].shares
            let slice = amounts[cursor..<(cursor + shareCount)]
            tempSplits[i].amount = slice.reduce(0, +)
            cursor += shareCount
        }
    }
}
