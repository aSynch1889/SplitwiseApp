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

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Timeframe Selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases) { tf in
                            Text(tf.rawValue).tag(tf)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Total Spent Headline Card
                    totalSpentCard

                    // Chart 1: Category Breakdown (SectorMark / Pie Chart)
                    categoryPieChartCard

                    // Chart 2: Monthly Spend Trend (LineMark & PointMark)
                    monthlyTrendChartCard

                    // Chart 3: Group Spending Comparison (BarMark)
                    groupBarChartCard
                }
                .padding(.vertical)
            }
            .background(ColorTheme.viewBackground)
            .navigationTitle("Analytics & Charts")
        }
    }

    private var totalSpentCard: some View {
        let total = filteredExpenses.reduce(0.0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 6) {
            Text("Total Spending")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(CurrencyFormatter.format(total, currency: appState.selectedCurrency))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(ColorTheme.brandTeal)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Category Donut / Pie Chart
    private var categoryPieChartCard: some View {
        let categoryTotals = Dictionary(grouping: filteredExpenses, by: { $0.category })
            .mapValues { expenses in expenses.reduce(0.0) { $0 + $1.amount } }
            .sorted { $0.value > $1.value }

        return VStack(alignment: .leading, spacing: 14) {
            Text("Category Breakdown")
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

    // MARK: - Monthly Trend Chart
    private var monthlyTrendChartCard: some View {
        let monthlyData = computeMonthlyData()

        return VStack(alignment: .leading, spacing: 14) {
            Text("Monthly Spend Trend")
                .font(.headline)

            if monthlyData.isEmpty {
                Text("No monthly data available.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Chart(monthlyData, id: \.month) { item in
                    LineMark(
                        x: .value("Month", item.month),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(ColorTheme.brandTeal)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Month", item.month),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(ColorTheme.brandTeal.opacity(0.15))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Month", item.month),
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

    // MARK: - Group Bar Chart
    private var groupBarChartCard: some View {
        let groupTotals = Dictionary(grouping: filteredExpenses, by: { $0.groupId })
            .map { (groupId, items) -> (name: String, amount: Double) in
                let groupName = groups.first(where: { $0.id == groupId })?.name ?? "No Group"
                return (groupName, items.reduce(0.0) { $0 + $1.amount })
            }
            .sorted { $0.amount > $1.amount }

        return VStack(alignment: .leading, spacing: 14) {
            Text("Spending by Group")
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

    private func computeMonthlyData() -> [(month: String, amount: Double)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"

        let grouped = Dictionary(grouping: expenses) { expense -> String in
            dateFormatter.string(from: expense.date)
        }

        return grouped.map { (month, items) in
            (month, items.reduce(0.0) { $0 + $1.amount })
        }.sorted { $0.month < $1.month }
    }
}
