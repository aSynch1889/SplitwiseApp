import SwiftUI

public struct CurrencyPicker: View {
    @Binding public var selection: String

    public var body: some View {
        Menu {
            ForEach(Array(CurrencyFormatter.symbols.keys.sorted()), id: \.self) { code in
                Button {
                    selection = code
                } label: {
                    HStack {
                        Text("\(code) (\(CurrencyFormatter.symbol(for: code)))")
                        if selection == code {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("\(selection) (\(CurrencyFormatter.symbol(for: selection)))")
                    .fontWeight(.semibold)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ColorTheme.brandTeal.opacity(0.12))
            .foregroundColor(ColorTheme.brandTeal)
            .cornerRadius(8)
        }
    }
}
