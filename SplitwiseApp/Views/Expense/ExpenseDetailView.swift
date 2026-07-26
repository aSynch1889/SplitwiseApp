import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

public struct ExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    public let expense: Expense

    @Query private var users: [User]

    @State private var showingReceiptZoom = false
    @State private var showingDeleteAlert = false

    private var payer: User? {
        users.first(where: { $0.id == expense.payerId })
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category Icon & Header
                VStack(spacing: 12) {
                    CategoryIconView(category: expense.category, size: 64)

                    Text(expense.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(CurrencyFormatter.format(expense.amount, currency: expense.currency))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(ColorTheme.brandTeal)

                    Text("Added on \(DateFormatter.localizedString(from: expense.date, dateStyle: .medium, timeStyle: .none))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(ColorTheme.cardBackground)
                .cornerRadius(16)

                // Paid By Info Card
                HStack(spacing: 14) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(ColorTheme.brandTeal)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Paid By")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(payer?.id == appState.currentUserId ? "You paid \(CurrencyFormatter.format(expense.amount, currency: expense.currency))" : "\(payer?.name ?? "Someone") paid \(CurrencyFormatter.format(expense.amount, currency: expense.currency))")
                            .font(.headline)
                    }

                    Spacer()
                }
                .padding(16)
                .background(ColorTheme.cardBackground)
                .cornerRadius(14)

                // Splits Breakdown Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Splits Breakdown (\(expense.splitMethod.rawValue))")
                            .font(.headline)
                        Spacer()
                        Text(expense.splitMethod.symbol)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.brandTeal)
                    }

                    ForEach(expense.splits) { split in
                        HStack {
                            Text(split.userName)
                                .fontWeight(.medium)
                            Spacer()
                            Text(CurrencyFormatter.format(split.amount, currency: expense.currency))
                                .fontWeight(.semibold)
                        }
                        .padding(12)
                        .background(ColorTheme.cardBackground)
                        .cornerRadius(10)
                    }
                }

                // Receipt Preview Section
                #if canImport(UIKit)
                if let data = expense.receiptImageData, let uiImage = UIImage(data: data) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Attached Receipt")
                            .font(.headline)

                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .cornerRadius(12)
                            .onTapGesture {
                                showingReceiptZoom = true
                            }
                    }
                }
                #endif

                // Notes Section
                if !expense.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(expense.notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ColorTheme.cardBackground)
                            .cornerRadius(10)
                    }
                }

                // Delete Expense Button
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Expense", systemImage: "trash")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .background(ColorTheme.viewBackground)
        .navigationTitle("Expense Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Delete Expense?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteExpense()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
        .sheet(isPresented: $showingReceiptZoom) {
            #if canImport(UIKit)
            if let data = expense.receiptImageData, let uiImage = UIImage(data: data) {
                NavigationStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .navigationTitle("Receipt Preview")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Close") { showingReceiptZoom = false }
                            }
                        }
                }
            }
            #endif
        }
    }

    private func deleteExpense() {
        modelContext.delete(expense)
        try? modelContext.save()
        dismiss()
    }
}
