import SwiftUI
import Charts
import CoreData

// MARK: - Mood Analytics View
struct MoodAnalyticsView: View {
    @ObservedObject var viewModel: JournalViewModel
    @State private var selectedTimeframe = MoodTimeframe.month
    @State private var analytics: MoodAnalytics?
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AtlasTheme.Spacing.lg) {
                    timeframeSelector
                    
                    if isLoading {
                        loadingView
                    } else if let analytics = analytics {
                        statisticsSection(analytics: analytics)
                        moodChartSection(analytics: analytics)
                        bestDaySection(analytics: analytics)
                    } else {
                        emptyStateView
                    }
                }
                .padding(AtlasTheme.Spacing.md)
            }
        }
        .onAppear {
            loadAnalytics()
        }
        .onChange(of: selectedTimeframe) { _, _ in
            loadAnalytics()
        }
    }
    
    // MARK: - View Components
    
    private var timeframeSelector: some View {
        FrostedCard(style: .standard) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                Text("Analytics Period")
                    .font(AtlasTheme.Typography.headline)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(MoodTimeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.displayName).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedTimeframe) { _, _ in
                    AtlasTheme.Haptics.selection()
                }
            }
        }
    }
    
    private var loadingView: some View {
        FrostedCard(style: .standard) {
            VStack(spacing: AtlasTheme.Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(AtlasTheme.Colors.accent)
                
                Text("Loading analytics...")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
            }
            .frame(height: 200)
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: "No data yet",
            subtitle: "Start logging your moods to see analytics",
            buttonTitle: "Log Mood",
            action: { 
                AtlasTheme.Haptics.medium()
                // Navigate to mood tracking 
            }
        )
    }
    
    private func statisticsSection(analytics: MoodAnalytics) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AtlasTheme.Spacing.md) {
            StatCard(
                title: "Average Mood",
                value: String(format: "%.1f", analytics.averageMood),
                subtitle: "This month",
                icon: "heart.fill",
                color: AtlasTheme.Colors.positive
            )
            
            StatCard(
                title: "Total Entries",
                value: "\(analytics.totalEntries)",
                subtitle: "Logged",
                icon: "chart.bar.fill",
                color: AtlasTheme.Colors.info
            )
            
            StatCard(
                title: "Best Mood",
                value: "\(analytics.bestMood)",
                subtitle: "Peak",
                icon: "star.fill",
                color: AtlasTheme.Colors.warning
            )
            
            StatCard(
                title: "Consistency",
                value: "\(Int(analytics.consistencyScore))%",
                subtitle: "Score",
                icon: "target",
                color: AtlasTheme.Colors.success
            )
        }
    }
    
    @ViewBuilder
    private func moodChartSection(analytics: MoodAnalytics) -> some View {
        if !analytics.moodTrend.isEmpty {
            moodTrendChart(analytics: analytics)
        }
    }
    
    private func moodTrendChart(analytics: MoodAnalytics) -> some View {
        FrostedCard(style: .standard) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                Text("Mood Trend")
                    .font(AtlasTheme.Typography.headline)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Chart(analytics.moodTrend) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Mood", dataPoint.moodValue)
                    )
                    .foregroundStyle(AtlasTheme.Colors.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                .frame(height: 200)
                .chartYScale(domain: 1...10)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedTimeframe == .week ? 1 : 7)) { value in
                        AxisGridLine()
                            .foregroundStyle(AtlasTheme.Colors.glassBorderLight)
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .foregroundStyle(AtlasTheme.Colors.secondaryText)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(AtlasTheme.Colors.glassBorderLight)
                        AxisTick()
                        AxisValueLabel()
                            .foregroundStyle(AtlasTheme.Colors.secondaryText)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func bestDaySection(analytics: MoodAnalytics) -> some View {
        if let bestDay = analytics.bestDay {
            bestDayCard(bestDay: bestDay, analytics: analytics)
        }
    }
    
    private func bestDayCard(bestDay: Date, analytics: MoodAnalytics) -> some View {
        FrostedCard(style: .standard) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                Text("Best Day")
                    .font(AtlasTheme.Typography.headline)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                HStack {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                        Text(bestDay.formatted(date: .complete, time: .omitted))
                            .font(AtlasTheme.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AtlasTheme.Colors.text)
                        
                        Text("Mood: \(analytics.bestMood)/10")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text("🌟")
                        .font(.largeTitle)
                }
            }
        }
    }
    
    private func loadAnalytics() {
        _Concurrency.Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            
            do {
                let repository = DependencyContainer.shared.journalRepository
                analytics = try repository.getMoodAnalytics(for: selectedTimeframe)
            } catch {
                print("Error loading analytics: \(error)")
            }
        }
    }
}

