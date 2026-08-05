import Foundation

/// Shared split math + validation for Add Expense / Split Options.
public enum SplitMath {
    public static let tolerance: Double = 0.01

    /// Equal split with cent remainder assigned to the first members.
    public static func equalAmounts(total: Double, count: Int) -> [Double] {
        guard count > 0 else { return [] }
        let cents = Int((total * 100).rounded())
        let base = cents / count
        var remainder = cents % count
        return (0..<count).map { _ in
            var share = base
            if remainder > 0 {
                share += 1
                remainder -= 1
            }
            return Double(share) / 100.0
        }
    }

    public static func buildEqualSplits(
        members: [User],
        total: Double,
        payerId: UUID?
    ) -> [ExpenseSplit] {
        let amounts = equalAmounts(total: total, count: members.count)
        return zip(members, amounts).map { member, amount in
            ExpenseSplit(
                userId: member.id,
                userName: member.name,
                amount: amount,
                percentage: members.isEmpty ? 0 : (100.0 / Double(members.count)),
                shares: 1,
                paidShare: member.id == payerId ? total : 0
            )
        }
    }

    public static func isValid(
        method: SplitMethod,
        total: Double,
        splits: [ExpenseSplit]
    ) -> Bool {
        guard !splits.isEmpty, total > 0 else { return false }
        let sum = splits.reduce(0.0) { $0 + $1.amount }

        switch method {
        case .equal:
            return abs(sum - total) < tolerance
        case .exact:
            return abs(sum - total) < tolerance
        case .percentage:
            let pct = splits.reduce(0.0) { $0 + $1.percentage }
            return abs(pct - 100.0) < 0.1 && abs(sum - total) < tolerance
        case .shares:
            let totalShares = splits.reduce(0) { $0 + $1.shares }
            return totalShares > 0 && abs(sum - total) < tolerance
        case .itemized:
            let itemSum = splits.reduce(0.0) { partial, split in
                let items = split.itemizedItems ?? []
                if items.isEmpty { return partial + split.amount }
                return partial + items.reduce(0.0) { $0 + $1.price }
            }
            return abs(sum - total) < tolerance && abs(itemSum - total) < tolerance
        }
    }

    public static func validationMessage(
        method: SplitMethod,
        total: Double,
        splits: [ExpenseSplit]
    ) -> String? {
        guard isValid(method: method, total: total, splits: splits) else {
            switch method {
            case .exact:
                return String(localized: "Exact amounts must sum to the expense total.")
            case .percentage:
                return String(localized: "Percentages must total 100%.")
            case .shares:
                return String(localized: "Total shares must be greater than zero.")
            case .itemized:
                return String(localized: "Itemized assignments must match the expense total.")
            case .equal:
                return String(localized: "Equal split amounts are inconsistent with the total.")
            }
        }
        return nil
    }

    /// Distribute OCR line items round-robin across members and set amounts from item sums.
    public static func applyItemizedItems(
        _ items: [ItemizedSplit],
        to members: [User],
        total: Double,
        payerId: UUID?
    ) -> [ExpenseSplit] {
        guard !members.isEmpty else { return [] }
        var buckets: [[ItemizedSplit]] = Array(repeating: [], count: members.count)
        for (index, item) in items.enumerated() {
            buckets[index % members.count].append(item)
        }

        var splits = zip(members, buckets).map { member, assigned in
            let amount = assigned.reduce(0.0) { $0 + $1.price }
            return ExpenseSplit(
                userId: member.id,
                userName: member.name,
                amount: amount,
                percentage: total > 0 ? (amount / total) * 100.0 : 0,
                shares: 1,
                paidShare: member.id == payerId ? total : 0,
                itemizedItems: assigned
            )
        }

        // If OCR items don't cover total, put remainder on first member.
        let assignedSum = splits.reduce(0.0) { $0 + $1.amount }
        let remainder = ((total - assignedSum) * 100).rounded() / 100
        if abs(remainder) >= tolerance, !splits.isEmpty {
            splits[0].amount += remainder
            if var items = splits[0].itemizedItems, abs(remainder) > tolerance {
                items.append(ItemizedSplit(title: "Adjustment", price: remainder))
                splits[0].itemizedItems = items
            }
        }
        return splits
    }
}
