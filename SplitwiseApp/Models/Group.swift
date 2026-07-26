import Foundation
import SwiftData

public enum GroupType: String, Codable, CaseIterable, Identifiable {
    case trip = "Trip"
    case home = "Home"
    case couple = "Couple"
    case other = "Other"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .trip: return "airplane"
        case .home: return "house.fill"
        case .couple: return "heart.fill"
        case .other: return "folder.fill"
        }
    }
}

@Model
public final class Group: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var groupTypeRaw: String
    public var coverImageName: String
    public var memberIds: [UUID]
    public var defaultCurrency: String
    public var simplifyDebts: Bool
    public var isArchived: Bool
    public var createdAt: Date

    public var groupType: GroupType {
        get { GroupType(rawValue: groupTypeRaw) ?? .other }
        set { groupTypeRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        groupType: GroupType = .other,
        coverImageName: String = "folder.fill",
        memberIds: [UUID] = [],
        defaultCurrency: String = "USD",
        simplifyDebts: Bool = true,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.groupTypeRaw = groupType.rawValue
        self.coverImageName = coverImageName
        self.memberIds = memberIds
        self.defaultCurrency = defaultCurrency
        self.simplifyDebts = simplifyDebts
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
