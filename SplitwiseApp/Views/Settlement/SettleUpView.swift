import SwiftUI
import SwiftData

public struct SettleUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    public var group: Group?
    public var targetPayee: User?

    @Query private var users: [User]

    @State private var payerId: UUID = UUID()
    @State private var payeeId: UUID = UUID()
    @State private var amount: Double = 0.0
    @State private var currency: String = "USD"
    @State private var paymentMethod: String = "Cash"
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var saveErrorMessage: String?

    let paymentMethods = ["Cash", "PayPal", "Venmo", "Zelle", "Bank Transfer", "WeChat Pay", "Alipay"]

    private var availableUsers: [User] {
        if let g = group {
            return users.filter { g.memberIds.contains($0.id) }
        }
        return users
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Settle Up Payment") {
                    Picker("Payer", selection: $payerId) {
                        ForEach(availableUsers) { user in
                            if user.id == appState.currentUserId {
                                Text("You").tag(user.id)
                            } else {
                                Text(user.name).tag(user.id)
                            }
                        }
                    }

                    Picker("Payee", selection: $payeeId) {
                        ForEach(availableUsers.filter { $0.id != payerId }) { user in
                            if user.id == appState.currentUserId {
                                Text("You").tag(user.id)
                            } else {
                                Text(user.name).tag(user.id)
                            }
                        }
                    }

                    amountInputRow
                }

                Section("Payment Details") {
                    Picker("Method", selection: $paymentMethod) {
                        ForEach(paymentMethods, id: \.self) { method in
                            Text(LocalizedStringKey(method)).tag(method)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: [.date])

                    TextField("Notes", text: $notes)
                }

                Section {
                    Text("This records a repayment that already happened. BillNest does not send money or verify payment apps.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Record a Payment")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                setupDefaults()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettlement()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.brandTeal)
                    .disabled(amount <= 0 || payerId == payeeId)
                }
            }
            .alert("Couldn’t Save Payment", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "")
            }
        }
    }

    private var amountInputRow: some View {
        HStack {
            Text(CurrencyFormatter.symbol(for: currency))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.brandTeal)

            TextField("0.00", value: $amount, format: .number)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                #if canImport(UIKit)
                .keyboardType(.decimalPad)
                #endif

            Spacer()

            CurrencyPicker(selection: $currency)
        }
    }

    private func setupDefaults() {
        if let me = users.first(where: { $0.isCurrentUser }) {
            payerId = me.id
        }
        if let payee = targetPayee {
            payeeId = payee.id
        } else if let firstOther = availableUsers.first(where: { $0.id != payerId }) {
            payeeId = firstOther.id
        }

        if let g = group {
            currency = g.defaultCurrency
        } else {
            currency = appState.selectedCurrency
        }
    }

    private func saveSettlement() {
        let settlement = Settlement(
            payerId: payerId,
            payeeId: payeeId,
            amount: amount,
            currency: currency,
            groupId: group?.id,
            paymentMethod: paymentMethod,
            notes: notes.trimmingCharacters(in: .whitespaces),
            date: date
        )

        modelContext.insert(settlement)

        let payerUser = users.first(where: { $0.id == payerId })
        let payeeUser = users.first(where: { $0.id == payeeId })

        let log = ActivityLog(
            type: .settledUp,
            actorId: payerId,
            actorName: payerUser?.name ?? "User",
            title: "\(payerUser?.name ?? "User") paid \(payeeUser?.name ?? "User") \(CurrencyFormatter.format(amount, currency: currency))",
            details: "Payment via \(paymentMethod)",
            groupId: group?.id
        )
        modelContext.insert(log)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.delete(settlement)
            modelContext.delete(log)
            saveErrorMessage = error.localizedDescription
        }
    }
}
