import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var securityManager: SecurityManager
    @EnvironmentObject private var biometricService: BiometricService
    @State private var selectedView: AppView = .dashboard
    @State private var isMenuOpen = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var showingProfilePictureEditor = false
    
    // Dashboard data service
    @StateObject private var dashboardDataService: DashboardDataService
    @StateObject private var profilePictureService = ProfilePictureService.shared
    
    // Animation states for dashboard
    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = 30
    @State private var statsOpacity: Double = 0
    @State private var statsOffset: CGFloat = 30
    
    // Menu configuration
    private let menuWidth: CGFloat = UIScreen.main.bounds.width * 0.6
    private let maxDragDistance: CGFloat = 50
    
    // MARK: - Initialization
    init() {
        // Initialize dashboard data service lazily to avoid blocking app startup
        // This will be created on first access to improve startup performance
        self._dashboardDataService = StateObject(wrappedValue: DashboardDataService(
            dataManager: DataManager.shared,
            calendarService: CalendarService(),
            notesService: NotesService(dataManager: DataManager.shared, encryptionService: EncryptionService.shared),
            tasksService: TasksService(dataManager: DataManager.shared),
            journalService: JournalService(dataManager: DataManager.shared, encryptionService: EncryptionService.shared)
        ))
    }
    
    var body: some View {
        GeometryReader { geometry in
        ZStack {
                // Swipe Menu (background layer)
                SwipeMenuView(
                    isOpen: $isMenuOpen,
                    selectedView: $selectedView
                )
                .environmentObject(dataManager)
                .environmentObject(securityManager)
                .zIndex(0)
                
                // Main Content (slides over when menu opens)
            currentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: isMenuOpen ? menuWidth + dragOffset : dragOffset)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1), value: isMenuOpen)
                    .animation(.spring(response: 0.3, dampingFraction: 0.9, blendDuration: 0.1), value: dragOffset)
                    .zIndex(1)
                    .onTapGesture {
                        if isMenuOpen {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)) {
                                isMenuOpen = false
                                dragOffset = 0
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
        .onAppear {
            // Ensure dragOffset is reset when view appears
            dragOffset = 0
            
            // Configure navigation bar to prevent white backgrounds during transitions
            configureNavigationBar()
        }
        .sheet(isPresented: $showingProfilePictureEditor) {
            ProfilePictureEditorView()
        }
        .withErrorHandling()
    }
    
    // MARK: - Current View
    @ViewBuilder
    private var currentView: some View {
        switch selectedView {
        case .dashboard:
            dashboardView
        case .notes:
            NotesView(dataManager: dataManager, encryptionService: securityManager.encryptionService)
        case .tasks:
            TasksView(dataManager: dataManager)
        case .journal:
            JournalView(dataManager: dataManager, encryptionService: securityManager.encryptionService)
        case .calendar:
            CalendarView()
        case .analytics:
            AnalyticsNavigationView()
        case .watchlist:
            WatchlistView(dataManager: dataManager)
        case .recipes:
            RecipesView()
        case .mindMapping:
            MindMappingView(dataManager: dataManager)
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
                        .opacity(headerOpacity)
                        .offset(y: headerOffset)
                        .animation(AtlasTheme.Animations.gentle.delay(0.1), value: headerOpacity)
                        .animation(AtlasTheme.Animations.gentle.delay(0.1), value: headerOffset)
                    
                    // Quick Stats Grid
                    quickStatsGrid
                        .opacity(statsOpacity)
                        .offset(y: statsOffset)
                        .animation(AtlasTheme.Animations.gentle.delay(0.2), value: statsOpacity)
                        .animation(AtlasTheme.Animations.gentle.delay(0.2), value: statsOffset)
                    
                    
                    // Bottom Spacing
                    Spacer(minLength: 100)
                }
            }
                   .onAppear {
                       // Refresh dashboard data
                       dashboardDataService.loadDashboardData()
                       
                       // Animate dashboard sections
                       withAnimation(AtlasTheme.Animations.gentle.delay(0.1)) {
                           headerOpacity = 1
                           headerOffset = 0
                       }
                       
                       withAnimation(AtlasTheme.Animations.gentle.delay(0.2)) {
                           statsOpacity = 1
                           statsOffset = 0
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
                    Button(action: {
                        showingProfilePictureEditor = true
                    }) {
                        ZStack {
                            if let profileImage = profilePictureService.profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
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
                            }
                            
                            Circle()
                                .stroke(.white, lineWidth: 3)
                                .frame(width: 66, height: 66)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
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
        HStack(alignment: .top, spacing: 0) {
            // Left side - empty space for future content
            Spacer()
            
            // Right side - vertically stacked stats cards (bigger and closer to edge)
            VStack(spacing: 15) {
                // Tasks Completed Today
                QuickStatCard(
                    title: "Tasks Done",
                    value: "\(dashboardDataService.dashboardStats.tasksCompletedToday)",
                    subtitle: "of \(dashboardDataService.dashboardStats.tasksTotalToday) today",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    progress: dashboardDataService.dashboardStats.tasksProgress,
                    action: {
                        selectedView = .tasks
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)) {
                            isMenuOpen = false
                        }
                    }
                )
                .scaleEffect(0.7)
                .frame(width: 180, height: 90)
                
                // Notes Created
                QuickStatCard(
                    title: "Notes",
                    value: "\(dashboardDataService.dashboardStats.notesThisWeek)",
                    subtitle: "this week",
                    icon: "note.text",
                    color: .blue,
                    progress: dashboardDataService.dashboardStats.notesProgress,
                    action: {
                        selectedView = .notes
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)) {
                            isMenuOpen = false
                        }
                    }
                )
                .scaleEffect(0.7)
                .frame(width: 180, height: 90)
                
                // Journal Entries
                QuickStatCard(
                    title: "Journal",
                    value: "\(dashboardDataService.dashboardStats.journalEntriesToday)",
                    subtitle: "entries today",
                    icon: "book.fill",
                    color: .purple,
                    progress: dashboardDataService.dashboardStats.journalProgress,
                    action: {
                        selectedView = .journal
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)) {
                            isMenuOpen = false
                        }
                    }
                )
                .scaleEffect(0.7)
                .frame(width: 180, height: 90)
                
            }
            .padding(.trailing, 0)
        }
        .padding(.top, 24)
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
                dragOffset = min(translation, menuWidth)
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
            // Opening gesture ended - more sensitive to velocity
            if translation > menuWidth * 0.25 || velocity > 300 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)) {
                    isMenuOpen = true
                    dragOffset = 0
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9, blendDuration: 0.1)) {
                    dragOffset = 0
                }
            }
        } else {
            // Closing gesture ended - more sensitive to velocity
            if translation < -30 || velocity < -300 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)) {
                    isMenuOpen = false
                    dragOffset = 0
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9, blendDuration: 0.1)) {
                    dragOffset = 0
                }
            }
        }
    }
    
    // MARK: - Navigation Bar Configuration
    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        appearance.shadowColor = UIColor.clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor.white
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
