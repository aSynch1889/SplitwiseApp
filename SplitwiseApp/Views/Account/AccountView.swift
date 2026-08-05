import SwiftUI
import SwiftData

public struct AccountView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<User> { $0.isCurrentUser }) private var currentUsers: [User]

    @State private var showingProView = false
    @State private var showingResetConfirm = false

    private var currentUser: User? {
        currentUsers.first
    }

    public var body: some View {
        NavigationStack {
            Form {
                // User Profile Banner
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(ColorTheme.brandTeal.opacity(0.15))
                                .frame(width: 60, height: 60)
                            Image(systemName: currentUser?.avatarName ?? "person.crop.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(ColorTheme.brandTeal)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentUser?.name ?? "Alex Johnson")
                                .font(.headline)
                            Text(currentUser?.email ?? "alex@example.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                // Splitwise Pro Banner
                Section {
                    Button {
                        showingProView = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Splitwise Pro")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    if ProSubscriptionManager.shared.isPro {
                                        Text("ACTIVE")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(ColorTheme.owedGreen)
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                    }
                                }
                                Text("Receipt OCR, Currency Rates, PDF Exports & Charts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // App Preferences Section
                Section("Preferences") {
                    HStack {
                        Label("Default Currency", systemImage: "dollarsign.circle")
                        Spacer()
                        CurrencyPicker(selection: Bindable(appState).selectedCurrency)
                    }

                    Picker(selection: Bindable(appState).colorSchemePreference) {
                        Text("System").tag("system")
                        Text("Light Mode").tag("light")
                        Text("Dark Mode").tag("dark")
                    } label: {
                        Label("Appearance", systemImage: "moon.phase.5")
                    }

                    NavigationLink {
                        LanguageSelectionView()
                    } label: {
                        HStack {
                            Label("Language", systemImage: "globe")
                            Spacer()
                            Text(loc.currentNativeName)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // App Info & Demo Data Reset
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (ASC Release Build)")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: LegalURLs.privacyPolicy(languageCode: loc.currentLanguage)) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Link(destination: LegalURLs.termsOfService(languageCode: loc.currentLanguage)) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }

                    #if DEBUG
                    Button(role: .destructive) {
                        showingResetConfirm = true
                    } label: {
                        Label("Reset Demo Sample Data", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(.red)
                    }
                    #endif
                }
            }
            .navigationTitle("Account")
            .sheet(isPresented: $showingProView) {
                SplitwiseProView()
            }
            #if DEBUG
            .confirmationDialog(
                "Reset all data and reload sample demo content?",
                isPresented: $showingResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset & Load Sample", role: .destructive) {
                    resetDemoData()
                }
                Button("Cancel", role: .cancel) {}
            }
            #endif
        }
    }

    #if DEBUG
    private func resetDemoData() {
        do {
            try modelContext.delete(model: Expense.self)
            try modelContext.delete(model: Group.self)
            try modelContext.delete(model: Settlement.self)
            try modelContext.delete(model: ActivityLog.self)
            try modelContext.delete(model: User.self)
            try modelContext.save()
            SampleData.populateIfEmpty(context: modelContext)
            appState.resolveCurrentUser(from: modelContext)
        } catch {
            print("Reset demo data failed: \(error)")
        }
    }
    #endif
}
