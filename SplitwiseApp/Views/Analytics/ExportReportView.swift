import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct ExportReportView: View {
    @Environment(\.dismiss) private var dismiss

    public let group: Group
    public let members: [User]
    public let expenses: [Expense]
    public let settlements: [Settlement]

    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.brandTeal)
                        .padding(.top, 20)

                    Text("\(group.name) Statement")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Generate and share complete financial reports for this group.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Divider()

                // Export Options
                VStack(spacing: 14) {
                    Button {
                        exportPDF()
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Export PDF Report")
                                    .font(.headline)
                                Text("Formatted printable statement with group summary and expenses.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(ColorTheme.brandTeal)
                        .cornerRadius(14)
                    }

                    Button {
                        exportCSV()
                    } label: {
                        HStack {
                            Image(systemName: "tablecells.fill")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Export CSV Spreadsheet")
                                    .font(.headline)
                                Text("Raw data spreadsheet compatible with Excel, Numbers, and Google Sheets.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                        }
                        .foregroundColor(.primary)
                        .padding()
                        .background(ColorTheme.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(ColorTheme.brandTeal.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .background(ColorTheme.viewBackground)
            .navigationTitle("Export Report")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.brandTeal)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                #if canImport(UIKit)
                ActivityViewControllerWrapper(activityItems: shareItems)
                #else
                Text("Sharing completed.")
                #endif
            }
        }
    }

    private func exportPDF() {
        #if canImport(UIKit)
        let pdfData = ExportManager.generatePDF(
            groupName: group.name,
            members: members,
            expenses: expenses,
            settlements: settlements,
            currency: group.defaultCurrency
        )
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(group.name)_Report.pdf")
        try? pdfData.write(to: tempURL)

        shareItems = [tempURL]
        showingShareSheet = true
        #endif
    }

    private func exportCSV() {
        let csvString = ExportManager.generateCSV(
            groupName: group.name,
            members: members,
            expenses: expenses,
            settlements: settlements
        )
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(group.name)_Statement.csv")
        try? csvString.write(to: tempURL, atomically: true, encoding: .utf8)

        shareItems = [tempURL]
        showingShareSheet = true
    }
}

#if canImport(UIKit)
public struct ActivityViewControllerWrapper: UIViewControllerRepresentable {
    public var activityItems: [Any]
    public var applicationActivities: [UIActivity]? = nil

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
