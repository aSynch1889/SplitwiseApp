import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

public struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    public var preselectedGroup: Group?

    @Query private var groups: [Group]
    @Query private var users: [User]

    @State private var title: String = ""
    @State private var amount: Double = 0.0
    @State private var currency: String = "USD"
    @State private var selectedCategory: ExpenseCategory = .general
    @State private var selectedGroupId: UUID?
    @State private var payerId: UUID = UUID()
    @State private var splitMethod: SplitMethod = .equal
    @State private var splits: [ExpenseSplit] = []

    @State private var receiptImageData: Data? = nil
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var repeatFrequency: RepeatFrequency = .never

    @State private var showingSplitOptions = false
    @State private var showingReceiptPicker = false

    private var activeGroup: Group? {
        groups.first(where: { $0.id == selectedGroupId })
    }

    private var groupMembers: [User] {
        if let g = activeGroup {
            return users.filter { g.memberIds.contains($0.id) }
        }
        return users
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Title, Amount, Currency & Category
                Section {
                    HStack(spacing: 12) {
                        CategoryIconView(category: selectedCategory, size: 44)

                        TextField("Expense Description (e.g. Dinner)", text: $title)
                            .font(.headline)
                    }

                    HStack {
                        Text(CurrencyFormatter.symbol(for: currency))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.brandTeal)

                        TextField("0.00", value: $amount, format: .number)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            #if canImport(UIKit)
                            .keyboardType(.decimalPad)
                            #endif

                        Spacer()

                        CurrencyPicker(selection: $currency)
                    }

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Label(LocalizedStringKey(category.rawValue), systemImage: category.iconName).tag(category)
                        }
                    }
                }

                // Section 2: Group & Payer Selector
                Section("Group & Payer") {
                    Picker("With Group", selection: $selectedGroupId) {
                        Text("No Group (Individual)").tag(UUID?.none)
                        ForEach(groups) { g in
                            Text(g.name).tag(UUID?.some(g.id))
                        }
                    }

                    Picker("Paid By", selection: $payerId) {
                        ForEach(groupMembers) { member in
                            if member.id == appState.currentUserId {
                                Text("You").tag(member.id)
                            } else {
                                Text(member.name).tag(member.id)
                            }
                        }
                    }
                }

                // Section 3: Split Options Mode & Summary
                Section("Split Breakdown") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Split Method: \(splitMethod.rawValue) (\(splitMethod.symbol))")
                                .fontWeight(.medium)
                            Text("\(splits.count) people sharing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Options") {
                            showingSplitOptions = true
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.brandTeal)
                    }

                    ForEach(splits) { split in
                        HStack {
                            Text(split.userName)
                                .font(.subheadline)
                            Spacer()
                            Text(CurrencyFormatter.format(split.amount, currency: currency))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }

                // Section 4: Receipt Attachment & OCR Scanner
                Section("Receipt & Attachments") {
                    HStack {
                        #if canImport(UIKit)
                        if let data = receiptImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)
                                .clipped()
                            Text("Receipt Attached")
                                .fontWeight(.medium)
                        } else {
                            Label("Scan / Attach Receipt", systemImage: "camera.fill")
                                .foregroundColor(ColorTheme.brandTeal)
                        }
                        #else
                        Label("Scan / Attach Receipt", systemImage: "camera.fill")
                            .foregroundColor(ColorTheme.brandTeal)
                        #endif
                        Spacer()
                        Button(receiptImageData == nil ? "Attach" : "Change") {
                            showingReceiptPicker = true
                        }
                    }
                }

                // Section 5: Date, Notes & Repeat
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])

                    Picker("Repeat", selection: $repeatFrequency) {
                        ForEach(RepeatFrequency.allCases) { freq in
                            Text(LocalizedStringKey(freq.rawValue)).tag(freq)
                        }
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Expense")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                if let g = preselectedGroup {
                    selectedGroupId = g.id
                    currency = g.defaultCurrency
                } else {
                    currency = appState.selectedCurrency
                }

                if let me = users.first(where: { $0.isCurrentUser }) {
                    payerId = me.id
                }

                recalculateSplits()
            }
            .onChange(of: selectedGroupId) { _, _ in
                recalculateSplits()
            }
            .onChange(of: amount) { _, _ in
                recalculateSplits()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.brandTeal)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || amount <= 0)
                }
            }
            .sheet(isPresented: $showingSplitOptions) {
                SplitOptionsView(
                    totalAmount: amount,
                    currency: currency,
                    members: groupMembers,
                    splitMethod: $splitMethod,
                    splits: $splits
                )
            }
            .sheet(isPresented: $showingReceiptPicker) {
                ReceiptPickerView(selectedImageData: $receiptImageData) { scanned in
                    if title.isEmpty {
                        title = scanned.title
                    }
                    if amount == 0 {
                        amount = scanned.totalAmount
                    }
                    splitMethod = .itemized
                    recalculateSplits()
                }
            }
        }
    }

    private func recalculateSplits() {
        let count = Double(max(1, groupMembers.count))
        let equalShare = amount / count

        splits = groupMembers.map { member in
            let isPayer = (member.id == payerId)
            return ExpenseSplit(
                userId: member.id,
                userName: member.name,
                amount: equalShare,
                percentage: (100.0 / count),
                shares: 1,
                paidShare: isPayer ? amount : 0.0
            )
        }
    }

    private func saveExpense() {
        let newExpense = Expense(
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amount,
            currency: currency,
            payerId: payerId,
            groupId: selectedGroupId,
            splitMethod: splitMethod,
            category: selectedCategory,
            splits: splits,
            receiptImageData: receiptImageData,
            notes: notes.trimmingCharacters(in: .whitespaces),
            date: date,
            repeatFrequency: repeatFrequency
        )

        modelContext.insert(newExpense)

        if let me = users.first(where: { $0.id == payerId }) {
            let log = ActivityLog(
                type: .addedExpense,
                actorId: me.id,
                actorName: me.name,
                title: "\(me.name) added \"\(newExpense.title)\"",
                details: "\(CurrencyFormatter.format(amount, currency: currency))",
                groupId: selectedGroupId,
                expenseId: newExpense.id
            )
            modelContext.insert(log)
        }

        try? modelContext.save()
        dismiss()
    }
}
