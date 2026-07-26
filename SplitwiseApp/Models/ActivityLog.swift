import Foundation
import SwiftData

public enum ActivityType: String, Codable, CaseIterable {
    case addedExpense = "Added Expense"
    case updatedExpense = "Updated Expense"
    case deletedExpense = "Deleted Expense"
    case settledUp = "Settled Up"
    case createdGroup = "Created Group"
    case addedMember = "Added Member"
}

@Model
public final class ActivityLog: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var typeRaw: String
    public var actorId: UUID
    public var actorName: String
    public var title: String
    public var details: String
    public var groupId: UUID?
    public var expenseId: UUID?
    public var timestamp: Date

    public var type: ActivityType {
        get { ActivityType(rawValue: typeRaw) ?? .addedExpense }
        set { typeRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        type: ActivityType,
        actorId: UUID,
        actorName: String,
        title: String,
        details: String = "",
        groupId: UUID? = nil,
        expenseId: UUID? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.actorId = actorId
        self.actorName = actorName
        self.title = title
        self.details = details
        self.groupId = groupId
        self.expenseId = expenseId
        self.timestamp = timestamp
    }
}
