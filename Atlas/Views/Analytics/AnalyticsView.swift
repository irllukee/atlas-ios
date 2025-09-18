import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingExportSheet = false
    @State private var selectedTab: AnalyticsTab = .overview
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    enum AnalyticsTab: String, CaseIterable {
        case overview = "Overview"
        case charts = "Charts"
        case trends = "Trends"
        case widgets = "Widgets"
        case export = "Export"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .charts: return "chart.line.uptrend.xyaxis"
            case .trends: return "chart.xyaxis.line"
            case .widgets: return "square.grid.2x2.fill"
            case .export: return "square.and.arrow.down.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                            AnalyticsTabButton(
                                tab: tab,
                                isSelected: selectedTab == tab,
                                action: { selectedTab = tab }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(AtlasTheme.Colors.glassBackground)
                
                // Content
                ZStack {
                    AtlasTheme.Colors.background
                        .ignoresSafeArea()
                    
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Header Section
                            headerSection
                            
                            // Time Range Selector
                            timeRangeSelector
                            
                            // Tab Content
                            switch selectedTab {
                            case .overview:
                                overviewContent
                            case .charts:
                                chartsContent
                            case .trends:
                                trendsContent
                            case .widgets:
                                widgetsContent
                            case .export:
                                exportContent
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadAnalytics(for: AnalyticsTimeRange(rawValue: selectedTimeRange.rawValue) ?? .week)
            }
            .onChange(of: selectedTimeRange) { _, newRange in
                viewModel.loadAnalytics(for: AnalyticsTimeRange(rawValue: newRange.rawValue) ?? .week)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Life Insights")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Track your progress and discover patterns")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        HStack(spacing: 12) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: { selectedTimeRange = range }) {
                    Text(range.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeRange == range ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTimeRange == range ? AtlasTheme.Colors.primary : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AtlasTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Overview Cards Section
    private var overviewCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            OverviewCard(
                title: "Tasks Completed",
                value: "\(viewModel.analyticsData.tasksCompleted)",
                change: viewModel.analyticsData.taskCompletionChange,
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            OverviewCard(
                title: "Notes Created",
                value: "\(viewModel.analyticsData.notesCreated)",
                change: viewModel.analyticsData.notesChange,
                icon: "note.text",
                color: .blue
            )
            
            OverviewCard(
                title: "Journal Entries",
                value: "\(viewModel.analyticsData.journalEntries)",
                change: viewModel.analyticsData.journalChange,
                icon: "book.fill",
                color: .purple
            )
            
            OverviewCard(
                title: "Avg Mood",
                value: String(format: "%.1f", viewModel.analyticsData.averageMood),
                change: viewModel.analyticsData.moodChange,
                icon: "heart.fill",
                color: .pink
            )
        }
    }
    
    // MARK: - Productivity Trends Section
    private var productivityTrendsSection: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(AtlasTheme.Colors.primary)
                    Text("Productivity Trends")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                if !viewModel.analyticsData.productivityData.isEmpty {
                    Chart(viewModel.analyticsData.productivityData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Tasks", dataPoint.tasksCompleted)
                        )
                        .foregroundStyle(AtlasTheme.Colors.primary)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Tasks", dataPoint.tasksCompleted)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AtlasTheme.Colors.primary.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                            AxisGridLine()
                                .foregroundStyle(.white.opacity(0.2))
                            AxisTick()
                                .foregroundStyle(.white.opacity(0.6))
                            AxisValueLabel()
                                .foregroundStyle(.white.opacity(0.8))
                                .font(.caption)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                                .foregroundStyle(.white.opacity(0.2))
                            AxisTick()
                                .foregroundStyle(.white.opacity(0.6))
                            AxisValueLabel()
                                .foregroundStyle(.white.opacity(0.8))
                                .font(.caption)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Complete some tasks to see your productivity trends")
                    )
                    .frame(height: 200)
                }
            }
        }
    }
    
    // MARK: - Mood Analytics Section
    private var moodAnalyticsSection: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                    Text("Mood Analytics")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                if !viewModel.analyticsData.moodData.isEmpty {
                    Chart(viewModel.analyticsData.moodData) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Mood", dataPoint.moodValue)
                        )
                        .foregroundStyle(.pink)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Mood", dataPoint.moodValue)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 1...5)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                            AxisGridLine()
                                .foregroundStyle(.white.opacity(0.2))
                            AxisTick()
                                .foregroundStyle(.white.opacity(0.6))
                            AxisValueLabel()
                                .foregroundStyle(.white.opacity(0.8))
                                .font(.caption)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                                .foregroundStyle(.white.opacity(0.2))
                            AxisTick()
                                .foregroundStyle(.white.opacity(0.6))
                            AxisValueLabel()
                                .foregroundStyle(.white.opacity(0.8))
                                .font(.caption)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Mood Data",
                        systemImage: "heart.fill",
                        description: Text("Log your mood to see trends and insights")
                    )
                    .frame(height: 200)
                }
            }
        }
    }
    
    // MARK: - Task Analytics Section
    private var taskAnalyticsSection: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Task Completion")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completion Rate")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(Int(viewModel.analyticsData.taskCompletionRate * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Avg per Day")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(String(format: "%.1f", viewModel.analyticsData.averageTasksPerDay))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                // Task Priority Distribution
                if !viewModel.analyticsData.taskPriorityData.isEmpty {
                    Chart(viewModel.analyticsData.taskPriorityData) { dataPoint in
                        BarMark(
                            x: .value("Priority", dataPoint.priority),
                            y: .value("Count", dataPoint.count)
                        )
                        .foregroundStyle(by: .value("Priority", dataPoint.priority))
                    }
                    .frame(height: 150)
                    .chartForegroundStyleScale([
                        "High": .red,
                        "Medium": .orange,
                        "Low": .green
                    ])
                }
            }
        }
    }
    
    // MARK: - Journal Insights Section
    private var journalInsightsSection: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(.purple)
                    Text("Journal Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Entries")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(viewModel.analyticsData.journalEntries)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Streak")
                            .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        Text("\(viewModel.analyticsData.journalStreak) days")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                // Journal Entry Types
                if !viewModel.analyticsData.journalTypeData.isEmpty {
                    Chart(viewModel.analyticsData.journalTypeData) { dataPoint in
                        SectorMark(
                            angle: .value("Count", dataPoint.count),
                            innerRadius: .ratio(0.4),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("Type", dataPoint.type))
                    }
                    .frame(height: 150)
                    .chartForegroundStyleScale([
                        "Daily": .blue,
                        "Dream": .purple,
                        "Gratitude": .yellow,
                        "Reflection": .green
                    ])
                }
            }
        }
    }
    
    // MARK: - Notes Analytics Section
    private var notesAnalyticsSection: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.blue)
                    Text("Notes Analytics")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Notes")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(viewModel.analyticsData.notesCreated)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Avg Length")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(viewModel.analyticsData.averageNoteLength) chars")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                // Notes Creation Timeline
                if !viewModel.analyticsData.notesData.isEmpty {
                    Chart(viewModel.analyticsData.notesData) { dataPoint in
                        BarMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Notes", dataPoint.notesCreated)
                        )
                        .foregroundStyle(.blue.opacity(0.7))
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                            AxisGridLine()
                                .foregroundStyle(.white.opacity(0.2))
                            AxisTick()
                                .foregroundStyle(.white.opacity(0.6))
                            AxisValueLabel()
                                .foregroundStyle(.white.opacity(0.8))
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Tab Content Views
    
    @ViewBuilder
    private var overviewContent: some View {
        // Overview Cards
        overviewCardsSection
        
        // Productivity Trends
        productivityTrendsSection
        
        // Mood Analytics
        moodAnalyticsSection
        
        // Task Completion Analytics
        taskAnalyticsSection
        
        // Journal Insights
        journalInsightsSection
        
        // Notes Analytics
        notesAnalyticsSection
    }
    
    @ViewBuilder
    private var chartsContent: some View {
        VStack(spacing: 20) {
            // Sample charts - in a real app, these would use actual data from viewModel
            let sampleData = Array((0..<30).map { day in
                ChartDataPoint(
                    date: Calendar.current.date(byAdding: .day, value: -day, to: Date()) ?? Date(),
                    value: Double.random(in: 0...100)
                )
            }.reversed())
            
            let categoryData = [
                CategoryDataPoint(category: "High", value: 25, color: .red),
                CategoryDataPoint(category: "Medium", value: 45, color: .orange),
                CategoryDataPoint(category: "Low", value: 30, color: .green)
            ]
            
            AnalyticsLineChart(
                data: sampleData,
                title: "Task Completion Trend",
                yAxisLabel: "Tasks",
                color: .blue
            )
            
            HStack(spacing: 16) {
                AnalyticsPieChart(
                    data: categoryData,
                    title: "Task Priority"
                )
                
                AnalyticsProgressRing(
                    value: 75,
                    maxValue: 100,
                    title: "Completion Rate",
                    color: .blue,
                    lineWidth: 8
                )
            }
        }
    }
    
    @ViewBuilder
    private var trendsContent: some View {
        TrendAnalysisView()
    }
    
    @ViewBuilder
    private var widgetsContent: some View {
        DashboardWidgetsView()
    }
    
    @ViewBuilder
    private var exportContent: some View {
        DataExportView()
    }
}

// MARK: - Analytics Tab Button
struct AnalyticsTabButton: View {
    let tab: AnalyticsView.AnalyticsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.caption)
                
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? AtlasTheme.Colors.primary : .clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Overview Card Component
struct OverviewCard: View {
    let title: String
    let value: String
    let change: Double
    let icon: String
    let color: Color
    
    var body: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                    
                    if change != 0 {
                        HStack(spacing: 4) {
                            Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                            Text("\(abs(Int(change)))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(change > 0 ? .green : .red)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Choose what data you'd like to export")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    ExportOption(
                        title: "Analytics Summary",
                        description: "Overview of your productivity and habits",
                        icon: "chart.bar.fill"
                    ) {
                        viewModel.exportAnalyticsSummary()
                    }
                    
                    ExportOption(
                        title: "All Data",
                        description: "Complete export of notes, tasks, and journal entries",
                        icon: "square.and.arrow.down.fill"
                    ) {
                        viewModel.exportAllData()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExportOption: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(AtlasTheme.Colors.primary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AnalyticsView()
}
