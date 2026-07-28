import SwiftUI
import SwiftData

public struct ActivityFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityLog.timestamp, order: .reverse) private var activities: [ActivityLog]

    @State private var searchText = ""
    @State private var selectedTypeFilter: ActivityType? = nil

    private var filteredActivities: [ActivityLog] {
        activities.filter { log in
            let matchesSearch = searchText.isEmpty || log.title.localizedCaseInsensitiveContains(searchText) || log.details.localizedCaseInsensitiveContains(searchText)
            let matchesType = (selectedTypeFilter == nil) || log.type == selectedTypeFilter
            return matchesSearch && matchesType
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Type Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button {
                                selectedTypeFilter = nil
                            } label: {
                                Text("All Activity")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedTypeFilter == nil ? ColorTheme.brandTeal : ColorTheme.cardBackground)
                                    .foregroundColor(selectedTypeFilter == nil ? .white : .primary)
                                    .cornerRadius(20)
                            }

                            ForEach(ActivityType.allCases, id: \.self) { type in
                                Button {
                                    selectedTypeFilter = type
                                } label: {
                                    Text(LocalizedStringKey(type.rawValue))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedTypeFilter == type ? ColorTheme.brandTeal : ColorTheme.cardBackground)
                                        .foregroundColor(selectedTypeFilter == type ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    if filteredActivities.isEmpty {
                        emptyActivityState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredActivities) { log in
                                activityRow(log)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(ColorTheme.viewBackground)
            .searchable(text: $searchText, prompt: "Search activity log")
            .navigationTitle("Activity")
        }
    }

    private func activityRow(_ log: ActivityLog) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(activityColor(log.type).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: activityIcon(log.type))
                    .foregroundColor(activityColor(log.type))
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(log.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if !log.details.isEmpty {
                    Text(log.details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(DateFormatter.localizedString(from: log.timestamp, dateStyle: .short, timeStyle: .short))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }

    private var emptyActivityState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 44))
                .foregroundColor(ColorTheme.brandTeal.opacity(0.4))
                .padding(.top, 40)

            Text("No Activity Recorded")
                .font(.headline)

            Text("Expense updates, group creations, and settlements will appear in this timeline feed.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }

    private func activityIcon(_ type: ActivityType) -> String {
        switch type {
        case .addedExpense: return "plus.circle.fill"
        case .updatedExpense: return "pencil.circle.fill"
        case .deletedExpense: return "trash.circle.fill"
        case .settledUp: return "checkmark.circle.fill"
        case .createdGroup: return "folder.fill.badge.plus"
        case .addedMember: return "person.badge.plus"
        }
    }

    private func activityColor(_ type: ActivityType) -> Color {
        switch type {
        case .addedExpense, .settledUp, .createdGroup: return ColorTheme.brandTeal
        case .updatedExpense, .addedMember: return .orange
        case .deletedExpense: return .red
        }
    }
}
