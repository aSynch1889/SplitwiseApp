import SwiftUI

public extension View {
    /// Hide the parent `TabView` tab bar when this screen is pushed from a tab root.
    /// No-op on iPad `NavigationSplitView` (no tab bar).
    func hidesTabBarWhenPushed() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .tabBar)
        #else
        self
        #endif
    }
}
