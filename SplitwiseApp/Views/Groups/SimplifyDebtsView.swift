import SwiftUI

public struct SimplifyDebtsView: View {
    @Environment(\.dismiss) private var dismiss

    public let group: Group
    public let members: [User]
    public let expenses: [Expense]
    public let settlements: [Settlement]

    @State private var showingSimplifiedOnly = true

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Explainer Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.title2)
                                .foregroundColor(ColorTheme.brandTeal)
                            Text("Splitwise Debt Simplification")
                                .font(.headline)
                        }

                        Text("Debt simplification calculates net balances to reduce the total number of transactions between group members.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(ColorTheme.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Toggle segment
                    Picker("Mode", selection: $showingSimplifiedOnly) {
                        Text("Simplified Debts").tag(true)
                        Text("Raw Individual Debts").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    let simplifiedTx = DebtSimplifier.simplifyDebts(
                        members: members,
                        expenses: expenses,
                        settlements: settlements,
                        currency: group.defaultCurrency
                    )

                    let rawTx = DebtSimplifier.computeRawPairwiseDebts(
                        members: members,
                        expenses: expenses,
                        settlements: settlements,
                        currency: group.defaultCurrency
                    )

                    // Stat comparison
                    HStack(spacing: 16) {
                        VStack {
                            Text("\(rawTx.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Raw Transactions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.cardBackground)
                        .cornerRadius(12)

                        Image(systemName: "arrow.right")
                            .foregroundColor(ColorTheme.brandTeal)

                        VStack {
                            Text("\(simplifiedTx.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(ColorTheme.brandTeal)
                            Text("Simplified Transactions")
                                .font(.caption)
                                .foregroundColor(ColorTheme.brandTeal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.cardBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // List of transactions
                    let activeList = showingSimplifiedOnly ? simplifiedTx : rawTx

                    if activeList.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 44))
                                .foregroundColor(ColorTheme.brandTeal)
                                .padding(.top, 20)
                            Text("No Outstanding Debts!")
                                .font(.headline)
                            Text("Everyone in this group is completely settled up.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(showingSimplifiedOnly ? "Optimal Payments Plan" : "Individual Debt List")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(activeList) { tx in
                                transactionRow(tx)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(ColorTheme.viewBackground)
            .navigationTitle("Simplify Debts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.brandTeal)
                }
            }
        }
    }

    private func transactionRow(_ tx: SimplifiedTransaction) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.secondary)

            Text(tx.debtorName)
                .font(.subheadline)
                .fontWeight(.semibold)

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(ColorTheme.brandTeal)

            Text(tx.creditorName)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            Text(CurrencyFormatter.format(tx.amount, currency: tx.currency))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.brandTeal)
        }
        .padding(14)
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
}
