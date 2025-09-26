import SwiftUI

struct EatDoView: View {
    @StateObject private var eatDoService = EatDoService()
    @State private var selectedTab = 0
    @State private var showingAddRestaurant = false
    @State private var showingAddActivity = false
    @State private var showingStats = false
    
    var body: some View {
        ZStack {
            // Atlas Background
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with Stats
                headerView
                
                // Custom Tab Picker with Atlas styling
                tabPickerView
                
                // Content based on selected tab
                if selectedTab == 0 {
                    RestaurantListView(
                        eatDoService: eatDoService,
                        showingAddRestaurant: $showingAddRestaurant
                    )
                } else {
                    ActivityListView(
                        eatDoService: eatDoService,
                        showingAddActivity: $showingAddActivity
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddRestaurant) {
            AddEditRestaurantView(eatDoService: eatDoService)
        }
        .sheet(isPresented: $showingAddActivity) {
            AddEditActivityView(eatDoService: eatDoService)
        }
        .sheet(isPresented: $showingStats) {
            EatDoStatsView(eatDoService: eatDoService)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Eat & Do")
                        .font(AtlasTheme.Typography.largeTitle)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    Text("Track your favorite places")
                        .font(AtlasTheme.Typography.subheadline)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                }
                
                Spacer()
                
                // Stats Button
                Button(action: {
                    AtlasTheme.Haptics.light()
                    showingStats = true
                }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.accent)
                        .frame(width: 44, height: 44)
                        .glassmorphism(style: .light, cornerRadius: 22)
                }
            }
            
            // Quick Stats Row
            quickStatsView
        }
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.top, AtlasTheme.Spacing.md)
    }
    
    // MARK: - Quick Stats
    private var quickStatsView: some View {
        HStack(spacing: AtlasTheme.Spacing.md) {
            // Restaurants Count
            QuickStatCard(
                title: "Restaurants",
                value: "\(eatDoService.restaurants.count)",
                subtitle: "saved",
                icon: "fork.knife",
                color: AtlasTheme.Colors.primary,
                progress: min(Double(eatDoService.restaurants.count) / 20.0, 1.0)
            )
            
            // Activities Count
            QuickStatCard(
                title: "Activities",
                value: "\(eatDoService.activities.count)",
                subtitle: "saved",
                icon: "figure.walk",
                color: AtlasTheme.Colors.secondary,
                progress: min(Double(eatDoService.activities.count) / 20.0, 1.0)
            )
        }
    }
    
    // MARK: - Tab Picker
    private var tabPickerView: some View {
        HStack(spacing: 0) {
            ForEach(0..<2) { index in
                Button(action: {
                    AtlasTheme.Haptics.selection()
                    withAnimation(AtlasTheme.Animations.smooth) {
                        selectedTab = index
                    }
                }) {
                    Text(index == 0 ? "Restaurants" : "Activities")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(selectedTab == index ? AtlasTheme.Colors.text : AtlasTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AtlasTheme.Spacing.md)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                .fill(AtlasTheme.Colors.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                        .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.bottom, AtlasTheme.Spacing.md)
    }
}

#Preview {
    EatDoView()
}