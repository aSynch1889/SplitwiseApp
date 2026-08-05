import SwiftUI
import SwiftData

public struct GroupSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    public let group: Group

    @Query private var allUsers: [User]

    @State private var groupName: String = ""
    @State private var groupType: GroupType = .home
    @State private var defaultCurrency: String = "USD"
    @State private var simplifyDebts: Bool = true
    @State private var isArchived: Bool = false

    @State private var showingAddMemberSheet = false
    @State private var newMemberName: String = ""
    @State private var newMemberEmail: String = ""
    @State private var saveErrorMessage: String?

    private var groupMembers: [User] {
        allUsers.filter { group.memberIds.contains($0.id) }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Group Name & Category") {
                    TextField("Group Name", text: $groupName)

                    Picker("Type", selection: $groupType) {
                        ForEach(GroupType.allCases) { type in
                            Label(type.rawValue, systemImage: type.iconName).tag(type)
                        }
                    }

                    HStack {
                        Text("Default Currency")
                        Spacer()
                        CurrencyPicker(selection: $defaultCurrency)
                    }
                }

                Section("Debt Options") {
                    Toggle("Simplify Group Debts", isOn: $simplifyDebts)
                        .tint(ColorTheme.brandTeal)
                }

                Section("Members (\(groupMembers.count))") {
                    ForEach(groupMembers) { member in
                        HStack {
                            Image(systemName: member.avatarName)
                                .foregroundColor(ColorTheme.brandTeal)
                            Text(member.name)
                                .fontWeight(member.isCurrentUser ? .bold : .regular)
                            if member.isCurrentUser {
                                Text("(You)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }

                    Button {
                        showingAddMemberSheet = true
                    } label: {
                        Label("Add Member to Group", systemImage: "person.badge.plus")
                            .foregroundColor(ColorTheme.brandTeal)
                    }
                }

                Section {
                    Toggle("Archive Group", isOn: $isArchived)
                        .tint(.orange)
                } header: {
                    Text("Archive")
                } footer: {
                    Text("Archived groups move to the Archived tab and hide active balance alerts.")
                }
            }
            .navigationTitle("Group Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                groupName = group.name
                groupType = group.groupType
                defaultCurrency = group.defaultCurrency
                simplifyDebts = group.simplifyDebts
                isArchived = group.isArchived
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.brandTeal)
                }
            }
            .alert("Add New Member", isPresented: $showingAddMemberSheet) {
                TextField("Member Name", text: $newMemberName)
                TextField("Member Email (optional)", text: $newMemberEmail)
                Button("Add") {
                    addMemberToGroup()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Couldn’t Save Changes", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "")
            }
        }
    }

    private func addMemberToGroup() {
        let name = newMemberName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let newUser = User(
            name: name,
            email: newMemberEmail.trimmingCharacters(in: .whitespaces),
            avatarName: "person.circle.fill"
        )
        modelContext.insert(newUser)
        group.memberIds.append(newUser.id)

        newMemberName = ""
        newMemberEmail = ""

        do {
            try modelContext.save()
        } catch {
            group.memberIds.removeAll { $0 == newUser.id }
            modelContext.delete(newUser)
            saveErrorMessage = error.localizedDescription
        }
    }

    private func saveChanges() {
        let previousName = group.name
        let previousType = group.groupType
        let previousCurrency = group.defaultCurrency
        let previousSimplify = group.simplifyDebts
        let previousArchived = group.isArchived

        group.name = groupName.trimmingCharacters(in: .whitespaces)
        group.groupType = groupType
        group.defaultCurrency = defaultCurrency
        group.simplifyDebts = simplifyDebts
        group.isArchived = isArchived

        do {
            try modelContext.save()
            dismiss()
        } catch {
            group.name = previousName
            group.groupType = previousType
            group.defaultCurrency = previousCurrency
            group.simplifyDebts = previousSimplify
            group.isArchived = previousArchived
            saveErrorMessage = error.localizedDescription
        }
    }
}
