import SwiftUI

struct SwipeMenuView: View {
    @Binding var isOpen: Bool
    @Binding var selectedView: AppView
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var dependencyContainer: DependencyContainer
    
    // Menu configuration
    private let menuWidth: CGFloat = UIScreen.main.bounds.width * 0.6
    private let maxDragDistance: CGFloat = 50
    
    // Navigation items
    private let navigationItems: [(AppView, String, String)] = [
        (.dashboard, "house.fill", "Dashboard"),
        (.notes, "doc.text", "Notes"),
        (.journal, "book.pages", "Journal"),
        (.tasks, "checkmark.circle", "Tasks"),
        (.watchlist, "tv", "Watchlist"),
        (.recipes, "fork.knife", "Recipes"),
        (.eatDo, "location.fill", "Eat & Do"),
        (.mindMapping, "brain.head.profile", "Mind Mapping"),
        (.profile, "person.circle", "Profile")
    ]
    
    var body: some View {
        ZStack {
            // Full-screen background that covers the entire screen
            AtlasTheme.Colors.background
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .ignoresSafeArea(.all)
            
            // Menu content (60% width, aligned to the left)
            VStack(alignment: .leading, spacing: 0) {
                // Header section
                headerSection
                
                // Navigation section
                navigationSection
                
                Spacer()
                
                // Footer section
                footerSection
            }
            .frame(width: menuWidth)
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .offset(x: isOpen ? 0 : -UIScreen.main.bounds.width)
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1), value: isOpen)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("A")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome Back")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Ready to organize your life?")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60) // Account for status bar
        }
    }
    
    // MARK: - Navigation Section
    private var navigationSection: some View {
        VStack(spacing: 8) {
            ForEach(navigationItems, id: \.0) { item in
                NavigationMenuRow(
                    icon: item.1,
                    title: item.2,
                    isSelected: selectedView == item.0
                ) {
                    selectedView = item.0
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isOpen = false
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 12) {
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.horizontal, 20)
            
            HStack {
                Image(systemName: "gear")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Settings")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40) // Account for home indicator
        }
    }
}

// MARK: - Navigation Menu Row
struct NavigationMenuRow: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var iconScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0.0
    @State private var chevronOffset: CGFloat = 0.0
    @State private var iconPulse: CGFloat = 1.0
    @State private var iconGlow: CGFloat = 0.0
    
    var body: some View {
        Button(action: {
            // Animate icon before action
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                iconScale = 0.8
                iconRotation = 5.0
            }
            
            // Reset and execute action
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    iconScale = 1.0
                    iconRotation = 0.0
                }
                action()
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .scaleEffect(iconScale * iconPulse)
                    .rotationEffect(.degrees(iconRotation))
                    .shadow(color: isSelected ? .white.opacity(iconGlow) : .clear, radius: 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: iconScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: iconRotation)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: iconPulse)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: iconGlow)
                    .onAppear {
                        // Start continuous animations
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            iconPulse = 1.05
                        }
                        if isSelected {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                iconGlow = 0.8
                            }
                        }
                    }
                    .onChange(of: isSelected) { _, selected in
                        if selected {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                iconGlow = 0.8
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                iconGlow = 0.0
                            }
                        }
                    }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .offset(x: chevronOffset)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: chevronOffset)
                        .onAppear {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) {
                                chevronOffset = 0
                            }
                        }
                        .onDisappear {
                            chevronOffset = -10
                        }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .blue.opacity(0.3) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - App View Enum

#Preview {
    SwipeMenuView(
        isOpen: .constant(true),
        selectedView: .constant(.dashboard)
    )
    .environmentObject(DataManager.shared)
        .environmentObject(DependencyContainer.shared)
}

