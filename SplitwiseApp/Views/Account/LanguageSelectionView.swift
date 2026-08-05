import SwiftUI

/// Secondary page pushed from Account → Language. Picking a language switches
/// the entire app live (no restart) via `LocalizationManager`.
public struct LanguageSelectionView: View {
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        List {
            Section {
                ForEach(LocalizationManager.supported) { language in
                    Button {
                        loc.setLanguage(language.code)
                        dismiss()
                    } label: {
                        HStack {
                            Text(language.nativeName)
                                .foregroundColor(.primary)
                            Spacer()
                            if language.code == loc.currentLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundColor(ColorTheme.brandTeal)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } footer: {
                Text("The app language updates instantly.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Language")
        .hidesTabBarWhenPushed()
    }
}
