import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum ExportManager {

    public static func generateCSV(groupName: String, members: [User], expenses: [Expense], settlements: [Settlement]) -> String {
        var csv = "Date,Type,Category,Description,Amount,Currency,Payer,Splits & Notes\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let memberDict = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.name) })

        for expense in expenses {
            let dateStr = dateFormatter.string(from: expense.date)
            let payerName = memberDict[expense.payerId] ?? "Unknown"
            let categoryStr = expense.category.rawValue
            let titleEscaped = "\"\(expense.title.replacingOccurrences(of: "\"", with: "\"\""))\""
            let notesEscaped = "\"\(expense.notes.replacingOccurrences(of: "\"", with: "\"\""))\""

            csv += "\(dateStr),Expense,\(categoryStr),\(titleEscaped),\(expense.amount),\(expense.currency),\"\(payerName)\",\(notesEscaped)\n"
        }

        for settlement in settlements {
            let dateStr = dateFormatter.string(from: settlement.date)
            let payerName = memberDict[settlement.payerId] ?? "Unknown"
            let payeeName = memberDict[settlement.payeeId] ?? "Unknown"
            let desc = "\"\(payerName) paid \(payeeName) via \(settlement.paymentMethod)\""

            csv += "\(dateStr),Settlement,General,\(desc),\(settlement.amount),\(settlement.currency),\"\(payerName)\",\"Payment\"\n"
        }

        return csv
    }

    #if canImport(UIKit)
    public static func generatePDF(groupName: String, members: [User], expenses: [Expense], settlements: [Settlement], currency: String = "USD") -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Splitwise App Export",
            kCGPDFContextAuthor: "Splitwise iOS",
            kCGPDFContextTitle: "\(groupName) Expense Summary"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat = 8.5 * 72.0
        let pageHeight: CGFloat = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let subtitleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let boldBodyFont = UIFont.boldSystemFont(ofSize: 12)

            // Header
            let titleText = "\(groupName) - Expense Report" as NSString
            let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.systemTeal]
            titleText.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)

            let dateRangeText = "Export Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))" as NSString
            let subtitleAttributes: [NSAttributedString.Key: Any] = [.font: subtitleFont, .foregroundColor: UIColor.darkGray]
            dateRangeText.draw(at: CGPoint(x: 40, y: 72), withAttributes: subtitleAttributes)

            // Summary Section
            let totalAmount = expenses.reduce(0.0) { $0 + $1.amount }
            let totalText = "Total Group Spending: \(CurrencyFormatter.format(totalAmount, currency: currency))" as NSString
            totalText.draw(at: CGPoint(x: 40, y: 95), withAttributes: subtitleAttributes)

            // Draw Line
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 40, y: 120))
            path.addLine(to: CGPoint(x: pageWidth - 40, y: 120))
            UIColor.lightGray.setStroke()
            path.lineWidth = 1
            path.stroke()

            // Table Header
            var yOffset: CGFloat = 135
            let dateH = "Date" as NSString
            let descH = "Description" as NSString
            let catH = "Category" as NSString
            let payerH = "Paid By" as NSString
            let amtH = "Amount" as NSString

            let boldAttr: [NSAttributedString.Key: Any] = [.font: boldBodyFont, .foregroundColor: UIColor.black]
            let bodyAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]

            dateH.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: boldAttr)
            descH.draw(at: CGPoint(x: 120, y: yOffset), withAttributes: boldAttr)
            catH.draw(at: CGPoint(x: 300, y: yOffset), withAttributes: boldAttr)
            payerH.draw(at: CGPoint(x: 420, y: yOffset), withAttributes: boldAttr)
            amtH.draw(at: CGPoint(x: 520, y: yOffset), withAttributes: boldAttr)

            yOffset += 20
            let memberDict = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.name) })
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"

            for expense in expenses.prefix(30) {
                let dateStr = dateFormatter.string(from: expense.date) as NSString
                let titleSub = String(expense.title.prefix(25)) as NSString
                let catSub = String(expense.category.rawValue.prefix(15)) as NSString
                let payerName = String((memberDict[expense.payerId] ?? "User").prefix(12)) as NSString
                let amtStr = CurrencyFormatter.format(expense.amount, currency: expense.currency) as NSString

                dateStr.draw(at: CGPoint(x: 40, y: yOffset), withAttributes: bodyAttr)
                titleSub.draw(at: CGPoint(x: 120, y: yOffset), withAttributes: bodyAttr)
                catSub.draw(at: CGPoint(x: 300, y: yOffset), withAttributes: bodyAttr)
                payerName.draw(at: CGPoint(x: 420, y: yOffset), withAttributes: bodyAttr)
                amtStr.draw(at: CGPoint(x: 520, y: yOffset), withAttributes: bodyAttr)

                yOffset += 18

                if yOffset > pageHeight - 60 {
                    context.beginPage()
                    yOffset = 40
                }
            }
        }

        return data
    }
    #endif
}
