import SwiftUI
import Charts

// MARK: - Trend Analysis Models
struct TrendData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let category: String
    let metadata: [String: Any]?
    
    init(date: Date, value: Double, category: String, metadata: [String: Any]? = nil) {
        self.date = date
        self.value = value
        self.category = category
        self.metadata = metadata
    }
}

struct TrendInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: InsightType
    let confidence: Double
    let actionable: Bool
    let recommendation: String?
    
    enum InsightType {
        case positive
        case negative
        case neutral
        case warning
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .negative: return .red
            case .neutral: return .blue
            case .warning: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .positive: return "arrow.up.circle.fill"
            case .negative: return "arrow.down.circle.fill"
            case .neutral: return "minus.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
    }
}

struct HabitStreak: Identifiable {
    let id = UUID()
    let habitName: String
    let currentStreak: Int
    let longestStreak: Int
    let completionRate: Double
    let lastCompleted: Date?
    let color: Color
}

// MARK: - Trend Analysis View
struct TrendAnalysisView: View {
    @StateObject private var viewModel = TrendAnalysisViewModel()
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var selectedCategory: String = "All"
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Timeframe and Category Selector
                VStack(spacing: 16) {
                    HStack {
                        Text("Time Frame")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Picker("Time Frame", selection: $selectedTimeframe) {
                            ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                                Text(timeframe.rawValue).tag(timeframe)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 200)
                    }
                    
                    HStack {
                        Text("Category")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Picker("Category", selection: $selectedCategory) {
                            Text("All").tag("All")
                            Text("Tasks").tag("Tasks")
                            Text("Notes").tag("Notes")
                            Text("Journal").tag("Journal")
                            Text("Mood").tag("Mood")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                
                // Key Insights
                if !viewModel.insights.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Insights")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 12) {
                            ForEach(viewModel.insights) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                    }
                }
                
                // Productivity Trends
                if !viewModel.productivityTrends.isEmpty {
                    ChartContainer(title: "Productivity Trends") {
                        Chart(viewModel.productivityTrends) { trend in
                            LineMark(
                                x: .value("Date", trend.date),
                                y: .value("Value", trend.value)
                            )
                            .foregroundStyle(by: .value("Category", trend.category))
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
                            AreaMark(
                                x: .value("Date", trend.date),
                                y: .value("Value", trend.value)
                            )
                            .foregroundStyle(by: .value("Category", trend.category))
                            .opacity(0.3)
                        }
                        .frame(height: 250)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                    .foregroundStyle(.secondary.opacity(0.3))
                                AxisValueLabel()
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: max(1, selectedTimeframe.days / 7))) { value in
                                AxisGridLine()
                                    .foregroundStyle(.secondary.opacity(0.3))
                                AxisValueLabel(format: .dateTime.month().day())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartForegroundStyleScale([
                            "Tasks": .blue,
                            "Notes": .green,
                            "Journal": .purple,
                            "Mood": .orange
                        ])
                    }
                }
                
