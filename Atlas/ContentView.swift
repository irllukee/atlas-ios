import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var encryptionService: EncryptionService
    @State private var selectedView: AppView = .dashboard
    @State private var isMenuOpen = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    // Menu configuration
    private let menuWidth: CGFloat = UIScreen.main.bounds.width * 0.6
    private let maxDragDistance: CGFloat = 50
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Swipe Menu (background layer)
                SwipeMenuView(
                    isOpen: $isMenuOpen,
                    selectedView: $selectedView
                )
                .zIndex(0)
                
                // Main Content (slides over when menu opens)
                currentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: isMenuOpen ? menuWidth + dragOffset : dragOffset)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1), value: isMenuOpen)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1), value: dragOffset)
                    .zIndex(1)
                    .onTapGesture {
                        if isMenuOpen {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)) {
                                isMenuOpen = false
                            }
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleDragChanged(value, in: geometry)
                            }
                            .onEnded { value in
                                handleDragEnded(value, in: geometry)
                            }
                    )
            }
        }
    }
    
    // MARK: - Current View
    @ViewBuilder
    private var currentView: some View {
        switch selectedView {
        case .dashboard:
            dashboardView
        case .notes:
            NotesView(dataManager: dataManager, encryptionService: encryptionService)
        case .tasks:
            TasksView(dataManager: dataManager)
        case .journal:
            JournalView(dataManager: dataManager, encryptionService: encryptionService)
        case .calendar:
            CalendarView()
        case .profile:
            ProfileView()
        }
    }
    
    // MARK: - Dashboard View
    private var dashboardView: some View {
        ZStack {
            // Background gradient
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Modern Header Section
                    modernHeaderSection
                    
                    // Quick Stats Grid
                    quickStatsGrid
                    
                    // Today's Focus Section
                    todaysFocusSection
                    
                    // Life Modules Grid
                    lifeModulesGrid
                    
                    // Recent Activity Section
                    recentActivitySection
                    
                    // Weather & Context Section
                    weatherContextSection
                    
                    // Bottom Spacing
                    Spacer(minLength: 100)
                }
            }
        }
    }
    
    // MARK: - Modern Header Section
    private var modernHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Dynamic Greeting
                    Text(dynamicGreeting)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Current Date & Time
                    Text(currentDateTime)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Motivational Quote
                    Text(dailyQuote)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .italic()
                }
                
                Spacer()
                
                // Profile Avatar with Status
                VStack(spacing: 8) {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text("A")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 3)
                                .frame(width: 66, height: 66)
                        )
                    
                    // Status Indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Quick Stats Grid
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Tasks Completed Today
            QuickStatCard(
                title: "Tasks Done",
                value: "12",
                subtitle: "of 15 today",
                icon: "checkmark.circle.fill",
                color: .green,
                progress: 0.8
            )
            
            // Notes Created
            QuickStatCard(
                title: "Notes",
                value: "8",
                subtitle: "this week",
                icon: "note.text",
                color: .blue,
                progress: 0.6
            )
            
            // Journal Entries
            QuickStatCard(
                title: "Journal",
                value: "3",
                subtitle: "entries today",
                icon: "book.fill",
                color: .purple,
                progress: 0.4
            )
            
            // Calendar Events
            QuickStatCard(
                title: "Events",
                value: "5",
                subtitle: "remaining today",
                icon: "calendar",
                color: .orange,
                progress: 0.7
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }
    
    // MARK: - Today's Focus Section
    private var todaysFocusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Focus")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Customize") {
                    // Action for customization
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            
            // Focus Cards
            VStack(spacing: 12) {
                FocusCard(
                    title: "Morning Routine",
                    description: "Complete your daily morning routine",
                    progress: 0.75,
                    color: .blue,
                    icon: "sunrise.fill"
                )
                
                FocusCard(
                    title: "Work Project",
                    description: "Finish the quarterly report",
                    progress: 0.4,
                    color: .green,
                    icon: "briefcase.fill"
                )
                
                FocusCard(
                    title: "Evening Reflection",
                    description: "Journal about today's experiences",
                    progress: 0.0,
                    color: .purple,
                    icon: "moon.stars.fill"
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Life Modules Grid
    private var lifeModulesGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Life Modules")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Action to view all modules
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                LifeModuleCard(
                    title: "Dream Journal",
                    icon: "moon.stars.fill",
                    value: "2 entries",
                    color: .purple,
                    progress: 0.6
                )
                
                LifeModuleCard(
                    title: "Notes & Ideas",
                    icon: "note.text",
                    value: "5 notes",
                    color: .blue,
                    progress: 0.8
                )
                
                LifeModuleCard(
                    title: "Tasks & Goals",
                    icon: "checkmark.circle.fill",
                    value: "73% done",
                    color: .green,
                    progress: 0.73
                )
                
                LifeModuleCard(
                    title: "Calendar",
                    icon: "calendar",
                    value: "3 PM meeting",
                    color: .orange,
                    progress: 0.4
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("See All") {
                    // Action to see all activity
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            
            FrostedCard(style: .standard) {
                VStack(spacing: 16) {
                    ActivityItem(
                        icon: "checkmark.circle.fill",
                        title: "Completed task: Review quarterly report",
                        time: "2 hours ago",
                        color: .green
                    )
                    
                    ActivityItem(
                        icon: "note.text",
                        title: "Created note: Meeting ideas",
                        time: "4 hours ago",
                        color: .blue
                    )
                    
                    ActivityItem(
                        icon: "book.fill",
                        title: "Journal entry: Morning reflection",
                        time: "6 hours ago",
                        color: .purple
                    )
                    
                    ActivityItem(
                        icon: "calendar",
                        title: "Added event: Team meeting",
                        time: "Yesterday",
                        color: .orange
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Weather & Context Section
    private var weatherContextSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Context")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                // Weather Card
                FrostedCard(style: .compact) {
                    VStack(spacing: 8) {
                        Image(systemName: "sun.max.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        
                        Text("72°F")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Sunny")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Productivity Score
                FrostedCard(style: .compact) {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("85%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Productivity")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Mood Tracker
                FrostedCard(style: .compact) {
                    VStack(spacing: 8) {
                        Image(systemName: "face.smiling.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        
                        Text("Great")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Mood")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Dynamic Content Helpers
    private var dynamicGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    private var currentDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private var dailyQuote: String {
        let quotes = [
            "Every day is a new beginning.",
            "Progress, not perfection.",
            "Small steps lead to big changes.",
            "Today's effort is tomorrow's success.",
            "Focus on what you can control."
        ]
        return quotes.randomElement() ?? "Make today count."
    }
    
    // MARK: - Gesture Handlers
    private func handleDragChanged(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        let startLocation = value.startLocation.x
        let translation = value.translation.width
        
        // Only respond to swipes starting from the left edge
        if startLocation <= maxDragDistance {
            isDragging = true
            
            if !isMenuOpen {
                // Opening gesture - menu slides in from left
                let progress = min(max(translation / menuWidth, 0), 1)
                dragOffset = translation - (menuWidth * progress)
            } else {
                // Closing gesture - menu slides out to left
                dragOffset = min(translation, 0)
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        let translation = value.translation.width
        let velocity = value.velocity.width
        
        isDragging = false
        
        if !isMenuOpen {
            // Opening gesture ended
            if translation > menuWidth * 0.3 || velocity > 500 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)) {
                    isMenuOpen = true
                }
            } else {
                dragOffset = 0
            }
        } else {
            // Closing gesture ended
            if translation < -50 || velocity < -500 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)) {
                    isMenuOpen = false
                }
            } else {
                dragOffset = 0
            }
        }
    }
}

// MARK: - Life Module Card Component (Floating Text Only)
struct LifeModuleCard: View {
    let title: String
    let icon: String
    let value: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 28, height: 28)
                
                Spacer()
                
                // Progress indicator
                CircularProgress(progress: progress, color: .white.opacity(0.8), size: 20, lineWidth: 2)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}
