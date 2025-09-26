import SwiftUI

struct QuickActionButtons: View {
    @Binding var selectedView: AppView
    @State private var isExpanded = false
    @State private var selectedAction: QuickAction?
    
    var body: some View {
        VStack(spacing: 12) {
            // Main Action Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                }
            }
            
            // Secondary Action Buttons
            if isExpanded {
                VStack(spacing: 12) {
                    QuickActionButton(
                        action: .newNote,
                        isSelected: selectedAction == .newNote
                    ) {
                        selectedAction = .newNote
                        // Add small delay to prevent rapid navigation updates
                        _Concurrency.Task { @MainActor in
                            try? await _Concurrency.Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                            selectedView = .notes
                        }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded = false
                        }
                    }
                    
                    QuickActionButton(
                        action: .quickJournal,
                        isSelected: selectedAction == .quickJournal
                    ) {
                        selectedAction = .quickJournal
                        // Add small delay to prevent rapid navigation updates
                        _Concurrency.Task { @MainActor in
                            try? await _Concurrency.Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                            selectedView = .journal
                        }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded = false
                        }
                    }
                    
                    QuickActionButton(
                        action: .addTask,
                        isSelected: selectedAction == .addTask
                    ) {
                        selectedAction = .addTask
                        // Add small delay to prevent rapid navigation updates
                        _Concurrency.Task { @MainActor in
                            try? await _Concurrency.Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                            selectedView = .tasks
                        }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded = false
                        }
                    }
                    
                    QuickActionButton(
                        action: .mindMap,
                        isSelected: selectedAction == .mindMap
                    ) {
                        selectedAction = .mindMap
                        // Add small delay to prevent rapid navigation updates
                        _Concurrency.Task { @MainActor in
                            try? await _Concurrency.Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                            selectedView = .mindMapping
                        }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded = false
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 100) // Account for safe area
    }
}

// MARK: - Quick Action Enum
enum QuickAction: String, CaseIterable {
    case newNote = "New Note"
    case quickJournal = "Quick Journal"
    case addTask = "Add Task"
    case mindMap = "Mind Map"
    
    var icon: String {
        switch self {
        case .newNote: return "doc.text"
        case .quickJournal: return "book.pages"
        case .addTask: return "checkmark.circle"
        case .mindMap: return "brain.head.profile"
        }
    }
    
    var color: Color {
        switch self {
        case .newNote: return .orange
        case .quickJournal: return .purple
        case .addTask: return .green
        case .mindMap: return .blue
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let action: QuickAction
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(action.color)
                }
                
                Text(action.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(action.color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.05 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    ZStack {
        AtlasTheme.Colors.background
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                QuickActionButtons(selectedView: .constant(.dashboard))
            }
        }
    }
}
