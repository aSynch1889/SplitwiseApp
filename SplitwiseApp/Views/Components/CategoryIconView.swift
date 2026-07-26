import SwiftUI

public struct CategoryIconView: View {
    public let category: ExpenseCategory
    public var size: CGFloat = 40

    public init(category: ExpenseCategory, size: CGFloat = 40) {
        self.category = category
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(ColorTheme.brandTeal.opacity(0.15))
                .frame(width: size, height: size)

            Image(systemName: category.iconName)
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(ColorTheme.brandTeal)
        }
    }
}
