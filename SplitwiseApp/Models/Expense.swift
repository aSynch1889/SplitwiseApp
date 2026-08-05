import Foundation
import SwiftData

public enum SplitMethod: String, Codable, CaseIterable, Identifiable {
    case equal = "Equal"
    case exact = "Exact"
    case percentage = "Percentage"
    case shares = "Shares"
    case itemized = "Itemized"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .equal: return "=/="
        case .exact: return "$"
        case .percentage: return "%"
        case .shares: return "1x"
        case .itemized: return "🧾"
        }
    }
}

public enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food = "Food & Drink"
    case utilities = "Utilities"
    case transportation = "Transportation"
    case entertainment = "Entertainment"
    case rent = "Rent"
    case shopping = "Shopping"
    case general = "General"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .utilities: return "bolt.fill"
        case .transportation: return "car.fill"
        case .entertainment: return "film.fill"
        case .rent: return "house.fill"
        case .shopping: return "bag.fill"
        case .general: return "dollarsign.circle.fill"
        }
    }
}

public enum RepeatFrequency: String, Codable, CaseIterable, Identifiable {
    case never = "Never"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    public var id: String { rawValue }
}

@Model
public final class Expense: Identifiable {
    public var id: UUID
    public var title: String
    public var amount: Double
    public var currency: String
    public var payerId: UUID
    public var groupId: UUID?
    public var splitMethodRaw: String
    public var categoryRaw: String
    public var splitsData: Data // Encoded [ExpenseSplit]
    public var receiptImageData: Data?
    public var notes: String
    public var date: Date
    public var repeatFrequencyRaw: String
    public var createdAt: Date

    public var splitMethod: SplitMethod {
        get { SplitMethod(rawValue: splitMethodRaw) ?? .equal }
        set { splitMethodRaw = newValue.rawValue }
    }

    public var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .general }
        set { categoryRaw = newValue.rawValue }
    }

    public var repeatFrequency: RepeatFrequency {
        get { RepeatFrequency(rawValue: repeatFrequencyRaw) ?? .never }
        set { repeatFrequencyRaw = newValue.rawValue }
    }

    public var splits: [ExpenseSplit] {
        get {
            (try? JSONDecoder().decode([ExpenseSplit].self, from: splitsData)) ?? []
        }
        set {
            splitsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        currency: String = "USD",
        payerId: UUID,
        groupId: UUID? = nil,
        splitMethod: SplitMethod = .equal,
        category: ExpenseCategory = .general,
        splits: [ExpenseSplit] = [],
        receiptImageData: Data? = nil,
        notes: String = "",
        date: Date = Date(),
        repeatFrequency: RepeatFrequency = .never,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.currency = currency
        self.payerId = payerId
        self.groupId = groupId
        self.splitMethodRaw = splitMethod.rawValue
        self.categoryRaw = category.rawValue
        self.receiptImageData = receiptImageData
        self.notes = notes
        self.date = date
        self.repeatFrequencyRaw = repeatFrequency.rawValue
        self.createdAt = createdAt
        self.splitsData = (try? JSONEncoder().encode(splits)) ?? Data()
    }
}
