import Foundation

public struct SimplifiedTransaction: Identifiable, Hashable {
    public var id: UUID
    public var debtorId: UUID
    public var debtorName: String
    public var creditorId: UUID
    public var creditorName: String
    public var amount: Double
    public var currency: String

    public init(
        id: UUID = UUID(),
        debtorId: UUID,
        debtorName: String,
        creditorId: UUID,
        creditorName: String,
        amount: Double,
        currency: String = "USD"
    ) {
        self.id = id
        self.debtorId = debtorId
        self.debtorName = debtorName
        self.creditorId = creditorId
        self.creditorName = creditorName
        self.amount = amount
        self.currency = currency
    }
}

public struct UserBalance: Identifiable {
    public var id: UUID { userId }
    public var userId: UUID
    public var userName: String
    public var netBalance: Double
}

public enum DebtSimplifier {

    /// Calculates individual net balances for all members, converting every amount into `baseCurrency`
    /// using the static in-app rate table (not live FX).
    /// Positive balance = User is owed money (+).
    /// Negative balance = User owes money (-).
    public static func calculateNetBalances(
        members: [User],
        expenses: [Expense],
        settlements: [Settlement],
        baseCurrency: String = "USD"
    ) -> [UUID: Double] {
        var balances: [UUID: Double] = [:]
        for member in members {
            balances[member.id] = 0.0
        }

        for expense in expenses {
            let total = CurrencyFormatter.convert(
                amount: expense.amount,
                from: expense.currency,
                to: baseCurrency
            )
            balances[expense.payerId, default: 0.0] += total

            for split in expense.splits {
                let share = CurrencyFormatter.convert(
                    amount: split.amount,
                    from: expense.currency,
                    to: baseCurrency
                )
                balances[split.userId, default: 0.0] -= share
            }
        }

        for settlement in settlements {
            let amount = CurrencyFormatter.convert(
                amount: settlement.amount,
                from: settlement.currency,
                to: baseCurrency
            )
            balances[settlement.payerId, default: 0.0] += amount
            balances[settlement.payeeId, default: 0.0] -= amount
        }

        return balances
    }

    /// Reduces net balances into fewer transfers. Uses a greedy pairing heuristic (reduces transfers;
    /// not a proven global minimum for all graphs).
    public static func simplifyDebts(
        members: [User],
        expenses: [Expense],
        settlements: [Settlement],
        currency: String = "USD"
    ) -> [SimplifiedTransaction] {
        let netBalances = calculateNetBalances(
            members: members,
            expenses: expenses,
            settlements: settlements,
            baseCurrency: currency
        )
        let memberDict = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.name) })

        var creditors: [(id: UUID, amount: Double)] = []
        var debtors: [(id: UUID, amount: Double)] = []

        for (userId, net) in netBalances {
            let rounded = (net * 100).rounded() / 100
            if rounded > 0.009 {
                creditors.append((userId, rounded))
            } else if rounded < -0.009 {
                debtors.append((userId, -rounded))
            }
        }

        creditors.sort { $0.amount > $1.amount }
        debtors.sort { $0.amount > $1.amount }

        var result: [SimplifiedTransaction] = []
        var i = 0
        var j = 0

        while i < creditors.count && j < debtors.count {
            var creditor = creditors[i]
            var debtor = debtors[j]

            let settleAmount = min(creditor.amount, debtor.amount)
            let roundedSettle = (settleAmount * 100).rounded() / 100

            if roundedSettle > 0 {
                let debtorName = memberDict[debtor.id] ?? "Unknown"
                let creditorName = memberDict[creditor.id] ?? "Unknown"
                result.append(
                    SimplifiedTransaction(
                        debtorId: debtor.id,
                        debtorName: debtorName,
                        creditorId: creditor.id,
                        creditorName: creditorName,
                        amount: roundedSettle,
                        currency: currency
                    )
                )
            }

            creditor.amount -= roundedSettle
            debtor.amount -= roundedSettle

            if creditor.amount < 0.01 {
                i += 1
            } else {
                creditors[i] = creditor
            }

            if debtor.amount < 0.01 {
                j += 1
            } else {
                debtors[j] = debtor
            }
        }

        return result
    }

    /// Pairwise debts after converting to `currency`, then netting opposite edges and applying settlements.
    public static func computeRawPairwiseDebts(
        members: [User],
        expenses: [Expense],
        settlements: [Settlement],
        currency: String = "USD"
    ) -> [SimplifiedTransaction] {
        var pairwise: [UUID: [UUID: Double]] = [:]
        let memberDict = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.name) })

        for expense in expenses {
            let payerId = expense.payerId
            for split in expense.splits {
                if split.userId != payerId && split.amount > 0 {
                    let share = CurrencyFormatter.convert(
                        amount: split.amount,
                        from: expense.currency,
                        to: currency
                    )
                    pairwise[split.userId, default: [:]][payerId, default: 0.0] += share
                }
            }
        }

        for settlement in settlements {
            let amount = CurrencyFormatter.convert(
                amount: settlement.amount,
                from: settlement.currency,
                to: currency
            )
            let payerId = settlement.payerId
            let payeeId = settlement.payeeId

            // Settlement: payer pays payee → reduces payer→payee debt, or creates reverse credit.
            let existing = pairwise[payerId]?[payeeId] ?? 0
            if existing >= amount {
                pairwise[payerId, default: [:]][payeeId] = existing - amount
            } else {
                pairwise[payerId]?[payeeId] = nil
                let remainder = amount - existing
                pairwise[payeeId, default: [:]][payerId, default: 0.0] += remainder
            }
        }

        // Net opposite directed edges A→B and B→A.
        let debtorIds = Array(pairwise.keys)
        for a in debtorIds {
            let creditors = Array((pairwise[a] ?? [:]).keys)
            for b in creditors {
                let ab = pairwise[a]?[b] ?? 0
                let ba = pairwise[b]?[a] ?? 0
                if ab > 0 && ba > 0 {
                    if ab >= ba {
                        pairwise[a]?[b] = ab - ba
                        pairwise[b]?[a] = nil
                    } else {
                        pairwise[b]?[a] = ba - ab
                        pairwise[a]?[b] = nil
                    }
                }
            }
        }

        var result: [SimplifiedTransaction] = []
        for (debtorId, creditors) in pairwise {
            for (creditorId, amount) in creditors {
                let rounded = (amount * 100).rounded() / 100
                if rounded > 0.01 {
                    result.append(
                        SimplifiedTransaction(
                            debtorId: debtorId,
                            debtorName: memberDict[debtorId] ?? "User",
                            creditorId: creditorId,
                            creditorName: memberDict[creditorId] ?? "User",
                            amount: rounded,
                            currency: currency
                        )
                    )
                }
            }
        }
        return result
    }
}
