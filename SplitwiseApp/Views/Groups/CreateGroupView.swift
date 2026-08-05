import SwiftUI
import SwiftData

public struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query private var existingUsers: [User]

    @State private var groupName: String = ""
    @State private var selectedGroupType: GroupType = .home
    @State private var selectedCurrency: String = "USD"
    @State private var simplifyDebts: Bool = true
    @State private var selectedMemberIds: Set<UUID> = []

    @State private var newMemberName: String = ""
    @State private var newMemberEmail: String = ""
    @State private var saveErrorMessage: String?

    public var body: some View {
        NavigationStack {
            Form {
                Section("Group Info") {
                    TextField("Group Name (e.g. Summer Vacation)", text: $groupName)

                    Picker("Group Type", selection: $selectedGroupType) {
                        ForEach(GroupType.allCases) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type)
                        }
                    }

                    HStack {
                        Text("Group Currency")
                        Spacer()
                        CurrencyPicker(selection: $selectedCurrency)
                    }
                }

                Section {
                    Toggle(isOn: $simplifyDebts) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Simplify Group Debts")
                                .fontWeight(.medium)
                            Text("Automatically combines debts to minimize the total number of transactions.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(ColorTheme.brandTeal)
                }

                Section("Group Members") {
                    ForEach(existingUsers) { user in
                        HStack {
                            Image(systemName: user.avatarName)
                                .foregroundColor(ColorTheme.brandTeal)
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .fontWeight(user.isCurrentUser ? .bold : .regular)
                                if !user.email.isEmpty {
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if user.isCurrentUser {
                                Text("You")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(ColorTheme.brandTeal.opacity(0.15))
                                    .foregroundColor(ColorTheme.brandTeal)
                                    .cornerRadius(6)
                            } else {
                                Image(systemName: selectedMemberIds.contains(user.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedMemberIds.contains(user.id) ? ColorTheme.brandTeal : .secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !user.isCurrentUser {
                                if selectedMemberIds.contains(user.id) {
                                    selectedMemberIds.remove(user.id)
                                } else {
                                    selectedMemberIds.insert(user.id)
                                }
                            }
                        }
                    }
                }

                Section("Add New Member") {
                    HStack {
                        TextField("Name", text: $newMemberName)
                        TextField("Email (optional)", text: $newMemberEmail)
                            #if canImport(UIKit)
                            .keyboardType(.emailAddress)
                            #endif
                        Button("Add") {
                            addNewMember()
                        }
                        .disabled(newMemberName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("New Group")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                if let me = existingUsers.first(where: { $0.isCurrentUser }) {
                    selectedMemberIds.insert(me.id)
                }
                selectedCurrency = appState.selectedCurrency
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        saveGroup()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.brandTeal)
                    .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Couldn’t Create Group", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "")
            }
        }
    }

    private func addNewMember() {
        let name = newMemberName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let newUser = User(
            name: name,
            email: newMemberEmail.trimmingCharacters(in: .whitespaces),
            avatarName: "person.circle.fill"
        )
        modelContext.insert(newUser)
        selectedMemberIds.insert(newUser.id)

        newMemberName = ""
        newMemberEmail = ""
    }

    private func saveGroup() {
        if let me = existingUsers.first(where: { $0.isCurrentUser }) {
            selectedMemberIds.insert(me.id)
        }

        let newGroup = Group(
            name: groupName.trimmingCharacters(in: .whitespaces),
            groupType: selectedGroupType,
            memberIds: Array(selectedMemberIds),
            defaultCurrency: selectedCurrency,
            simplifyDebts: simplifyDebts
        )

        modelContext.insert(newGroup)

        var createdLog: ActivityLog?
        if let me = existingUsers.first(where: { $0.isCurrentUser }) {
            let log = ActivityLog(
                type: .createdGroup,
                actorId: me.id,
                actorName: me.name,
                title: "\(me.name) created group \"\(newGroup.name)\"",
                groupId: newGroup.id
            )
            modelContext.insert(log)
            createdLog = log
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.delete(newGroup)
            if let createdLog {
                modelContext.delete(createdLog)
            }
            saveErrorMessage = error.localizedDescription
        }
    }
}
