import XCTest
@testable import SplitwiseApp

final class SplitMathTests: XCTestCase {
    func testEqualSplitRemainderGoesToFirstMembers() {
        let amounts = SplitMath.equalAmounts(total: 10.00, count: 3)
        XCTAssertEqual(amounts.count, 3)
        XCTAssertEqual(amounts.reduce(0, +), 10.00, accuracy: 0.001)
        XCTAssertEqual(amounts[0], 3.34, accuracy: 0.001)
        XCTAssertEqual(amounts[1], 3.33, accuracy: 0.001)
        XCTAssertEqual(amounts[2], 3.33, accuracy: 0.001)
    }

    func testExactValidationRequiresMatchingTotal() {
        let userA = UUID()
        let userB = UUID()
        let splits = [
            ExpenseSplit(userId: userA, userName: "A", amount: 4),
            ExpenseSplit(userId: userB, userName: "B", amount: 6)
        ]
        XCTAssertTrue(SplitMath.isValid(method: .exact, total: 10, splits: splits))
        XCTAssertFalse(SplitMath.isValid(method: .exact, total: 9.5, splits: splits))
    }

    func testSharesZeroIsInvalid() {
        let splits = [
            ExpenseSplit(userId: UUID(), userName: "A", amount: 5, shares: 0),
            ExpenseSplit(userId: UUID(), userName: "B", amount: 5, shares: 0)
        ]
        XCTAssertFalse(SplitMath.isValid(method: .shares, total: 10, splits: splits))
    }

    func testCSVFormulaInjectionPrefix() {
        XCTAssertTrue(ExportManager.csvField("=1+1").hasPrefix("\"'=1+1"))
        XCTAssertEqual(ExportManager.csvField("hello\"world"), "\"hello\"\"world\"")
    }
}

final class DebtSimplifierTests: XCTestCase {
    func testMultiCurrencyConvertedBeforeNetting() {
        let me = User(name: "Me", isCurrentUser: true)
        let friend = User(name: "Friend")
        let expense = Expense(
            title: "JPY Lunch",
            amount: 1000,
            currency: "JPY",
            payerId: me.id,
            groupId: nil,
            splitMethod: .equal,
            category: .food,
            splits: [
                ExpenseSplit(userId: me.id, userName: me.name, amount: 500),
                ExpenseSplit(userId: friend.id, userName: friend.name, amount: 500)
            ]
        )

        let balances = DebtSimplifier.calculateNetBalances(
            members: [me, friend],
            expenses: [expense],
            settlements: [],
            baseCurrency: "USD"
        )

        let expectedFriendDebt = CurrencyFormatter.convert(amount: 500, from: "JPY", to: "USD")
        XCTAssertEqual(balances[friend.id] ?? 0, -expectedFriendDebt, accuracy: 0.0001)
        XCTAssertEqual(balances[me.id] ?? 0, expectedFriendDebt, accuracy: 0.0001)
    }

    func testSimplifyReducesOrEqualsRawCount() {
        let a = User(name: "A")
        let b = User(name: "B")
        let c = User(name: "C")

        let e1 = Expense(
            title: "E1",
            amount: 30,
            currency: "USD",
            payerId: a.id,
            splitMethod: .equal,
            category: .general,
            splits: [
                ExpenseSplit(userId: a.id, userName: "A", amount: 10),
                ExpenseSplit(userId: b.id, userName: "B", amount: 10),
                ExpenseSplit(userId: c.id, userName: "C", amount: 10)
            ]
        )
        let e2 = Expense(
            title: "E2",
            amount: 20,
            currency: "USD",
            payerId: b.id,
            splitMethod: .equal,
            category: .general,
            splits: [
                ExpenseSplit(userId: a.id, userName: "A", amount: 10),
                ExpenseSplit(userId: b.id, userName: "B", amount: 10)
            ]
        )

        let members = [a, b, c]
        let expenses = [e1, e2]
        let raw = DebtSimplifier.computeRawPairwiseDebts(
            members: members,
            expenses: expenses,
            settlements: [],
            currency: "USD"
        )
        let simplified = DebtSimplifier.simplifyDebts(
            members: members,
            expenses: expenses,
            settlements: [],
            currency: "USD"
        )
        XCTAssertLessThanOrEqual(simplified.count, raw.count)
    }
}
