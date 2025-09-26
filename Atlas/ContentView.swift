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
    
    // Menu properties
    private let menuWidth: CGFloat = 280
    private let maxDragDistance: CGFloat = 50
    
    // Animation states for dashboard
    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = 30
    @State private var statsOpacity: Double = 0
    @State private var statsOffset: CGFloat = 30
    
    // MARK: - Initialization
    init() {
        // Lazy initialization to avoid blocking app startup
        // Services will be created on first access for better performance
        self._dashboardDataService = StateObject(wrappedValue: DashboardDataService.lazy)
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
                selectedViewContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: isMenuOpen ? menuWidth + dragOffset : dragOffset)
                    .animation(AtlasTheme.Animations.optimizedSpring, value: isMenuOpen)
                    .zIndex(1)
                    .onTapGesture {
                        if isMenuOpen {
                            withAnimation(AtlasTheme.Animations.optimizedSpring) {
                                isMenuOpen = false
                                dragOffset = 0
                            }
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 10) // Added minimum distance to prevent accidental drags
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
            
            // Removed performance metrics logging
        }
        .sheet(isPresented: $showingProfilePictureEditor) {
            ProfilePictureEditorView()
        }
        .withErrorHandling()
    }
    
    // MARK: - Current View (removed - using selectedViewContent instead)
    

    // MARK: - View Selection
    private var selectedViewContent: some View {
        Group {
            switch selectedView {
            case .dashboard:
                dashboardView
            case .journal:
                JournalView()
            case .notes:
                NotesListView()
            case .tasks:
                TasksView()
            case .watchlist:
                WatchlistView(dataManager: dataManager)
            case .recipes:
                RecipesView()
            case .eatDo:
                EatDoView()
            case .mindMapping:
                MindMappingViewV2(dataManager: dataManager)
            case .profile:
                ProfileView()
            }
        }
    }
    
    // MARK: - Side Menu
    private var sideMenu: some View {
        HStack {
            sideMenuContent
            Spacer()
        }
    }
    
    private var sideMenuContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sideMenuHeader
            sideMenuItems
            Spacer()
            sideMenuFooter
        }
        .frame(width: menuWidth)
        .background(AtlasTheme.Colors.background.edgesIgnoringSafeArea(.all))
        .offset(x: isMenuOpen ? 0 : -menuWidth)
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1), value: isMenuOpen)
    }
    
    private var sideMenuHeader: some View {
        HStack {
            Text("Atlas")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AtlasTheme.Colors.primary)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isMenuOpen = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(AtlasTheme.Colors.primary)
            }
        }
        .padding(.top, 50)
        .padding(.horizontal, 20)
    }
    
    private var sideMenuItems: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(AppView.allCases, id: \.self) { view in
                sideMenuItem(for: view)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func sideMenuItem(for view: AppView) -> some View {
        Button(action: {
            // Add small delay to prevent rapid navigation updates
            _Concurrency.Task { @MainActor in
                try? await _Concurrency.Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                selectedView = view
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                isMenuOpen = false
            }
        }) {
            HStack {
                Image(systemName: view.iconName)
                    .font(.title2)
                    .foregroundColor(selectedView == view ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondary)
                    .frame(width: 30)
                
                Text(view.title)
                    .font(.headline)
                    .foregroundColor(selectedView == view ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondary)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 15)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedView == view ? AtlasTheme.Colors.primary.opacity(0.1) : Color.clear)
            )
        }
    }
    
    private var sideMenuFooter: some View {
        VStack(alignment: .leading, spacing: 15) {
            Button(action: {
                // Handle settings
            }) {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.secondary)
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(AtlasTheme.Colors.secondary)
                }
            }
            Button(action: {
                securityManager.logout()
            }) {
                HStack {
                    Image(systemName: "arrow.right.square.fill")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.secondary)
                    Text("Logout")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(AtlasTheme.Colors.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - Dashboard View
    private var dashboardView: some View {
        ZStack {
            // Background gradient
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Modern Header Section
                    modernHeaderSection
                        .opacity(headerOpacity)
                        .offset(y: headerOffset)
                    
                    // Quick Stats Grid
                    quickStatsGrid
                        .opacity(statsOpacity)
                        .offset(y: statsOffset)
                    
                    // Bottom Spacing
                    Spacer(minLength: 120) // Increased for floating action buttons
                }
                .padding(.horizontal, 20)
            }
            .onAppear {
                // Refresh dashboard data
                dashboardDataService.loadDashboardData()
                
                // Single coordinated animation to prevent AnimatablePair conflicts
                withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                    headerOpacity = 1
                    headerOffset = 0
                    statsOpacity = 1
                    statsOffset = 0
                }
            }
            
            // Floating Action Buttons
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    QuickActionButtons(selectedView: $selectedView)
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
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
                
                // Notes
                QuickStatCard(
                    title: "Notes",
                    value: "\(dataManager.getAppStatistics().notesToday)",
                    subtitle: "created today",
                    icon: "doc.text",
                    color: .orange,
                    progress: 0.6, // TODO: Calculate notes progress
                    action: {
                        selectedView = .notes
                        withAnimation(AtlasTheme.Animations.optimizedSpring) {
                            isMenuOpen = false
                        }
                    }
                )
                .scaleEffect(0.7)
                .frame(width: 180, height: 90)
                
                // Journal
                QuickStatCard(
                    title: "Journal",
                    value: "0", // TODO: Get journal entries count
                    subtitle: "entries today",
                    icon: "book.pages",
                    color: .purple,
                    progress: 0.3, // TODO: Calculate journal progress
                    action: {
                        selectedView = .journal
                        withAnimation(AtlasTheme.Animations.optimizedSpring) {
                            isMenuOpen = false
                        }
                    }
                )
                .scaleEffect(0.7)
                .frame(width: 180, height: 90)
                
                // Tasks
                QuickStatCard(
                    title: "Tasks",
                    value: "0", // TODO: Get tasks count
                    subtitle: "pending today",
                    icon: "checkmark.circle",
                    color: .green,
                    progress: 0.5, // TODO: Calculate tasks progress
                    action: {
                        selectedView = .tasks
                        withAnimation(AtlasTheme.Animations.optimizedSpring) {
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
            
            // Throttle updates to reduce navigation observer warnings
            let newOffset = if !isMenuOpen {
                min(translation, menuWidth)
            } else {
                min(translation, 0)
            }
            
            // Only update if the change is significant enough
            if abs(newOffset - dragOffset) > 2 {
                dragOffset = newOffset
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
                withAnimation(AtlasTheme.Animations.optimizedSpring) {
                    isMenuOpen = true
                    dragOffset = 0
                }
            } else {
                withAnimation(AtlasTheme.Animations.optimizedGentle) {
                    dragOffset = 0
                }
            }
        } else {
            // Closing gesture ended - more sensitive to velocity
            if translation < -30 || velocity < -300 {
                withAnimation(AtlasTheme.Animations.optimizedSpring) {
                    isMenuOpen = false
                    dragOffset = 0
                }
            } else {
                withAnimation(AtlasTheme.Animations.optimizedGentle) {
                    dragOffset = 0
                }
            }
        }
    }
    
    // MARK: - Navigation Bar Configuration
    @MainActor
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
