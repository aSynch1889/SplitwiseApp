import Foundation
import SwiftData

@Model
public final class User: Identifiable {
    public var id: UUID
    public var name: String
    public var email: String
    public var phone: String
    public var avatarName: String
    public var defaultCurrency: String
    public var isCurrentUser: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        email: String = "",
        phone: String = "",
        avatarName: String = "person.crop.circle.fill",
        defaultCurrency: String = "USD",
        isCurrentUser: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.avatarName = avatarName
        self.defaultCurrency = defaultCurrency
        self.isCurrentUser = isCurrentUser
        self.createdAt = createdAt
    }
}