                // Habit Streaks
                if !viewModel.habitStreaks.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Habit Streaks")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(viewModel.habitStreaks) { streak in
                                HabitStreakCard(streak: streak)
                            }
                        }
                    }
                }
                
                // Weekly Patterns
                if !viewModel.weeklyPatterns.isEmpty {
                    ChartContainer(title: "Weekly Patterns") {
                        Chart(viewModel.weeklyPatterns) { pattern in
                            BarMark(
                                x: .value("Day", pattern.category),
                                y: .value("Value", pattern.value)
                            )
                            .foregroundStyle(pattern.color)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                    .foregroundStyle(.secondary.opacity(0.3))
                                AxisValueLabel()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Correlation Analysis
                if !viewModel.correlations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Correlation Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 12) {
                            ForEach(viewModel.correlations, id: \.id) { correlation in
                                CorrelationCard(correlation: correlation)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Trend Analysis")
        .onAppear {
            viewModel.loadTrendData(timeframe: selectedTimeframe, category: selectedCategory)
        }
        .onChange(of: selectedTimeframe) { _, newValue in
            viewModel.loadTrendData(timeframe: newValue, category: selectedCategory)
        }
        .onChange(of: selectedCategory) { _, newValue in
            viewModel.loadTrendData(timeframe: selectedTimeframe, category: newValue)
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: TrendInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.title2)
                .foregroundColor(insight.type.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                if let recommendation = insight.recommendation {
                    Text(recommendation)
                        .font(.caption)
                        .foregroundColor(insight.type.color)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("Confidence")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Habit Streak Card
struct HabitStreakCard: View {
    let streak: HabitStreak
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(streak.color)
                    .frame(width: 12, height: 12)
                
                Text(streak.habitName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(streak.currentStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(streak.longestStreak)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Best Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Completion Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(streak.completionRate * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                ProgressView(value: streak.completionRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: streak.color))
            }
            
            if let lastCompleted = streak.lastCompleted {
                Text("Last completed: \(lastCompleted, formatter: DateFormatter.shortDate)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Correlation Card
struct CorrelationCard: View {
    let correlation: (id: UUID, title: String, description: String, strength: Double, type: String)
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("\(Int(abs(correlation.strength) * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(correlation.strength > 0 ? .green : .red)
                
                Text("Correlation")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(correlation.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(correlation.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Text("Type: \(correlation.type)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(correlation.strength > 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Trend Analysis ViewModel
@MainActor
class TrendAnalysisViewModel: ObservableObject {
    @Published var insights: [TrendInsight] = []
    @Published var productivityTrends: [TrendData] = []
    @Published var habitStreaks: [HabitStreak] = []
    @Published var weeklyPatterns: [CategoryDataPoint] = []
    @Published var correlations: [(id: UUID, title: String, description: String, strength: Double, type: String)] = []
    @Published var isLoading = false
    
    func loadTrendData(timeframe: TrendAnalysisView.TimeFrame, category: String) {
        isLoading = true
        
        // Simulate data loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.generateSampleData(timeframe: timeframe, category: category)
            self.isLoading = false
        }
    }
    
    private func generateSampleData(timeframe: TrendAnalysisView.TimeFrame, category: String) {
        // Generate sample insights
        insights = [
            TrendInsight(
                title: "Productivity Peak",
                description: "Your productivity is highest on Tuesdays and Wednesdays. Consider scheduling important tasks on these days.",
                type: .positive,
                confidence: 0.85,
                actionable: true,
                recommendation: "Schedule complex tasks for Tuesday/Wednesday"
            ),
            TrendInsight(
                title: "Mood Correlation",
                description: "Your mood shows a strong positive correlation with journaling frequency.",
                type: .positive,
                confidence: 0.78,
                actionable: true,
                recommendation: "Maintain daily journaling habit"
            ),
            TrendInsight(
                title: "Task Completion Decline",
                description: "Task completion rates have decreased by 15% over the past week.",
                type: .warning,
                confidence: 0.72,
                actionable: true,
                recommendation: "Review task priorities and break down large tasks"
            )
        ]
        
        // Generate sample productivity trends
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -timeframe.days, to: endDate) ?? endDate
        
        productivityTrends = (0..<timeframe.days).compactMap { dayOffset -> [TrendData]? in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { return nil }
            
            return [
                TrendData(date: date, value: Double.random(in: 0...100), category: "Tasks"),
                TrendData(date: date, value: Double.random(in: 0...50), category: "Notes"),
                TrendData(date: date, value: Double.random(in: 0...30), category: "Journal"),
                TrendData(date: date, value: Double.random(in: 1...5), category: "Mood")
            ]
        }.flatMap { $0 }
        
        // Generate sample habit streaks
        habitStreaks = [
            HabitStreak(
                habitName: "Daily Journaling",
                currentStreak: 12,
                longestStreak: 45,
                completionRate: 0.85,
                lastCompleted: Date(),
                color: .purple
            ),
            HabitStreak(
                habitName: "Task Completion",
                currentStreak: 5,
                longestStreak: 23,
                completionRate: 0.72,
                lastCompleted: Date(),
                color: .blue
            ),
            HabitStreak(
                habitName: "Mood Tracking",
                currentStreak: 8,
                longestStreak: 31,
                completionRate: 0.68,
                lastCompleted: Date(),
                color: .orange
            ),
            HabitStreak(
                habitName: "Note Taking",
                currentStreak: 3,
                longestStreak: 18,
                completionRate: 0.55,
                lastCompleted: calendar.date(byAdding: .day, value: -1, to: Date()),
                color: .green
            )
        ]
        
        // Generate sample weekly patterns
        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        weeklyPatterns = weekdays.enumerated().map { index, day in
            let value = Double.random(in: 20...100)
            let color: Color = index < 5 ? .blue : .green // Weekdays vs weekends
            return CategoryDataPoint(category: day, value: value, color: color)
        }
        
        // Generate sample correlations
        correlations = [
            (
                id: UUID(),
                title: "Journaling & Mood",
                description: "Strong positive correlation between journaling frequency and mood scores",
                strength: 0.78,
                type: "Positive"
            ),
            (
                id: UUID(),
                title: "Task Load & Stress",
                description: "Moderate negative correlation between high task volume and mood",
                strength: -0.65,
                type: "Negative"
            ),
            (
                id: UUID(),
                title: "Weekend Activity",
                description: "Weekend productivity shows correlation with weekday planning",
                strength: 0.52,
                type: "Positive"
            )
        ]
    }
}


// MARK: - Preview
struct TrendAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TrendAnalysisView()
        }
    }
}
