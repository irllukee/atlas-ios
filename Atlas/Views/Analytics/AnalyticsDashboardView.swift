import SwiftUI
import Charts

/// Comprehensive analytics dashboard with beautiful visualizations
struct AnalyticsDashboardView: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingInsights = false
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Header with productivity score
                    productivityScoreCard
                    
                    // Quick stats grid
                    quickStatsGrid
                    
                    // Habit tracking chart
                    habitTrackingChart
                    
                    // Mood trends chart
                    moodTrendsChart
                    
                    // Productivity insights
                    productivityInsightsCard
                    
                    // Detailed statistics
                    detailedStatsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.blue.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(range.rawValue) {
                                selectedTimeRange = range
                            }
                        }
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        analyticsService.refreshAnalytics()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                analyticsService.refreshAnalytics()
            }
        }
    }
    
    // MARK: - Productivity Score Card
    
    private var productivityScoreCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Productivity Score")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Today's Performance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: analyticsService.productivityMetrics.productivityScore / 100)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: analyticsService.productivityMetrics.productivityScore)
                    
                    Text("\(Int(analyticsService.productivityMetrics.productivityScore))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Streak",
                    value: "\(analyticsService.productivityMetrics.streakDays)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatItem(
                    title: "Words",
                    value: "\(analyticsService.productivityMetrics.totalWordsWritten)",
                    icon: "textformat.abc",
                    color: .green
                )
                
                StatItem(
                    title: "Notes",
                    value: "\(analyticsService.productivityMetrics.notesCreatedToday)",
                    icon: "note.text",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Quick Stats Grid
    
    private var quickStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            QuickStatCard(
                title: "Tasks Completed",
                value: "\(analyticsService.productivityMetrics.tasksCompletedToday)",
                subtitle: "Today",
                icon: "checkmark.circle.fill",
                color: .green,
                progress: 0.8
            )
            
            QuickStatCard(
                title: "Journal Entries",
                value: "\(analyticsService.productivityMetrics.journalEntriesToday)",
                subtitle: "Today",
                icon: "book.fill",
                color: .purple,
                progress: 0.6
            )
            
            QuickStatCard(
                title: "Completion Rate",
                value: "\(Int(analyticsService.taskAnalytics.completionRate))%",
                subtitle: "Overall",
                icon: "chart.bar.fill",
                color: .blue,
                progress: analyticsService.taskAnalytics.completionRate / 100
            )
            
            QuickStatCard(
                title: "Overdue Tasks",
                value: "\(analyticsService.taskAnalytics.overdueTasks)",
                subtitle: "Need Attention",
                icon: "exclamationmark.triangle.fill",
                color: .red,
                progress: 0.3
            )
        }
    }
    
    // MARK: - Habit Tracking Chart
    
    private var habitTrackingChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Habit Tracking")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(analyticsService.habitData.prefix(7)) { habit in
                        LineMark(
                            x: .value("Date", habit.date),
                            y: .value("Count", habit.value)
                        )
                        .foregroundStyle(by: .value("Habit", habit.habitType.rawValue))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }
                }
                .frame(height: 200)
                .chartForegroundStyleScale([
                    "Notes Created": .blue,
                    "Tasks Completed": .green,
                    "Journal Entries": .purple
                ])
            } else {
                // Fallback for iOS 15
                VStack {
                    Text("Charts require iOS 16+")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Mood Trends Chart
    
    private var moodTrendsChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Trends")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(analyticsService.moodTrends.prefix(7)) { trend in
                        AreaMark(
                            x: .value("Date", trend.date),
                            y: .value("Mood", trend.averageMood)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 200)
            } else {
                // Fallback for iOS 15
                VStack {
                    Text("Charts require iOS 16+")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Productivity Insights Card
    
    private var productivityInsightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Productivity Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    showingInsights.toggle()
                } label: {
                    Image(systemName: showingInsights ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            
            if showingInsights {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(analyticsService.getProductivityInsights(), id: \.self) { insight in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.title3)
                            
                            Text(insight)
                                .font(.body)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .animation(.easeInOut(duration: 0.3), value: showingInsights)
    }
    
    // MARK: - Detailed Statistics Section
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                StatRow(
                    title: "Total Notes",
                    value: "\(analyticsService.noteStatistics.totalNotes)"
                )
                
                StatRow(
                    title: "Notes This Week",
                    value: "\(analyticsService.noteStatistics.notesThisWeek)"
                )
                
                StatRow(
                    title: "Average Note Length",
                    value: "\(Int(analyticsService.noteStatistics.averageNoteLength)) chars"
                )
                
                StatRow(
                    title: "Most Productive Day",
                    value: analyticsService.noteStatistics.mostProductiveDay
                )
                
                StatRow(
                    title: "Notes with Images",
                    value: "\(analyticsService.noteStatistics.notesWithImages)"
                )
                
                StatRow(
                    title: "Notes with Tables",
                    value: "\(analyticsService.noteStatistics.notesWithTables)"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}



#Preview {
    AnalyticsDashboardView()
}
