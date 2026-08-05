import SwiftUI
import SwiftData

public struct GroupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    public let group: Group

    @Query private var allExpenses: [Expense]
    @Query private var allSettlements: [Settlement]
    @Query private var allUsers: [User]

    @State private var showingAddExpense = false
    @State private var showingSettleUp = false
    @State private var showingSimplifyDebts = false
    @State private var showingSettings = false
    @State private var showingExport = false

    private var groupExpenses: [Expense] {
        allExpenses.filter { $0.groupId == group.id }.sorted { $0.date > $1.date }
    }

    private var groupSettlements: [Settlement] {
        allSettlements.filter { $0.groupId == group.id }.sorted { $0.date > $1.date }
    }

    private var groupMembers: [User] {
        allUsers.filter { group.memberIds.contains($0.id) }
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Banner
                    headerBanner

                    // Action Buttons (Settle Up, Balances, Simplify, Export)
                    actionButtonsRow

                    // Net Balances Summary Section
                    memberBalancesCard

                    // Expenses List
                    if groupExpenses.isEmpty && groupSettlements.isEmpty {
                        emptyExpensesState
                    } else {
                        expensesSection
                    }
                }
                .padding(.bottom, 80)
            }
            .background(ColorTheme.viewBackground)

            // Floating Action Button (+) Add Expense
            addExpenseFAB
        }
        .navigationTitle(group.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(ColorTheme.brandTeal)
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(preselectedGroup: group)
        }
        .sheet(isPresented: $showingSettleUp) {
            SettleUpView(group: group)
        }
        .sheet(isPresented: $showingSimplifyDebts) {
            SimplifyDebtsView(group: group, members: groupMembers, expenses: groupExpenses, settlements: groupSettlements)
        }
        .sheet(isPresented: $showingSettings) {
            GroupSettingsView(group: group)
        }
        .sheet(isPresented: $showingExport) {
            ExportReportView(group: group, members: groupMembers, expenses: groupExpenses, settlements: groupSettlements)
        }
    }

    // MARK: - Header Banner
    private var headerBanner: some View {
        let totalSpent = groupExpenses.reduce(0.0) { $0 + $1.amount }

        return HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ColorTheme.brandTeal.opacity(0.2))
                    .frame(width: 64, height: 64)
                Image(systemName: group.groupType.iconName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(ColorTheme.brandTeal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Total Group Spending: \(CurrencyFormatter.format(totalSpent, currency: group.defaultCurrency))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(ColorTheme.cardBackground)
    }

    // MARK: - Action Buttons Row
    private var actionButtonsRow: some View {
        HStack(spacing: 12) {
            Button {
                showingSettleUp = true
            } label: {
                Label("Settle Up", systemImage: "dollarsign.arrow.circlepath")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(ColorTheme.brandTeal)
                    .cornerRadius(10)
            }

            Button {
                if group.simplifyDebts {
                    ProAccess.require(.debtSimplification) {
                        showingSimplifyDebts = true
                    }
                } else {
                    showingSimplifyDebts = true
                }
            } label: {
                HStack(spacing: 4) {
                    Label(group.simplifyDebts ? "Simplify" : "Balances", systemImage: "arrow.triangle.merge")
                    if group.simplifyDebts && !ProAccess.isPro {
                        ProBadge()
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.brandTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(ColorTheme.brandTeal.opacity(0.12))
                .cornerRadius(10)
            }

            Button {
                showingExport = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.brandTeal)
                    .padding(10)
                    .background(ColorTheme.brandTeal.opacity(0.12))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Member Balances Card
    private var memberBalancesCard: some View {
        let netBalances = DebtSimplifier.calculateNetBalances(
            members: groupMembers,
            expenses: groupExpenses,
            settlements: groupSettlements,
            baseCurrency: group.defaultCurrency
        )

        return VStack(alignment: .leading, spacing: 10) {
            Text("Group Balances")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(groupMembers) { member in
                        let net = netBalances[member.id] ?? 0.0
                        let isMe = (member.id == appState.currentUserId)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: member.avatarName)
                                    .foregroundColor(ColorTheme.brandTeal)
                                Text(isMe ? "You" : member.name)
                                    .font(.subheadline)
                                    .fontWeight(isMe ? .bold : .medium)
                            }

                            if net > 0.009 {
                                Text("gets back \(CurrencyFormatter.format(net, currency: group.defaultCurrency))")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(ColorTheme.owedGreen)
                            } else if net < -0.009 {
                                Text("owes \(CurrencyFormatter.format(abs(net), currency: group.defaultCurrency))")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(ColorTheme.owesOrange)
                            } else {
                                Text("settled up")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(ColorTheme.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Expenses Section
    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expenses & History")
                .font(.headline)
                .padding(.horizontal)

            LazyVStack(spacing: 10) {
                ForEach(groupExpenses) { expense in
                    NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                        expenseRow(expense)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(groupSettlements) { settlement in
                    settlementRow(settlement)
                }
            }
            .padding(.horizontal)
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        let payer = allUsers.first(where: { $0.id == expense.payerId })
        let payerName = (payer?.id == appState.currentUserId) ? "You" : (payer?.name ?? "Someone")

        let mySplit = expense.splits.first(where: { $0.userId == appState.currentUserId })
        let myOwedShare = mySplit?.amount ?? 0.0

        return HStack(spacing: 14) {
            CategoryIconView(category: expense.category, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.body)
                    .fontWeight(.semibold)

                Text("\(payerName) paid \(CurrencyFormatter.format(expense.amount, currency: expense.currency))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if payer?.id == appState.currentUserId {
                    Text("you lent")
                        .font(.caption2)
                        .foregroundColor(ColorTheme.owedGreen)
                    Text(CurrencyFormatter.format(expense.amount - myOwedShare, currency: expense.currency))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.owedGreen)
                } else if myOwedShare > 0 {
                    Text("you owe")
                        .font(.caption2)
                        .foregroundColor(ColorTheme.owesOrange)
                    Text(CurrencyFormatter.format(myOwedShare, currency: expense.currency))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.owesOrange)
                } else {
                    Text("not involved")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }

    private func settlementRow(_ settlement: Settlement) -> some View {
        let payer = allUsers.first(where: { $0.id == settlement.payerId })
        let payee = allUsers.first(where: { $0.id == settlement.payeeId })

        let payerName = (payer?.id == appState.currentUserId) ? "You" : (payer?.name ?? "User")
        let payeeName = (payee?.id == appState.currentUserId) ? "you" : (payee?.name ?? "User")

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ColorTheme.brandTeal.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(ColorTheme.brandTeal)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(payerName) paid \(payeeName)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(settlement.paymentMethod) • \(CurrencyFormatter.format(settlement.amount, currency: settlement.currency))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("Payment")
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ColorTheme.brandTeal.opacity(0.12))
                .foregroundColor(ColorTheme.brandTeal)
                .cornerRadius(6)
        }
        .padding(14)
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }

    private var emptyExpensesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "receipt.fill")
                .font(.system(size: 44))
                .foregroundColor(ColorTheme.brandTeal.opacity(0.4))
                .padding(.top, 24)

            Text("No Expenses Added Yet")
                .font(.headline)

            Text("Tap the '+' button below to record an expense for this group.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Floating Action Button
    private var addExpenseFAB: some View {
        Button {
            showingAddExpense = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Add Expense")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(ColorTheme.brandTeal)
            .cornerRadius(30)
            .shadow(color: ColorTheme.brandTeal.opacity(0.4), radius: 10, x: 0, y: 6)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}
