import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#endif

public struct ScannedReceiptResult {
    public var title: String
    public var totalAmount: Double
    public var lineItems: [ItemizedSplit]
}

public enum ReceiptScanError: LocalizedError {
    case invalidImage
    case recognitionFailed
    case noUsefulData

    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not read the selected image."
        case .recognitionFailed:
            return "Receipt recognition failed. Please enter the expense manually."
        case .noUsefulData:
            return "No amount or items could be read. Please fill in the expense manually."
        }
    }
}

public enum ReceiptScannerService {

    #if canImport(UIKit)
    public static func scanReceipt(image: UIImage) async throws -> ScannedReceiptResult {
        guard let cgImage = image.cgImage else {
            throw ReceiptScanError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: ReceiptScanError.recognitionFailed)
                    return
                }

                var detectedLines: [String] = []
                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        detectedLines.append(topCandidate.string)
                    }
                }

                do {
                    let parsedResult = try parseReceiptText(lines: detectedLines)
                    continuation.resume(returning: parsedResult)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    #endif

    /// DEBUG-only sample data for UI demos. Never used as a fallback for real scans.
    public static func mockReceiptResult() -> ScannedReceiptResult {
        ScannedReceiptResult(
            title: "Trader Joe's Grocery",
            totalAmount: 48.50,
            lineItems: [
                ItemizedSplit(title: "Organic Milk", price: 4.99),
                ItemizedSplit(title: "Avocados (4 pack)", price: 5.49),
                ItemizedSplit(title: "Sourdough Bread", price: 3.99),
                ItemizedSplit(title: "Ribeye Steak 12oz", price: 18.99),
                ItemizedSplit(title: "Sparkling Water 12p", price: 6.99),
                ItemizedSplit(title: "Sales Tax & Bag Fee", price: 8.05)
            ]
        )
    }

    private static func parseReceiptText(lines: [String]) throws -> ScannedReceiptResult {
        guard !lines.isEmpty else {
            throw ReceiptScanError.noUsefulData
        }

        var detectedTotal: Double = 0.0
        var items: [ItemizedSplit] = []
        let mainTitle = lines.first ?? "Receipt Expense"

        let numberRegex = try? NSRegularExpression(pattern: #"(\d+\.\d{2})"#)
        let totalKeywords = ["total", "amount due", "合计", "总计", "總計"]

        for line in lines {
            let lower = line.lowercased()
            let isTotalLine = totalKeywords.contains(where: { lower.contains($0) })
                || lower.contains("subtotal")

            if isTotalLine {
                if let match = numberRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                   let range = Range(match.range(at: 1), in: line),
                   let val = Double(line[range]), val > detectedTotal {
                    detectedTotal = val
                }
            } else if let match = numberRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                      let range = Range(match.range(at: 1), in: line),
                      let val = Double(line[range]) {
                let name = line.replacingOccurrences(of: String(line[range]), with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty && val > 0 && val < 500 {
                    items.append(ItemizedSplit(title: name, price: val))
                }
            }
        }

        if detectedTotal == 0.0 {
            detectedTotal = items.reduce(0.0) { $0 + $1.price }
        }

        guard detectedTotal > 0 || !items.isEmpty else {
            throw ReceiptScanError.noUsefulData
        }

        if detectedTotal == 0.0 {
            detectedTotal = items.reduce(0.0) { $0 + $1.price }
        }

        return ScannedReceiptResult(title: mainTitle, totalAmount: detectedTotal, lineItems: items)
    }
}
