import SwiftUI

/// Main navigation view for all analytics features
struct AnalyticsNavigationView: View {
    @State private var selectedTab: AnalyticsTab = .dashboard
    
    enum AnalyticsTab: String, CaseIterable {
        case dashboard = "Dashboard"
        case habits = "Habits"
        case insights = "Insights"
        case widgets = "Widgets"
        
        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .habits: return "target"
            case .insights: return "lightbulb.fill"
            case .widgets: return "square.grid.2x2.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .dashboard: return .blue
            case .habits: return .green
            case .insights: return .purple
            case .widgets: return .orange
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    AnalyticsDashboardView()
                        .tag(AnalyticsTab.dashboard)
                    
                    HabitTrackingView()
                        .tag(AnalyticsTab.habits)
                    
                    ProductivityInsightsView()
                        .tag(AnalyticsTab.insights)
                    
                    DashboardWidgetsView()
                        .tag(AnalyticsTab.widgets)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Refresh all analytics
                        AnalyticsService.shared.refreshAnalytics()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.title2)
                            .foregroundColor(selectedTab == tab ? tab.color : .gray)
                        
                        Text(tab.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == tab ? tab.color : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == tab ? tab.color.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

#Preview {
    AnalyticsNavigationView()
}
