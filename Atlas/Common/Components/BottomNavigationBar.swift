import SwiftUI

// MARK: - Tab Item Model (moved outside to be accessible)
struct TabItem: Equatable {
    let title: String
    let icon: String
    let selectedIcon: String
    
    init(title: String, icon: String, selectedIcon: String? = nil) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon
    }
    
    static func == (lhs: TabItem, rhs: TabItem) -> Bool {
        return lhs.title == rhs.title && lhs.icon == rhs.icon
    }
}

// MARK: - Bottom Navigation Bar
struct BottomNavigationBar: View {
    @Binding var selectedTab: TabItem
    let tabs: [TabItem]
    
    init(selectedTab: Binding<TabItem>, @TabBuilder tabs: () -> [TabItem]) {
        self._selectedTab = selectedTab
        self.tabs = tabs()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                TabButton(
                    tab: tabs[index],
                    isSelected: selectedTab == tabs[index],
                    action: { selectedTab = tabs[index] }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.md)
        .padding(.vertical, AtlasTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.large)
                .fill(AtlasTheme.Colors.glassBackground)
                .background(
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.large)
                        .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                )
                .shadow(color: AtlasTheme.Colors.glassShadow, radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)                                                                                                          
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)                                                                                                          
            }
            .padding(.vertical, AtlasTheme.Spacing.sm)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Tab Builder
@resultBuilder
struct TabBuilder {
    static func buildBlock(_ tabs: TabItem...) -> [TabItem] {
        tabs
    }
    
    static func buildArray(_ components: [TabItem]) -> [TabItem] {
        components
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        
        BottomNavigationBar(selectedTab: .constant(TabItem(title: "Dashboard", icon: "house"))) {                                                                                                   
            TabItem(title: "Dashboard", icon: "house")
            TabItem(title: "Planner", icon: "calendar")
            TabItem(title: "Profile", icon: "person.circle")
        }
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}
