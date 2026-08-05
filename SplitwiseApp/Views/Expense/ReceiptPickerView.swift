import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

public struct ReceiptPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding public var selectedImageData: Data?
    public var onReceiptScanned: ((ScannedReceiptResult) -> Void)?

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isScanning: Bool = false
    @State private var scanErrorMessage: String?

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                #if canImport(UIKit)
                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(16)
                        .shadow(radius: 5)

                    Button(role: .destructive) {
                        selectedImageData = nil
                        selectedPhotoItem = nil
                    } label: {
                        Label("Remove Image", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } else {
                    pickerPlaceholderView
                }
                #else
                pickerPlaceholderView
                #endif

                if isScanning {
                    ProgressView("Scanning receipt with Vision OCR...")
                        .padding()
                }
            }
            .padding()
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        #if canImport(UIKit)
                        if let image = UIImage(data: data) {
                            await performOCR(image: image)
                        }
                        #endif
                    }
                }
            }
            .navigationTitle("Receipt Scanner")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.brandTeal)
                }
            }
            .alert("Scan Failed", isPresented: Binding(
                get: { scanErrorMessage != nil },
                set: { if !$0 { scanErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { scanErrorMessage = nil }
            } message: {
                Text(scanErrorMessage ?? "")
            }
        }
    }

    private var pickerPlaceholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(ColorTheme.brandTeal)

            Text("Attach & Scan Receipt")
                .font(.title3)
                .fontWeight(.bold)

            Text("Uses on-device Vision OCR to parse amounts and items from your receipt. If scanning fails, enter the expense manually.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Choose Photo from Library")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(ColorTheme.brandTeal)
                .cornerRadius(12)
            }

            #if DEBUG
            Button {
                scanDemoReceipt()
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Scan Sample Receipt (Debug Demo)")
                }
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.brandTeal)
                .padding(.vertical, 8)
            }
            #endif
        }
        .padding()
    }

    #if canImport(UIKit)
    private func performOCR(image: UIImage) async {
        isScanning = true
        defer { isScanning = false }
        do {
            let result = try await ReceiptScannerService.scanReceipt(image: image)
            onReceiptScanned?(result)
        } catch {
            scanErrorMessage = error.localizedDescription
        }
    }
    #endif

    #if DEBUG
    private func scanDemoReceipt() {
        isScanning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isScanning = false
            onReceiptScanned?(ReceiptScannerService.mockReceiptResult())
            dismiss()
        }
    }
    #endif
}
