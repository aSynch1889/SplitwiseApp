import SwiftUI
import SwiftData

public struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""

    public var body: some View {
        NavigationStack {
            Form {
                Section("Friend Details") {
                    TextField("Full Name", text: $name)
                    
                    #if canImport(UIKit)
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone Number (optional)", text: $phone)
                        .keyboardType(.phonePad)
                    #else
                    TextField("Email Address", text: $email)
                    TextField("Phone Number (optional)", text: $phone)
                    #endif
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(ColorTheme.brandTeal)
                            Text("Local Contact")
                                .fontWeight(.semibold)
                        }
                        Text("Friends are stored only on this device as local participants for splitting expenses. There is no cloud invite or multi-user sync in this version.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Friend")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFriend()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.brandTeal)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveFriend() {
        let friend = User(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            phone: phone.trimmingCharacters(in: .whitespaces),
            avatarName: "person.circle.fill"
        )
        modelContext.insert(friend)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Keep sheet open so the user can retry.
            print("Failed to save friend: \(error)")
        }
    }
}
