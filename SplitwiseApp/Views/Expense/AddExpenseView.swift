import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

public struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    public var preselectedGroup: Group? = nil
    /// When set (e.g. from FriendDetail), No Group mode is locked to this 1-on-1 friend.
    public var preselectedFriend: User? = nil

    public init(preselectedGroup: Group? = nil, preselectedFriend: User? = nil) {
        self.preselectedGroup = preselectedGroup
        self.preselectedFriend = preselectedFriend
    }

    @Query private var groups: [Group]
    @Query private var users: [User]

    @State private var title: String = ""
    @State private var amount: Double = 0.0
    @State private var currency: String = "USD"
    @State private var selectedCategory: ExpenseCategory = .general
    @State private var selectedGroupId: UUID?
    @State private var selectedFriendId: UUID?
    @State private var payerId: UUID?
    @State private var splitMethod: SplitMethod = .equal
    @State private var splits: [ExpenseSplit] = []

    @State private var receiptImageData: Data? = nil
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var repeatFrequency: RepeatFrequency = .never

    @State private var showingSplitOptions = false
    @State private var showingReceiptPicker = false
    @State private var saveErrorMessage: String?
    @State private var userCustomizedSplits = false
    @State private var pendingOCRItems: [ItemizedSplit] = []

    private var currentUser: User? {
        users.first(where: { $0.isCurrentUser })
            ?? users.first(where: { $0.id == appState.currentUserId })
    }

    private var activeGroup: Group? {
        groups.first(where: { $0.id == selectedGroupId })
    }

    /// Friends available for No Group / 1-on-1 expenses (everyone except current user).
    private var friendCandidates: [User] {
        guard let me = currentUser else { return users }
        return users.filter { $0.id != me.id }
    }

    /// Participants for the active group, or current user + optional friend for individual bills.
    private var groupMembers: [User] {
        if let g = activeGroup {
            return users.filter { g.memberIds.contains($0.id) }
        }
        guard let me = currentUser else { return [] }
        if let friendId = selectedFriendId,
           let friend = users.first(where: { $0.id == friendId }) {
            return [me, friend]
        }
        // Personal expense: only the current user.
        return [me]
    }

    private var canSave: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, amount > 0 else { return false }
        guard currentUser != nil else { return false }
        guard let payerId, groupMembers.contains(where: { $0.id == payerId }) else { return false }
        guard !splits.isEmpty else { return false }
        guard splits.allSatisfy({ split in groupMembers.contains(where: { $0.id == split.userId }) }) else { return false }
        return SplitMath.isValid(method: splitMethod, total: amount, splits: splits)
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

                // Section 2: Group / Friend & Payer Selector
                Section("Group & Payer") {
                    Picker("With Group", selection: $selectedGroupId) {
                        Text("No Group (Individual)").tag(UUID?.none)
                        ForEach(groups) { g in
                            Text(g.name).tag(UUID?.some(g.id))
                        }
                    }

                    if selectedGroupId == nil {
                        if preselectedFriend != nil {
                            LabeledContent("With Friend") {
                                Text(preselectedFriend?.name ?? "")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Picker("With Friend", selection: $selectedFriendId) {
                                Text("Just Me (Personal)").tag(UUID?.none)
                                ForEach(friendCandidates) { friend in
                                    Text(friend.name).tag(UUID?.some(friend.id))
                                }
                            }
                        }
                    }

                    Picker("Paid By", selection: Binding(
                        get: { payerId ?? currentUser?.id },
                        set: { payerId = $0 }
                    )) {
                        ForEach(groupMembers) { member in
                            if member.id == appState.currentUserId {
                                Text("You").tag(Optional(member.id))
                            } else {
                                Text(member.name).tag(Optional(member.id))
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
                        .disabled(groupMembers.isEmpty)
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
                configureInitialSelection()
                recalculateSplits()
            }
            .onChange(of: selectedGroupId) { _, newValue in
                if newValue != nil {
                    if preselectedFriend == nil {
                        selectedFriendId = nil
                    }
                }
                userCustomizedSplits = false
                ensureValidPayer()
                recalculateSplits()
            }
            .onChange(of: selectedFriendId) { _, _ in
                userCustomizedSplits = false
                ensureValidPayer()
                recalculateSplits()
            }
            .onChange(of: amount) { _, _ in
                if !userCustomizedSplits || splitMethod == .equal {
                    recalculateSplits()
                }
            }
            .onChange(of: payerId) { _, _ in
                if !userCustomizedSplits {
                    recalculateSplits()
                } else {
                    // Update paidShare only.
                    for i in splits.indices {
                        splits[i].paidShare = (splits[i].userId == payerId) ? amount : 0
                    }
                }
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
                    .disabled(!canSave)
                }
            }
            .alert("Could Not Save", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { saveErrorMessage = nil }
            } message: {
                Text(saveErrorMessage ?? "")
            }
            .sheet(isPresented: $showingSplitOptions, onDismiss: {
                userCustomizedSplits = true
            }) {
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
                    pendingOCRItems = scanned.lineItems
                    userCustomizedSplits = true
                    if scanned.lineItems.isEmpty {
                        recalculateSplits()
                    } else {
                        splits = SplitMath.applyItemizedItems(
                            scanned.lineItems,
                            to: groupMembers,
                            total: amount > 0 ? amount : scanned.totalAmount,
                            payerId: payerId ?? currentUser?.id
                        )
                    }
                }
            }
        }
    }

    private func configureInitialSelection() {
        if let g = preselectedGroup {
            selectedGroupId = g.id
            currency = g.defaultCurrency
        } else {
            currency = appState.selectedCurrency
        }

        if let friend = preselectedFriend {
            selectedGroupId = nil
            selectedFriendId = friend.id
        }

        ensureValidPayer()
    }

    private func ensureValidPayer() {
        if let payerId, groupMembers.contains(where: { $0.id == payerId }) {
            return
        }
        payerId = currentUser?.id ?? groupMembers.first?.id
    }

    private func recalculateSplits() {
        let members = groupMembers
        guard !members.isEmpty else {
            splits = []
            return
        }

        let resolvedPayer = payerId ?? currentUser?.id

        if splitMethod == .itemized, !pendingOCRItems.isEmpty {
            splits = SplitMath.applyItemizedItems(
                pendingOCRItems,
                to: members,
                total: amount,
                payerId: resolvedPayer
            )
            return
        }

        splits = SplitMath.buildEqualSplits(
            members: members,
            total: amount,
            payerId: resolvedPayer
        )
    }

    private func saveExpense() {
        guard canSave, let resolvedPayer = payerId ?? currentUser?.id else {
            saveErrorMessage = SplitMath.validationMessage(method: splitMethod, total: amount, splits: splits)
                ?? "Missing current user or payer. Please set up your profile and try again."
            return
        }

        guard groupMembers.contains(where: { $0.id == resolvedPayer }) else {
            saveErrorMessage = "Payer is not a participant of this expense."
            return
        }

        guard !splits.isEmpty else {
            saveErrorMessage = "At least one participant is required."
            return
        }

        if let message = SplitMath.validationMessage(method: splitMethod, total: amount, splits: splits) {
            saveErrorMessage = message
            return
        }

        let newExpense = Expense(
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amount,
            currency: currency,
            payerId: resolvedPayer,
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

        if let me = users.first(where: { $0.id == resolvedPayer }) {
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

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = "Failed to save expense: \(error.localizedDescription)"
        }
    }
}
