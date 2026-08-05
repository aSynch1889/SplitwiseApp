import Foundation
import SwiftData

@Model
public final class Settlement: Identifiable {
    public var id: UUID = UUID()
    public var payerId: UUID = UUID()
    public var payeeId: UUID = UUID()
    public var amount: Double = 0
    public var currency: String = "USD"
    public var groupId: UUID?
    public var paymentMethod: String = "Cash" // "Cash", "PayPal", "Venmo", "Bank Transfer"
    public var notes: String = ""
    public var date: Date = Date()

    public init(
        id: UUID = UUID(),
        payerId: UUID,
        payeeId: UUID,
        amount: Double,
        currency: String = "USD",
        groupId: UUID? = nil,
        paymentMethod: String = "Cash",
        notes: String = "",
        date: Date = Date()
    ) {
        self.id = id
        self.payerId = payerId
        self.payeeId = payeeId
        self.amount = amount
        self.currency = currency
        self.groupId = groupId
        self.paymentMethod = paymentMethod
        self.notes = notes
        self.date = date
    }
}
