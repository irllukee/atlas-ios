import SwiftUI

// MARK: - Modern Categorized Floating Action Button
struct ModernFAB: View {
    @State private var isExpanded = false
    @State private var selectedCategory: Category? = nil
    @State private var rotationAngle: Double = 0
    @State private var keyboardHeight: CGFloat = 0
    
    enum Category: String, CaseIterable {
        case writing = "Writing"
        case productivity = "Productivity"
        case personal = "Personal"
        case tools = "Tools"
        
        var icon: String {
            switch self {
            case .writing: return "pencil.and.outline"
            case .productivity: return "chart.line.uptrend.xyaxis"
            case .personal: return "person.circle"
            case .tools: return "wrench.and.screwdriver"
            }
        }
        
        var color: Color {
            switch self {
            case .writing: return Color.blue
            case .productivity: return Color.green
            case .personal: return Color.purple
            case .tools: return Color.orange
            }
        }
        
        var actions: [FABAction] {
            switch self {
            case .writing:
                return [
                    FABAction(icon: "doc.text", title: "New Note", color: .blue),
                    FABAction(icon: "book", title: "Journal Entry", color: .purple),
                    FABAction(icon: "list.bullet", title: "Quick List", color: .green)
                ]
            case .productivity:
                return [
                    FABAction(icon: "checkmark.circle", title: "New Task", color: .green),
                    FABAction(icon: "calendar", title: "Schedule Event", color: .blue),
                    FABAction(icon: "chart.bar", title: "Analytics", color: .orange)
                ]
            case .personal:
                return [
                    FABAction(icon: "heart", title: "Mood Log", color: .pink),
                    FABAction(icon: "moon.stars", title: "Dream Entry", color: .purple),
                    FABAction(icon: "camera", title: "Photo Note", color: .blue)
                ]
            case .tools:
                return [
                    FABAction(icon: "keyboard.chevron.compact.down", title: "Dismiss Keyboard", color: .gray) {
                        DispatchQueue.main.async {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    },
                    FABAction(icon: "magnifyingglass", title: "Search", color: .blue),
                    FABAction(icon: "gear", title: "Settings", color: .gray)
                ]
            }
        }
    }
    
    var body: some View {
        VStack(spacing: AtlasTheme.Spacing.sm) {
            // Category buttons (appear when expanded)
            if isExpanded {
                ForEach(Category.allCases, id: \.self) { category in
                    FABCategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: { selectCategory(category) }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(Category.allCases.firstIndex(of: category) ?? 0) * 0.03), value: isExpanded)
                }
            }
            
            // Action buttons (appear when category is selected)
            if let category = selectedCategory, isExpanded {
                ForEach(category.actions.indices, id: \.self) { index in
                    ActionButton(action: category.actions[index])
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.03), value: selectedCategory)
                }
            }
            
            // Main FAB button
            Button(action: toggleExpansion) {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(AtlasTheme.Colors.primary)
                            .shadow(color: AtlasTheme.Colors.primary.opacity(0.2), radius: 6, x: 0, y: 3)
                    )
            }
            .rotationEffect(.degrees(rotationAngle))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: rotationAngle)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }
    
    private func toggleExpansion() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isExpanded.toggle()
            rotationAngle = isExpanded ? 45 : 0
            if !isExpanded {
                selectedCategory = nil
            }
        }
    }
    
    private func selectCategory(_ category: Category) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedCategory = selectedCategory == category ? nil : category
        }
    }
}

// MARK: - FAB Category Button
struct FABCategoryButton: View {
    let category: ModernFAB.Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? category.color : category.color.opacity(0.7))
                            .shadow(color: category.color.opacity(0.2), radius: 3, x: 0, y: 1)
                    )
                
                Text(category.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(AtlasTheme.Colors.text)
                    .multilineTextAlignment(.center)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let action: FABAction
    
    var body: some View {
        Button(action: action.action) {
            VStack(spacing: 4) {
                Image(systemName: action.icon)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(action.color)
                            .shadow(color: action.color.opacity(0.2), radius: 3, x: 0, y: 1)
                    )
                
                Text(action.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(AtlasTheme.Colors.text)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 60)
            }
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: action.color)
    }
}

// MARK: - Action Model
struct FABAction {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    init(icon: String, title: String, color: Color, action: @escaping () -> Void = {}) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }
}

// MARK: - Legacy FAB (for backward compatibility)
struct ExpandableFAB: View {
    let mainIcon: String
    let actions: [FABAction]
    
    @State private var isExpanded = false
    @State private var rotationAngle: Double = 0
    
    init(mainIcon: String, actions: [FABAction]) {
        self.mainIcon = mainIcon
        self.actions = actions
    }
    
    var body: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            // Action buttons (appear when expanded)
            if isExpanded {
                ForEach(actions.indices, id: \.self) { index in
                    ActionButton(action: actions[index])
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.03), value: isExpanded)
                }
            }
            
            // Main FAB button
            Button(action: toggleExpansion) {
                Image(systemName: isExpanded ? "xmark" : mainIcon)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(AtlasTheme.Colors.primary)
                            .shadow(color: AtlasTheme.Colors.primary.opacity(0.2), radius: 6, x: 0, y: 3)
                    )
            }
            .rotationEffect(.degrees(rotationAngle))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: rotationAngle)
        }
    }
    
    private func toggleExpansion() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isExpanded.toggle()
            rotationAngle = isExpanded ? 45 : 0
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AtlasTheme.Colors.background
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                ModernFAB()
                    .padding()
            }
        }
    }
}