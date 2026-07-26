import SwiftUI

public struct BalanceBadge: View {
    public let amount: Double
    public let currency: String

    public init(amount: Double, currency: String = "USD") {
        self.amount = amount
        self.currency = currency
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if amount > 0.009 {
                Text("you are owed")
                    .font(.caption2)
                    .foregroundColor(ColorTheme.owedGreen)
                    .fontWeight(.medium)
                Text(CurrencyFormatter.format(amount, currency: currency))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.owedGreen)
            } else if amount < -0.009 {
                Text("you owe")
                    .font(.caption2)
                    .foregroundColor(ColorTheme.owesOrange)
                    .fontWeight(.medium)
                Text(CurrencyFormatter.format(abs(amount), currency: currency))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.owesOrange)
            } else {
                Text("settled up")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
