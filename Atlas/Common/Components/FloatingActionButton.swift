import SwiftUI

// MARK: - Expandable Floating Action Button
struct ExpandableFAB: View {
    let mainIcon: String
    let actions: [Action]
    
    @State private var isExpanded = false
    @State private var rotationAngle: Double = 0
    
    init(mainIcon: String, @FABActionBuilder actions: () -> [Action]) {
        self.mainIcon = mainIcon
        self.actions = actions()
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
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: isExpanded)
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
                            .shadow(color: AtlasTheme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
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

// MARK: - Action Button
struct ActionButton: View {
    let action: ExpandableFAB.Action
    
    var body: some View {
        Button(action: action.action) {
            Image(systemName: action.icon)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(action.color)
                        .shadow(color: action.color.opacity(0.3), radius: 6, x: 0, y: 3)
                )
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: action.color)
    }
}

// MARK: - Action Model
extension ExpandableFAB {
    struct Action {
        let icon: String
        let color: Color
        let action: () -> Void
        
        init(icon: String, color: Color, action: @escaping () -> Void) {
            self.icon = icon
            self.color = color
            self.action = action
        }
    }
}

// MARK: - Result Builder
@resultBuilder
struct FABActionBuilder {
    static func buildBlock(_ actions: ExpandableFAB.Action...) -> [ExpandableFAB.Action] {
        actions
    }
    
    static func buildArray(_ components: [ExpandableFAB.Action]) -> [ExpandableFAB.Action] {
        components
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
                ExpandableFAB(mainIcon: "plus") {
                    ExpandableFAB.Action(icon: "moon.stars.fill", color: Color.purple) {
                        print("New dream entry")
                    }
                    ExpandableFAB.Action(icon: "lightbulb.fill", color: Color.yellow) {
                        print("New note")
                    }
                    ExpandableFAB.Action(icon: "checkmark.circle", color: AtlasTheme.Colors.success) {
                        print("New task")
                    }
                    ExpandableFAB.Action(icon: "calendar", color: AtlasTheme.Colors.info) {
                        print("New event")
                    }
                }
                .padding()
            }
        }
    }
}