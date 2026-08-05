import SwiftUI
import SwiftData

public struct FriendDetailView: View {
    @Environment(AppState.self) private var appState
    public let friend: User

    @Query private var expenses: [Expense]
    @Query private var settlements: [Settlement]

    @State private var showingSettleUp = false
    @State private var showingAddExpense = false

    private var friendExpenses: [Expense] {
        expenses.filter { expense in
            let myId = appState.currentUserId
            let involved = expense.splits.map { $0.userId }
            return (expense.payerId == myId && involved.contains(friend.id)) ||
                   (expense.payerId == friend.id && involved.contains(myId))
        }.sorted { $0.date > $1.date }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Friend Header Summary
                headerCard

                // Actions: Add Expense + Settle Up
                HStack(spacing: 12) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Label("Add Expense", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(ColorTheme.brandTeal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ColorTheme.brandTeal.opacity(0.12))
                            .cornerRadius(12)
                    }

                    Button {
                        showingSettleUp = true
                    } label: {
                        Label("Settle Up", systemImage: "dollarsign.arrow.circlepath")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ColorTheme.brandTeal)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                // History
                if friendExpenses.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 40))
                            .foregroundColor(ColorTheme.brandTeal)
                            .padding(.top, 30)
                        Text("No shared expenses yet")
                            .font(.headline)
                        Text("When you add expenses with \(friend.name), they will show up here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Shared Expenses History")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(friendExpenses) { expense in
                            NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                                expenseRow(expense)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(ColorTheme.viewBackground)
        .navigationTitle(friend.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .hidesTabBarWhenPushed()
        .sheet(isPresented: $showingSettleUp) {
            SettleUpView(targetPayee: friend)
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(preselectedFriend: friend)
        }
    }

    private var headerCard: some View {
        let net = calculateNetWithFriend()

        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ColorTheme.brandTeal.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: friend.avatarName)
                    .font(.system(size: 38))
                    .foregroundColor(ColorTheme.brandTeal)
            }

            Text(friend.name)
                .font(.title2)
                .fontWeight(.bold)

            if net > 0.009 {
                Text("\(friend.name) owes you \(CurrencyFormatter.format(net, currency: appState.selectedCurrency))")
                    .font(.headline)
                    .foregroundColor(ColorTheme.owedGreen)
            } else if net < -0.009 {
                Text("You owe \(friend.name) \(CurrencyFormatter.format(abs(net), currency: appState.selectedCurrency))")
                    .font(.headline)
                    .foregroundColor(ColorTheme.owesOrange)
            } else {
                Text("You and \(friend.name) are all settled up!")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(ColorTheme.cardBackground)
    }

    private func expenseRow(_ expense: Expense) -> some View {
        let isMePayer = (expense.payerId == appState.currentUserId)

        return HStack(spacing: 14) {
            CategoryIconView(category: expense.category, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.body)
                    .fontWeight(.semibold)

                Text(isMePayer ? "You paid \(CurrencyFormatter.format(expense.amount, currency: expense.currency))" : "\(friend.name) paid \(CurrencyFormatter.format(expense.amount, currency: expense.currency))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isMePayer {
                if let friendSplit = expense.splits.first(where: { $0.userId == friend.id }) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("owes you")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.owedGreen)
                        Text(CurrencyFormatter.format(friendSplit.amount, currency: expense.currency))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.owedGreen)
                    }
                }
            } else {
                if let mySplit = expense.splits.first(where: { $0.userId == appState.currentUserId }) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("you owe")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.owesOrange)
                        Text(CurrencyFormatter.format(mySplit.amount, currency: expense.currency))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.owesOrange)
                    }
                }
            }
        }
        .padding(14)
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }

    private func calculateNetWithFriend() -> Double {
        var net: Double = 0.0
        let myId = appState.currentUserId
        let displayCurrency = appState.selectedCurrency

        for expense in expenses {
            if expense.payerId == myId {
                if let friendSplit = expense.splits.first(where: { $0.userId == friend.id }) {
                    net += CurrencyFormatter.convert(
                        amount: friendSplit.amount,
                        from: expense.currency,
                        to: displayCurrency
                    )
                }
            } else if expense.payerId == friend.id {
                if let mySplit = expense.splits.first(where: { $0.userId == myId }) {
                    net -= CurrencyFormatter.convert(
                        amount: mySplit.amount,
                        from: expense.currency,
                        to: displayCurrency
                    )
                }
            }
        }

        for settlement in settlements {
            let amount = CurrencyFormatter.convert(
                amount: settlement.amount,
                from: settlement.currency,
                to: displayCurrency
            )
            if settlement.payerId == myId && settlement.payeeId == friend.id {
                net += amount
            } else if settlement.payerId == friend.id && settlement.payeeId == myId {
                net -= amount
            }
        }

        return net
    }
}
