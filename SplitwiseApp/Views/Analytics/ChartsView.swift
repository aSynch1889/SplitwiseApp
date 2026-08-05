import SwiftUI
import SwiftData
import Charts

public struct ChartsView: View {
    @Environment(AppState.self) private var appState
    @Query private var expenses: [Expense]
    @Query private var groups: [Group]

    @State private var selectedTimeframe: Timeframe = .thisMonth

    enum Timeframe: String, CaseIterable, Identifiable {
        case thisMonth = "This Month"
        case last3Months = "3 Months"
        case allTime = "All Time"
        public var id: String { rawValue }
    }

    private struct MonthBucket: Identifiable {
        let id: String
        let sortKey: Date
        let label: String
        let amount: Double
    }

    public var body: some View {
        NavigationStack {
            Group {
                if ProAccess.isPro {
                    ScrollView {
                        VStack(spacing: 20) {
                            Picker("Timeframe", selection: $selectedTimeframe) {
                                ForEach(Timeframe.allCases) { tf in
                                    Text(tf.rawValue).tag(tf)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            totalSpentCard
                            categoryPieChartCard
                            monthlyTrendChartCard
                            groupBarChartCard
                        }
                        .padding(.vertical)
                    }
                } else {
                    proLockedPlaceholder
                }
            }
            .background(ColorTheme.viewBackground)
            .navigationTitle("Analytics & Charts")
            .toolbar {
                if !ProAccess.isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProBadge()
                    }
                }
            }
        }
    }

    private var proLockedPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(ColorTheme.brandTeal)
            Text("Advanced Charts are Pro")
                .font(.title3)
                .fontWeight(.bold)
            Text(ProFeature.advancedCharts.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                PaywallPresenter.shared.present(for: .advancedCharts)
            } label: {
                Label("Unlock with Pro", systemImage: "crown.fill")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(ColorTheme.brandTeal)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Current user's share of expenses in the selected timeframe, converted to app currency.
    private var myShareTotal: Double {
        filteredExpenses.reduce(0.0) { partial, expense in
            let myShare = expense.splits.first(where: { $0.userId == appState.currentUserId })?.amount ?? 0
            return partial + CurrencyFormatter.convert(
                amount: myShare,
                from: expense.currency,
                to: appState.selectedCurrency
            )
        }
    }

    private var totalSpentCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Share of Spending")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(CurrencyFormatter.format(myShareTotal, currency: appState.selectedCurrency))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(ColorTheme.brandTeal)

            Text("Amounts converted to \(appState.selectedCurrency) using in-app static rates.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var categoryPieChartCard: some View {
        let categoryTotals = Dictionary(grouping: filteredExpenses, by: { $0.category })
            .mapValues { items in
                items.reduce(0.0) { partial, expense in
                    let myShare = expense.splits.first(where: { $0.userId == appState.currentUserId })?.amount ?? 0
                    return partial + CurrencyFormatter.convert(
                        amount: myShare,
                        from: expense.currency,
                        to: appState.selectedCurrency
                    )
                }
            }
            .sorted { $0.value > $1.value }

        return VStack(alignment: .leading, spacing: 14) {
            Text("Your Share by Category")
                .font(.headline)

            if categoryTotals.isEmpty {
                Text("No spending data for this timeframe.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Chart(categoryTotals, id: \.key) { category, amount in
                    SectorMark(
                        angle: .value("Amount", amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Category", category.rawValue))
                }
                .frame(height: 220)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(categoryTotals, id: \.key) { category, amount in
                        HStack {
                            CategoryIconView(category: category, size: 24)
                            Text(category.rawValue)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(CurrencyFormatter.format(amount, currency: appState.selectedCurrency))
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var monthlyTrendChartCard: some View {
        let monthlyData = computeMonthlyData()

        return VStack(alignment: .leading, spacing: 14) {
            Text("Monthly Trend (Your Share)")
                .font(.headline)

            if monthlyData.isEmpty {
                Text("No monthly data available.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Chart(monthlyData) { item in
                    LineMark(
                        x: .value("Month", item.label),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(ColorTheme.brandTeal)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Month", item.label),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(ColorTheme.brandTeal.opacity(0.15))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Month", item.label),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(ColorTheme.brandTeal)
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var groupBarChartCard: some View {
        let groupTotals = Dictionary(grouping: filteredExpenses, by: { $0.groupId })
            .map { (groupId, items) -> (name: String, amount: Double) in
                let groupName = groups.first(where: { $0.id == groupId })?.name ?? "No Group"
                let amount = items.reduce(0.0) { partial, expense in
                    let myShare = expense.splits.first(where: { $0.userId == appState.currentUserId })?.amount ?? 0
                    return partial + CurrencyFormatter.convert(
                        amount: myShare,
                        from: expense.currency,
                        to: appState.selectedCurrency
                    )
                }
                return (groupName, amount)
            }
            .sorted { $0.amount > $1.amount }

        return VStack(alignment: .leading, spacing: 14) {
            Text("Your Share by Group")
                .font(.headline)

            if groupTotals.isEmpty {
                Text("No group spending data available.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Chart(groupTotals, id: \.name) { item in
                    BarMark(
                        x: .value("Group", item.name),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(ColorTheme.brandTeal)
                    .cornerRadius(6)
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private var filteredExpenses: [Expense] {
        let now = Date()
        let cal = Calendar.current

        switch selectedTimeframe {
        case .thisMonth:
            return expenses.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .last3Months:
            if let limit = cal.date(byAdding: .month, value: -3, to: now) {
                return expenses.filter { $0.date >= limit }
            }
            return expenses
        case .allTime:
            return expenses
        }
    }

    private func computeMonthlyData() -> [MonthBucket] {
        let cal = Calendar.current
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "MMM yyyy"

        let grouped = Dictionary(grouping: filteredExpenses) { expense -> Date in
            let comps = cal.dateComponents([.year, .month], from: expense.date)
            return cal.date(from: comps) ?? expense.date
        }

        return grouped.map { (monthStart, items) in
            let amount = items.reduce(0.0) { partial, expense in
                let myShare = expense.splits.first(where: { $0.userId == appState.currentUserId })?.amount ?? 0
                return partial + CurrencyFormatter.convert(
                    amount: myShare,
                    from: expense.currency,
                    to: appState.selectedCurrency
                )
            }
            return MonthBucket(
                id: labelFormatter.string(from: monthStart),
                sortKey: monthStart,
                label: labelFormatter.string(from: monthStart),
                amount: amount
            )
        }
        .sorted { $0.sortKey < $1.sortKey }
    }
}
