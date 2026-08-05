import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum ExportManager {

    /// RFC 4180-ish CSV field escaping, with formula-injection prefix neutralization.
    public static func csvField(_ raw: String) -> String {
        var value = raw
        if let first = value.first, "=+-@".contains(first) {
            value = "'" + value
        }
        value = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(value)\""
    }

    public static func generateCSV(groupName: String, members: [User], expenses: [Expense], settlements: [Settlement]) -> String {
        var csv = "Date,Type,Category,Description,Amount,Currency,Payer,Splits & Notes\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let memberDict = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.name) })

        for expense in expenses {
            let dateStr = dateFormatter.string(from: expense.date)
            let payerName = memberDict[expense.payerId] ?? "Unknown"
            csv += [
                csvField(dateStr),
                csvField("Expense"),
                csvField(expense.category.rawValue),
                csvField(expense.title),
                csvField(String(expense.amount)),
                csvField(expense.currency),
                csvField(payerName),
                csvField(expense.notes)
            ].joined(separator: ",") + "\n"
        }

        for settlement in settlements {
            let dateStr = dateFormatter.string(from: settlement.date)
            let payerName = memberDict[settlement.payerId] ?? "Unknown"
            let payeeName = memberDict[settlement.payeeId] ?? "Unknown"
            let desc = "\(payerName) paid \(payeeName) via \(settlement.paymentMethod)"

            csv += [
                csvField(dateStr),
                csvField("Settlement"),
                csvField("General"),
                csvField(desc),
                csvField(String(settlement.amount)),
                csvField(settlement.currency),
                csvField(payerName),
                csvField("Payment")
            ].joined(separator: ",") + "\n"
        }

        return csv
    }

    #if canImport(UIKit)
    public static func generatePDF(
        groupName: String,
        members: [User],
        expenses: [Expense],
        settlements: [Settlement],
        currency: String = "USD"
    ) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "BillNest App Export",
            kCGPDFContextAuthor: "BillNest iOS",
            kCGPDFContextTitle: "\(groupName) Expense Summary"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat = 8.5 * 72.0
        let pageHeight: CGFloat = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let bottomLimit: CGFloat = pageHeight - 60
        let topContentY: CGFloat = 40

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let subtitleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let boldBodyFont = UIFont.boldSystemFont(ofSize: 12)

            let boldAttr: [NSAttributedString.Key: Any] = [.font: boldBodyFont, .foregroundColor: UIColor.black]
            let bodyAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]
            let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.systemTeal]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [.font: subtitleFont, .foregroundColor: UIColor.darkGray]

            let memberDict = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.name) })
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"

            func drawTableHeader(at y: CGFloat) {
                ("Date" as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: boldAttr)
                ("Description" as NSString).draw(at: CGPoint(x: 120, y: y), withAttributes: boldAttr)
                ("Category" as NSString).draw(at: CGPoint(x: 300, y: y), withAttributes: boldAttr)
                ("Paid By" as NSString).draw(at: CGPoint(x: 420, y: y), withAttributes: boldAttr)
                ("Amount" as NSString).draw(at: CGPoint(x: 520, y: y), withAttributes: boldAttr)
            }

            func drawPageChrome(isFirstPage: Bool, yOffset: inout CGFloat) {
                context.beginPage()
                if isFirstPage {
                    let titleText = "\(groupName) - Expense Report" as NSString
                    titleText.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)

                    let dateRangeText = "Export Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))" as NSString
                    dateRangeText.draw(at: CGPoint(x: 40, y: 72), withAttributes: subtitleAttributes)

                    let convertedTotal = expenses.reduce(0.0) {
                        $0 + CurrencyFormatter.convert(amount: $1.amount, from: $1.currency, to: currency)
                    }
                    let totalText = "Total Group Spending (\(currency), static rates): \(CurrencyFormatter.format(convertedTotal, currency: currency))" as NSString
                    totalText.draw(at: CGPoint(x: 40, y: 95), withAttributes: subtitleAttributes)

                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: 40, y: 120))
                    path.addLine(to: CGPoint(x: pageWidth - 40, y: 120))
                    UIColor.lightGray.setStroke()
                    path.lineWidth = 1
                    path.stroke()

                    yOffset = 135
                    drawTableHeader(at: yOffset)
                    yOffset += 20
                } else {
                    let continued = "\(groupName) - continued" as NSString
                    continued.draw(at: CGPoint(x: 40, y: topContentY), withAttributes: subtitleAttributes)
                    yOffset = topContentY + 24
                    drawTableHeader(at: yOffset)
                    yOffset += 20
                }
            }

            var yOffset: CGFloat = 0
            var isFirstPage = true
            drawPageChrome(isFirstPage: true, yOffset: &yOffset)
            isFirstPage = false

            func ensureSpace(_ needed: CGFloat = 18) {
                if yOffset + needed > bottomLimit {
                    drawPageChrome(isFirstPage: false, yOffset: &yOffset)
                }
            }

            for expense in expenses {
                ensureSpace()
                let dateStr = dateFormatter.string(from: expense.date) as NSString
                let titleSub = String(expense.title.prefix(25)) as NSString
                let catSub = String(expense.category.rawValue.prefix(15)) as NSString
                let payerName = String((memberDict[expense.payerId] ?? "User").prefix(12)) as NSString
                let converted = CurrencyFormatter.convert(amount: expense.amount, from: expense.currency, to: currency)
                let amtStr = CurrencyFormatter.format(converted, currency: currency) as NSString

                dateStr.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: bodyAttr)
                titleSub.draw(at: CGPoint(x: 120, y: yOffset), withAttributes: bodyAttr)
                catSub.draw(at: CGPoint(x: 300, y: yOffset), withAttributes: bodyAttr)
                payerName.draw(at: CGPoint(x: 420, y: yOffset), withAttributes: bodyAttr)
                amtStr.draw(at: CGPoint(x: 520, y: yOffset), withAttributes: bodyAttr)
                yOffset += 18
            }

            if !settlements.isEmpty {
                ensureSpace(36)
                yOffset += 10
                ("Settlements" as NSString).draw(at: CGPoint(x: 40, y: yOffset), withAttributes: boldAttr)
                yOffset += 20

                for settlement in settlements {
                    ensureSpace()
                    let dateStr = dateFormatter.string(from: settlement.date) as NSString
                    let payerName = memberDict[settlement.payerId] ?? "User"
                    let payeeName = memberDict[settlement.payeeId] ?? "User"
                    let desc = String("\(payerName) → \(payeeName)".prefix(25)) as NSString
                    let method = String(settlement.paymentMethod.prefix(15)) as NSString
                    let converted = CurrencyFormatter.convert(
                        amount: settlement.amount,
                        from: settlement.currency,
                        to: currency
                    )
                    let amtStr = CurrencyFormatter.format(converted, currency: currency) as NSString

                    dateStr.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: bodyAttr)
                    desc.draw(at: CGPoint(x: 120, y: yOffset), withAttributes: bodyAttr)
                    method.draw(at: CGPoint(x: 300, y: yOffset), withAttributes: bodyAttr)
                    ("Settlement" as NSString).draw(at: CGPoint(x: 420, y: yOffset), withAttributes: bodyAttr)
                    amtStr.draw(at: CGPoint(x: 520, y: yOffset), withAttributes: bodyAttr)
                    yOffset += 18
                }
            }
        }

        return data
    }
    #endif
}
