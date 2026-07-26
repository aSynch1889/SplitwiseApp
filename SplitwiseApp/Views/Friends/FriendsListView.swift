import SwiftUI
import SwiftData

public struct FriendsListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query private var users: [User]
    @Query private var expenses: [Expense]
    @Query private var settlements: [Settlement]

    @State private var showingAddFriend = false
    @State private var searchText = ""

    private var friends: [User] {
        users.filter { !$0.isCurrentUser }
    }

    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.email.localizedCaseInsensitiveContains(searchText) }
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if friends.isEmpty {
                        emptyFriendsState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFriends) { friend in
                                NavigationLink(destination: FriendDetailView(friend: friend)) {
                                    friendRow(friend)
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
            .searchable(text: $searchText, prompt: "Search friends by name or email")
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddFriend = true
                    } label: {
                        Label("Add Friend", systemImage: "person.badge.plus")
                            .font(.headline)
                            .foregroundColor(ColorTheme.brandTeal)
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView()
            }
        }
    }

    private func friendRow(_ friend: User) -> some View {
        let net = calculateNetWithFriend(friend)

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(ColorTheme.brandTeal.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: friend.avatarName)
                    .font(.system(size: 24))
                    .foregroundColor(ColorTheme.brandTeal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                if !friend.email.isEmpty {
                    Text(friend.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            BalanceBadge(amount: net, currency: appState.selectedCurrency)
        }
        .padding(14)
        .background(ColorTheme.cardBackground)
        .cornerRadius(14)
    }

    private var emptyFriendsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 54))
                .foregroundColor(ColorTheme.brandTeal.opacity(0.6))
                .padding(.top, 40)

            Text("No Friends Added")
                .font(.title3)
                .fontWeight(.bold)

            Text("Add friends to split bills directly without creating a group.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingAddFriend = true
            } label: {
                Text("Add a Friend")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(ColorTheme.brandTeal)
                    .cornerRadius(12)
            }
        }
    }

    private func calculateNetWithFriend(_ friend: User) -> Double {
        var net: Double = 0.0
        let myId = appState.currentUserId

        for expense in expenses {
            let payerId = expense.payerId
            let splits = expense.splits

            if payerId == myId {
                // I paid
                if let friendSplit = splits.first(where: { $0.userId == friend.id }) {
                    net += friendSplit.amount
                }
            } else if payerId == friend.id {
                // Friend paid
                if let mySplit = splits.first(where: { $0.userId == myId }) {
                    net -= mySplit.amount
                }
            }
        }

        for settlement in settlements {
            if settlement.payerId == myId && settlement.payeeId == friend.id {
                net += settlement.amount
            } else if settlement.payerId == friend.id && settlement.payeeId == myId {
                net -= settlement.amount
            }
        }

        return net
    }
}
