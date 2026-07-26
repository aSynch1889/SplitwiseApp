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

    /// Calculates individual net balances for all members in a group.
    /// Positive balance = User is owed money (+).
    /// Negative balance = User owes money (-).
    public static func calculateNetBalances(
        members: [User],
        expenses: [Expense],
        settlements: [Settlement]
    ) -> [UUID: Double] {
        var balances: [UUID: Double] = [:]
        for member in members {
            balances[member.id] = 0.0
        }

        // Process Expenses
        for expense in expenses {
            // Payer gets credit for total expense amount paid upfront
            balances[expense.payerId, default: 0.0] += expense.amount

            // Each member in splits owes their designated share
            for split in expense.splits {
                balances[split.userId, default: 0.0] -= split.amount
            }
        }

        // Process Settlements
        for settlement in settlements {
            // Payer paid payee, so payer's net balance increases (they gave money), payee's net balance decreases (they received money)
            balances[settlement.payerId, default: 0.0] += settlement.amount
            balances[settlement.payeeId, default: 0.0] -= settlement.amount
        }

        return balances
    }

    /// Simplifies net balances into the minimum number of transactions needed to clear all debts.
    public static func simplifyDebts(
        members: [User],
        expenses: [Expense],
        settlements: [Settlement],
        currency: String = "USD"
    ) -> [SimplifiedTransaction] {
        let netBalances = calculateNetBalances(members: members, expenses: expenses, settlements: settlements)
        let memberDict = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.name) })

        var creditors: [(id: UUID, amount: Double)] = []
        var debtors: [(id: UUID, amount: Double)] = []

        for (userId, net) in netBalances {
            let rounded = (net * 100).rounded() / 100
            if rounded > 0.009 {
                creditors.append((userId, rounded))
            } else if rounded < -0.009 {
                debtors.append((userId, -rounded)) // Store as positive magnitude
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

    /// Computes non-simplified pairwise debts for comparison view.
    public static func computeRawPairwiseDebts(
        members: [User],
        expenses: [Expense],
        settlements: [Settlement],
        currency: String = "USD"
    ) -> [SimplifiedTransaction] {
        var pairwise: [UUID: [UUID: Double]] = [:] // [Debtor: [Creditor: Amount]]
        let memberDict = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.name) })

        for expense in expenses {
            let payerId = expense.payerId
            for split in expense.splits {
                if split.userId != payerId && split.amount > 0 {
                    pairwise[split.userId, default: [:]][payerId, default: 0.0] += split.amount
                }
            }
        }

        for settlement in settlements {
            let payerId = settlement.payerId
            let payeeId = settlement.payeeId
            // Subtract settlement from debt
            if let currentDebt = pairwise[payerId]?[payeeId], currentDebt > 0 {
                let newDebt = max(0, currentDebt - settlement.amount)
                pairwise[payerId]?[payeeId] = newDebt
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
