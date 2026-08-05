import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

public struct AccountView: View {
    @Environment(AppState.self) private var appState
    @Environment(LocalizationManager.self) private var loc
    @Environment(CloudSyncMonitor.self) private var cloudSync
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<User> { $0.isCurrentUser }) private var currentUsers: [User]

    @State private var showingProView = false
    @State private var showingResetConfirm = false
    @State private var showingShareBackup = false
    @State private var backupShareItems: [Any] = []
    @State private var showingImportPicker = false
    @State private var backupMessage: String?
    @State private var showingRestartHint = false

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

                Section {
                    Toggle(isOn: Binding(
                        get: { cloudSync.isEnabled },
                        set: { newValue in
                            cloudSync.isEnabled = newValue
                            cloudSync.needsRestartToApply = (newValue != cloudSync.isCloudKitStoreActive)
                            if cloudSync.needsRestartToApply {
                                showingRestartHint = true
                            }
                            cloudSync.refreshAccountStatus()
                        }
                    )) {
                        Label("iCloud Sync", systemImage: "icloud.fill")
                    }
                    .tint(ColorTheme.brandTeal)

                    HStack {
                        Text("Status")
                        Spacer()
                        if cloudSync.isSyncing {
                            ProgressView()
                                .padding(.trailing, 6)
                        }
                        Text(cloudSync.accountStatusText)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }

                    Text(cloudSync.statusDetail)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        cloudSync.refreshAccountStatus()
                        appState.resolveCurrentUser(from: modelContext)
                    } label: {
                        Label("Refresh Sync Status", systemImage: "arrow.triangle.2.circlepath")
                    }
                } header: {
                    Text("iCloud")
                } footer: {
                    Text("Syncs groups, expenses, settlements, and activity to your private iCloud (CloudKit) for devices signed into the same Apple ID. JSON export remains available as an offline backup.")
                }

                // BillNest Pro Banner
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
                                    Text("BillNest Pro")
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
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
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

                    Button {
                        exportBackup()
                    } label: {
                        Label("Export Local Backup (JSON)", systemImage: "externaldrive.badge.timemachine")
                    }

                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("Restore Backup (Replace All)", systemImage: "arrow.clockwise.icloud")
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
            .sheet(isPresented: $showingShareBackup) {
                #if canImport(UIKit)
                ActivityViewControllerWrapper(activityItems: backupShareItems)
                #endif
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importBackup(from: url)
                case .failure(let error):
                    backupMessage = String(localized: "Import failed: \(error.localizedDescription)")
                }
            }
            .alert("Backup", isPresented: Binding(
                get: { backupMessage != nil },
                set: { if !$0 { backupMessage = nil } }
            )) {
                Button("OK", role: .cancel) { backupMessage = nil }
            } message: {
                Text(backupMessage ?? "")
            }
            .alert("Restart Required", isPresented: $showingRestartHint) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("iCloud Sync settings apply the next time you launch BillNest. Fully quit the app, then open it again.")
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
            .onAppear {
                cloudSync.refreshAccountStatus()
            }
        }
    }

    private func exportBackup() {
        do {
            let data = try BackupManager.exportSnapshot(context: modelContext)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("BillNest-Backup.json")
            try data.write(to: url, options: .atomic)
            backupShareItems = [url]
            showingShareBackup = true
        } catch {
            backupMessage = String(localized: "Export failed: \(error.localizedDescription)")
        }
    }

    private func importBackup(from url: URL) {
        do {
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            try BackupManager.importSnapshot(data: data, context: modelContext, replaceExisting: true)
            appState.resolveCurrentUser(from: modelContext)
            backupMessage = String(localized: "Backup restored successfully.")
        } catch {
            backupMessage = String(localized: "Restore failed: \(error.localizedDescription)")
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
            backupMessage = String(localized: "Reset demo data failed: \(error.localizedDescription)")
        }
    }
    #endif
}
