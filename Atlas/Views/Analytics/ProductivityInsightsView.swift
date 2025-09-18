import SwiftUI
import Charts

/// Detailed productivity insights and recommendations
struct ProductivityInsightsView: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var selectedInsight: InsightType = .overview
    @State private var showingRecommendations = false
    
    enum InsightType: String, CaseIterable {
        case overview = "Overview"
        case patterns = "Patterns"
        case goals = "Goals"
        case recommendations = "Recommendations"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Insight type selector
                    insightTypeSelector
                    
                    // Content based on selected insight
                    Group {
                        switch selectedInsight {
                        case .overview:
                            overviewContent
                        case .patterns:
                            patternsContent
                        case .goals:
                            goalsContent
                        case .recommendations:
                            recommendationsContent
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color.green.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Productivity Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        analyticsService.refreshAnalytics()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    // MARK: - Insight Type Selector
    
    private var insightTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InsightType.allCases, id: \.self) { type in
                    InsightTypeButton(
                        type: type,
                        isSelected: selectedInsight == type,
                        action: { selectedInsight = type }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Overview Content
    
    private var overviewContent: some View {
        VStack(spacing: 24) {
            // Productivity score breakdown
            productivityScoreBreakdown
            
            // Key metrics
            keyMetricsGrid
            
            // Recent activity
            recentActivityCard
        }
    }
    
    private var productivityScoreBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Productivity Score Breakdown")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ScoreBreakdownRow(
                    title: "Notes Created",
                    score: min(Double(analyticsService.productivityMetrics.notesCreatedToday) * 10, 30),
                    maxScore: 30,
                    color: .blue
                )
                
                ScoreBreakdownRow(
                    title: "Tasks Completed",
                    score: min(Double(analyticsService.productivityMetrics.tasksCompletedToday) * 8, 40),
                    maxScore: 40,
                    color: .green
                )
                
                ScoreBreakdownRow(
                    title: "Journal Entries",
                    score: min(Double(analyticsService.productivityMetrics.journalEntriesToday) * 15, 15),
                    maxScore: 15,
                    color: .purple
                )
                
                ScoreBreakdownRow(
                    title: "Words Written",
                    score: min(Double(analyticsService.productivityMetrics.totalWordsWritten) * 0.1, 15),
                    maxScore: 15,
                    color: .orange
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
    
    private var keyMetricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Current Streak",
                value: "\(analyticsService.productivityMetrics.streakDays)",
                subtitle: "days",
                icon: "flame.fill",
                color: .orange
            )
            
            MetricCard(
                title: "Completion Rate",
                value: "\(Int(analyticsService.taskAnalytics.completionRate))",
                subtitle: "%",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            MetricCard(
                title: "Notes This Week",
                value: "\(analyticsService.noteStatistics.notesThisWeek)",
                subtitle: "notes",
                icon: "note.text",
                color: .blue
            )
            
            MetricCard(
                title: "Most Productive Day",
                value: analyticsService.noteStatistics.mostProductiveDay,
                subtitle: "of the week",
                icon: "calendar.badge.clock",
                color: .purple
            )
        }
    }
    
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ActivityRow(
                    title: "Notes Created Today",
                    value: "\(analyticsService.productivityMetrics.notesCreatedToday)",
                    icon: "note.text",
                    color: .blue
                )
                
                ActivityRow(
                    title: "Tasks Completed Today",
                    value: "\(analyticsService.productivityMetrics.tasksCompletedToday)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                ActivityRow(
                    title: "Journal Entries Today",
                    value: "\(analyticsService.productivityMetrics.journalEntriesToday)",
                    icon: "book",
                    color: .purple
                )
                
                ActivityRow(
                    title: "Total Words Written",
                    value: "\(analyticsService.productivityMetrics.totalWordsWritten)",
                    icon: "textformat.abc",
                    color: .orange
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
    
    // MARK: - Patterns Content
    
    private var patternsContent: some View {
        VStack(spacing: 24) {
            // Productivity patterns
            productivityPatternsCard
            
            // Time-based patterns
            timeBasedPatternsCard
            
            // Content patterns
            contentPatternsCard
        }
    }
    
    private var productivityPatternsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Productivity Patterns")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                PatternRow(
                    title: "Peak Productivity Day",
                    value: analyticsService.noteStatistics.mostProductiveDay,
                    description: "You create most notes on this day",
                    icon: "calendar.badge.clock",
                    color: .blue
                )
                
                PatternRow(
                    title: "Average Note Length",
                    value: "\(Int(analyticsService.noteStatistics.averageNoteLength)) characters",
                    description: "Your typical note size",
                    icon: "textformat.size",
                    color: .green
                )
                
                PatternRow(
                    title: "Content Richness",
                    value: "\(analyticsService.noteStatistics.notesWithImages + analyticsService.noteStatistics.notesWithTables) notes with media",
                    description: "Notes with images or tables",
                    icon: "photo.on.rectangle",
                    color: .purple
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
    
    private var timeBasedPatternsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time-Based Patterns")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                PatternRow(
                    title: "Weekly Activity",
                    value: "\(analyticsService.noteStatistics.notesThisWeek) notes this week",
                    description: "Consistent weekly output",
                    icon: "calendar",
                    color: .blue
                )
                
                PatternRow(
                    title: "Monthly Growth",
                    value: "\(analyticsService.noteStatistics.notesThisMonth) notes this month",
                    description: "Monthly productivity trend",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                PatternRow(
                    title: "Current Streak",
                    value: "\(analyticsService.productivityMetrics.streakDays) days",
                    description: "Days of consistent activity",
                    icon: "flame.fill",
                    color: .orange
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
    
    private var contentPatternsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Content Patterns")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                PatternRow(
                    title: "Visual Content",
                    value: "\(analyticsService.noteStatistics.notesWithImages) notes with images",
                    description: "Notes enhanced with visuals",
                    icon: "photo",
                    color: .blue
                )
                
                PatternRow(
                    title: "Structured Content",
                    value: "\(analyticsService.noteStatistics.notesWithTables) notes with tables",
                    description: "Notes with organized data",
                    icon: "tablecells",
                    color: .green
                )
                
                PatternRow(
                    title: "Task Management",
                    value: "\(analyticsService.taskAnalytics.completedTasks) tasks completed",
                    description: "Overall task completion",
                    icon: "checkmark.circle.fill",
                    color: .purple
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
    
    // MARK: - Goals Content
    
    private var goalsContent: some View {
        VStack(spacing: 24) {
            // Current goals
            currentGoalsCard
            
            // Goal progress
            goalProgressCard
            
            // Achievement highlights
            achievementHighlightsCard
        }
    }
    
    private var currentGoalsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Goals")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                GoalProgressRow(
                    title: "Daily Notes",
                    current: analyticsService.productivityMetrics.notesCreatedToday,
                    target: 3,
                    icon: "note.text",
                    color: .blue
                )
                
                GoalProgressRow(
                    title: "Daily Tasks",
                    current: analyticsService.productivityMetrics.tasksCompletedToday,
                    target: 5,
                    icon: "checkmark.circle",
                    color: .green
                )
                
                GoalProgressRow(
                    title: "Daily Journal",
                    current: analyticsService.productivityMetrics.journalEntriesToday,
                    target: 1,
                    icon: "book",
                    color: .purple
                )
                
                GoalProgressRow(
                    title: "Daily Words",
                    current: analyticsService.productivityMetrics.totalWordsWritten / 100,
                    target: 5,
                    icon: "textformat.abc",
                    color: .orange
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
    
    private var goalProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Progress")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ProgressRow(
                    title: "Weekly Notes Goal",
                    progress: Double(analyticsService.noteStatistics.notesThisWeek) / 21.0, // 3 per day
                    icon: "note.text",
                    color: .blue
                )
                
                ProgressRow(
                    title: "Task Completion Rate",
                    progress: analyticsService.taskAnalytics.completionRate / 100.0,
                    icon: "checkmark.circle",
                    color: .green
                )
                
                ProgressRow(
                    title: "Consistency Streak",
                    progress: min(Double(analyticsService.productivityMetrics.streakDays) / 30.0, 1.0),
                    icon: "flame.fill",
                    color: .orange
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
    
    private var achievementHighlightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievement Highlights")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                AchievementRow(
                    title: "Total Notes Created",
                    value: "\(analyticsService.noteStatistics.totalNotes)",
                    description: "All-time note count",
                    icon: "note.text",
                    color: .blue
                )
                
                AchievementRow(
                    title: "Tasks Completed",
                    value: "\(analyticsService.taskAnalytics.completedTasks)",
                    description: "Total completed tasks",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                AchievementRow(
                    title: "Words Written",
                    value: "\(analyticsService.productivityMetrics.totalWordsWritten)",
                    description: "Total words across all notes",
                    icon: "textformat.abc",
                    color: .orange
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
    
    // MARK: - Recommendations Content
    
    private var recommendationsContent: some View {
        VStack(spacing: 24) {
            // Personalized recommendations
            personalizedRecommendationsCard
            
            // Improvement suggestions
            improvementSuggestionsCard
            
            // Best practices
            bestPracticesCard
        }
    }
    
    private var personalizedRecommendationsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personalized Recommendations")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                RecommendationRow(
                    title: "Boost Your Streak",
                    description: "You're on a \(analyticsService.productivityMetrics.streakDays)-day streak! Keep it up by creating at least one note daily.",
                    icon: "flame.fill",
                    color: .orange
                )
                
                RecommendationRow(
                    title: "Increase Task Completion",
                    description: "Your completion rate is \(Int(analyticsService.taskAnalytics.completionRate))%. Try breaking large tasks into smaller ones.",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                RecommendationRow(
                    title: "Enhance Content",
                    description: "Add more images and tables to your notes. Only \(analyticsService.noteStatistics.notesWithImages + analyticsService.noteStatistics.notesWithTables) notes have media.",
                    icon: "photo.on.rectangle",
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
    
    private var improvementSuggestionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Improvement Suggestions")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                SuggestionRow(
                    title: "Set Daily Goals",
                    description: "Aim for 3 notes, 5 tasks, and 1 journal entry per day for optimal productivity.",
                    icon: "target",
                    color: .blue
                )
                
                SuggestionRow(
                    title: "Use Templates",
                    description: "Create note templates for common content types to speed up your workflow.",
                    icon: "doc.text",
                    color: .green
                )
                
                SuggestionRow(
                    title: "Review Regularly",
                    description: "Set aside time weekly to review and organize your notes and tasks.",
                    icon: "calendar.badge.clock",
                    color: .purple
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
    
    private var bestPracticesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Best Practices")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                PracticeRow(
                    title: "Consistent Naming",
                    description: "Use clear, descriptive titles for your notes to make them easier to find.",
                    icon: "textformat.abc",
                    color: .blue
                )
                
                PracticeRow(
                    title: "Regular Backups",
                    description: "Your data is automatically saved, but consider exporting important notes periodically.",
                    icon: "icloud.and.arrow.up",
                    color: .green
                )
                
                PracticeRow(
                    title: "Tag Organization",
                    description: "Use tags and folders to organize your notes for better productivity.",
                    icon: "tag",
                    color: .purple
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

struct InsightTypeButton: View {
    let type: ProductivityInsightsView.InsightType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? .blue : Color.clear)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                )
        }
    }
}

struct ScoreBreakdownRow: View {
    let title: String
    let score: Double
    let maxScore: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(score))/\(Int(maxScore))")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: score, total: maxScore)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct ActivityRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct PatternRow: View {
    let title: String
    let value: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct GoalProgressRow: View {
    let title: String
    let current: Int
    let target: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(current)/\(target)")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(current), total: Double(target))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(.vertical, 4)
    }
}

struct ProgressRow: View {
    let title: String
    let progress: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(.vertical, 4)
    }
}

struct AchievementRow: View {
    let title: String
    let value: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct RecommendationRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct SuggestionRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PracticeRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProductivityInsightsView()
}
