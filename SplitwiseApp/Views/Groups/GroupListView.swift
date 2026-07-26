import SwiftUI
import SwiftData

public struct GroupListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @Query(sort: \Group.createdAt, order: .reverse) private var groups: [Group]
    @Query private var expenses: [Expense]
    @Query private var settlements: [Settlement]
    @Query private var users: [User]

    @State private var showingCreateGroup = false
    @State private var selectedFilter: GroupFilter = .active

    enum GroupFilter: String, CaseIterable, Identifiable {
        case active = "Active"
        case archived = "Archived"
        public var id: String { rawValue }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Overall Balance Header Card
                    overallBalanceCard

                    // Filter picker
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(GroupFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Groups List
                    let filteredGroups = groups.filter {
                        selectedFilter == .active ? !$0.isArchived : $0.isArchived
                    }

                    if filteredGroups.isEmpty {
                        emptyGroupState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredGroups) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    groupRow(group)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(ColorTheme.viewBackground)
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateGroup = true
                    } label: {
                        Label("New Group", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(ColorTheme.brandTeal)
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
        }
    }

    // MARK: - Overall Balance Card
    private var overallBalanceCard: some View {
        let totalNet = calculateOverallNetBalance()

        return VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if totalNet > 0.009 {
                        Text("You are owed \(CurrencyFormatter.format(totalNet, currency: appState.selectedCurrency)) overall")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.owedGreen)
                    } else if totalNet < -0.009 {
                        Text("You owe \(CurrencyFormatter.format(abs(totalNet), currency: appState.selectedCurrency)) overall")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.owesOrange)
                    } else {
                        Text("You are all settled up!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 38))
                    .foregroundColor(ColorTheme.brandTeal)
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        .padding(.horizontal)
    }

    private func groupRow(_ group: Group) -> some View {
        let groupExpenses = expenses.filter { $0.groupId == group.id }
        let groupSettlements = settlements.filter { $0.groupId == group.id }
        let groupMembers = users.filter { group.memberIds.contains($0.id) }

        let balances = DebtSimplifier.calculateNetBalances(
            members: groupMembers,
            expenses: groupExpenses,
            settlements: groupSettlements
        )
        let myNet = balances[appState.currentUserId] ?? 0.0

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ColorTheme.brandTeal.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: group.groupType.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(ColorTheme.brandTeal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Label("\(group.memberIds.count) members", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if group.simplifyDebts {
                        Text("• Simplify On")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.brandTeal)
                            .fontWeight(.semibold)
                    }
                }
            }

            Spacer()

            BalanceBadge(amount: myNet, currency: group.defaultCurrency)
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(14)
    }

    private var emptyGroupState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 54))
                .foregroundColor(ColorTheme.brandTeal.opacity(0.6))
                .padding(.top, 40)

            Text("No Groups Yet")
                .font(.title3)
                .fontWeight(.bold)

            Text("Create a group to start splitting bills for trips, housemates, or events.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingCreateGroup = true
            } label: {
                Text("Create First Group")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(ColorTheme.brandTeal)
                    .cornerRadius(12)
            }
        }
    }

    private func calculateOverallNetBalance() -> Double {
        let balances = DebtSimplifier.calculateNetBalances(
            members: users,
            expenses: expenses,
            settlements: settlements
        )
        return balances[appState.currentUserId] ?? 0.0
    }
}
