import Foundation

/// Represents how much a specific user pays or owes for an expense.
public struct ExpenseSplit: Codable, Identifiable, Hashable {
    public var id: UUID
    public var userId: UUID
    public var userName: String
    public var amount: Double
    public var percentage: Double
    public var shares: Int
    public var paidShare: Double // Amount this user directly paid upfront
    public var itemizedItems: [ItemizedSplit]? // Itemized items assigned to this user

    public init(
        id: UUID = UUID(),
        userId: UUID,
        userName: String,
        amount: Double = 0.0,
        percentage: Double = 0.0,
        shares: Int = 1,
        paidShare: Double = 0.0,
        itemizedItems: [ItemizedSplit]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.amount = amount
        self.percentage = percentage
        self.shares = shares
        self.paidShare = paidShare
        self.itemizedItems = itemizedItems
    }
}

public struct ItemizedSplit: Codable, Identifiable, Hashable {
    public var id: UUID
    public var title: String
    public var price: Double

    public init(id: UUID = UUID(), title: String, price: Double) {
        self.id = id
        self.title = title
        self.price = price
    }
}
