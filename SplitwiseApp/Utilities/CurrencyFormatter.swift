import Foundation

public enum CurrencyFormatter {
    public static let symbols: [String: String] = [
        "USD": "$",
        "CNY": "¥",
        "EUR": "€",
        "GBP": "£",
        "JPY": "¥",
        "AUD": "A$",
        "CAD": "C$",
        "HKD": "HK$",
        "SGD": "S$",
        "TWD": "NT$"
    ]

    public static let conversionRatesToUSD: [String: Double] = [
        "USD": 1.0,
        "CNY": 0.14,
        "EUR": 1.09,
        "GBP": 1.28,
        "JPY": 0.0067,
        "AUD": 0.66,
        "CAD": 0.74,
        "HKD": 0.128,
        "SGD": 0.74,
        "TWD": 0.031
    ]

    public static func symbol(for currencyCode: String) -> String {
        symbols[currencyCode] ?? "$"
    }

    public static func format(_ amount: Double, currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = symbol(for: currency)
        formatter.maximumFractionDigits = (currency == "JPY") ? 0 : 2
        formatter.minimumFractionDigits = (currency == "JPY") ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol(for: currency))\(String(format: "%.2f", amount))"
    }

    public static func convert(amount: Double, from fromCurrency: String, to toCurrency: String) -> Double {
        guard fromCurrency != toCurrency else { return amount }
        let fromRate = conversionRatesToUSD[fromCurrency] ?? 1.0
        let toRate = conversionRatesToUSD[toCurrency] ?? 1.0
        let amountInUSD = amount * fromRate
        return amountInUSD / toRate
    }
}
