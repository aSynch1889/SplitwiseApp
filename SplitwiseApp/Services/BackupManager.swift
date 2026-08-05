import Foundation
import SwiftData

/// Local JSON backup / restore for offline data (no iCloud account required).
public enum BackupManager {
    public struct Snapshot: Codable {
        public var version: Int
        public var exportedAt: Date
        public var users: [UserDTO]
        public var groups: [GroupDTO]
        public var expenses: [ExpenseDTO]
        public var settlements: [SettlementDTO]
        public var activities: [ActivityDTO]
    }

    public struct UserDTO: Codable {
        public var id: UUID
        public var name: String
        public var email: String
        public var phone: String
        public var avatarName: String
        public var defaultCurrency: String
        public var isCurrentUser: Bool
        public var createdAt: Date
    }

    public struct GroupDTO: Codable {
        public var id: UUID
        public var name: String
        public var groupTypeRaw: String
        public var coverImageName: String
        public var memberIds: [UUID]
        public var defaultCurrency: String
        public var simplifyDebts: Bool
        public var isArchived: Bool
        public var createdAt: Date
    }

    public struct ExpenseDTO: Codable {
        public var id: UUID
        public var title: String
        public var amount: Double
        public var currency: String
        public var payerId: UUID
        public var groupId: UUID?
        public var splitMethodRaw: String
        public var categoryRaw: String
        public var splits: [ExpenseSplit]
        public var notes: String
        public var date: Date
        public var repeatFrequencyRaw: String
        public var createdAt: Date
    }

    public struct SettlementDTO: Codable {
        public var id: UUID
        public var payerId: UUID
        public var payeeId: UUID
        public var amount: Double
        public var currency: String
        public var groupId: UUID?
        public var paymentMethod: String
        public var notes: String
        public var date: Date
    }

    public struct ActivityDTO: Codable {
        public var id: UUID
        public var typeRaw: String
        public var actorId: UUID
        public var actorName: String
        public var title: String
        public var details: String
        public var groupId: UUID?
        public var expenseId: UUID?
        public var timestamp: Date
    }

    @MainActor
    public static func exportSnapshot(context: ModelContext) throws -> Data {
        let users = try context.fetch(FetchDescriptor<User>())
        let groups = try context.fetch(FetchDescriptor<Group>())
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        let settlements = try context.fetch(FetchDescriptor<Settlement>())
        let activities = try context.fetch(FetchDescriptor<ActivityLog>())

        let snapshot = Snapshot(
            version: 1,
            exportedAt: Date(),
            users: users.map {
                UserDTO(
                    id: $0.id, name: $0.name, email: $0.email, phone: $0.phone,
                    avatarName: $0.avatarName, defaultCurrency: $0.defaultCurrency,
                    isCurrentUser: $0.isCurrentUser, createdAt: $0.createdAt
                )
            },
            groups: groups.map {
                GroupDTO(
                    id: $0.id, name: $0.name, groupTypeRaw: $0.groupTypeRaw,
                    coverImageName: $0.coverImageName, memberIds: $0.memberIds,
                    defaultCurrency: $0.defaultCurrency, simplifyDebts: $0.simplifyDebts,
                    isArchived: $0.isArchived, createdAt: $0.createdAt
                )
            },
            expenses: expenses.map {
                ExpenseDTO(
                    id: $0.id, title: $0.title, amount: $0.amount, currency: $0.currency,
                    payerId: $0.payerId, groupId: $0.groupId, splitMethodRaw: $0.splitMethodRaw,
                    categoryRaw: $0.categoryRaw, splits: $0.splits, notes: $0.notes,
                    date: $0.date, repeatFrequencyRaw: $0.repeatFrequencyRaw, createdAt: $0.createdAt
                )
            },
            settlements: settlements.map {
                SettlementDTO(
                    id: $0.id, payerId: $0.payerId, payeeId: $0.payeeId, amount: $0.amount,
                    currency: $0.currency, groupId: $0.groupId, paymentMethod: $0.paymentMethod,
                    notes: $0.notes, date: $0.date
                )
            },
            activities: activities.map {
                ActivityDTO(
                    id: $0.id, typeRaw: $0.typeRaw, actorId: $0.actorId, actorName: $0.actorName,
                    title: $0.title, details: $0.details, groupId: $0.groupId,
                    expenseId: $0.expenseId, timestamp: $0.timestamp
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    @MainActor
    public static func importSnapshot(data: Data, context: ModelContext, replaceExisting: Bool) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(Snapshot.self, from: data)

        if replaceExisting {
            try context.delete(model: Expense.self)
            try context.delete(model: Settlement.self)
            try context.delete(model: ActivityLog.self)
            try context.delete(model: Group.self)
            try context.delete(model: User.self)
            try context.save()
        }

        for dto in snapshot.users {
            context.insert(User(
                id: dto.id, name: dto.name, email: dto.email, phone: dto.phone,
                avatarName: dto.avatarName, defaultCurrency: dto.defaultCurrency,
                isCurrentUser: dto.isCurrentUser, createdAt: dto.createdAt
            ))
        }
        for dto in snapshot.groups {
            context.insert(Group(
                id: dto.id, name: dto.name,
                groupType: GroupType(rawValue: dto.groupTypeRaw) ?? .other,
                coverImageName: dto.coverImageName, memberIds: dto.memberIds,
                defaultCurrency: dto.defaultCurrency, simplifyDebts: dto.simplifyDebts,
                isArchived: dto.isArchived, createdAt: dto.createdAt
            ))
        }
        for dto in snapshot.expenses {
            let expense = Expense(
                id: dto.id, title: dto.title, amount: dto.amount, currency: dto.currency,
                payerId: dto.payerId, groupId: dto.groupId,
                splitMethod: SplitMethod(rawValue: dto.splitMethodRaw) ?? .equal,
                category: ExpenseCategory(rawValue: dto.categoryRaw) ?? .general,
                splits: dto.splits, notes: dto.notes, date: dto.date,
                repeatFrequency: RepeatFrequency(rawValue: dto.repeatFrequencyRaw) ?? .never,
                createdAt: dto.createdAt
            )
            context.insert(expense)
        }
        for dto in snapshot.settlements {
            context.insert(Settlement(
                id: dto.id, payerId: dto.payerId, payeeId: dto.payeeId, amount: dto.amount,
                currency: dto.currency, groupId: dto.groupId, paymentMethod: dto.paymentMethod,
                notes: dto.notes, date: dto.date
            ))
        }
        for dto in snapshot.activities {
            context.insert(ActivityLog(
                id: dto.id, type: ActivityType(rawValue: dto.typeRaw) ?? .addedExpense,
                actorId: dto.actorId, actorName: dto.actorName, title: dto.title,
                details: dto.details, groupId: dto.groupId, expenseId: dto.expenseId,
                timestamp: dto.timestamp
            ))
        }
        try context.save()
    }
}
