import SwiftUI
import Charts

struct MoodTrendsView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: JournalViewModel
    @State private var selectedTimeframe: Timeframe = .week
    @State private var showingMoodDetails: Bool = false
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Timeframe Selector
                    timeframeSelector
                    
                    // Mood Chart
                    moodChartSection
                    
                    // Statistics
                    statisticsSection
                    
                    // Recent Mood Entries
                    recentMoodEntriesSection
                }
                .padding()
            }
            .navigationTitle("Mood Trends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Log Mood") {
                        showingMoodDetails = true
                    }
                }
            }
            .sheet(isPresented: $showingMoodDetails) {
                MoodQuickLogView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Your Mood Journey")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Track patterns and understand your emotional well-being")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Timeframe Selector
    private var timeframeSelector: some View {
        HStack(spacing: 12) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Button(action: {
                    selectedTimeframe = timeframe
                }) {
                    Text(timeframe.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTimeframe == timeframe ? Color.blue : Color(.systemGray6))
                        )
                }
            }
        }
    }
    
    // MARK: - Mood Chart Section
    private var moodChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Trend")
                .font(.headline)
                .fontWeight(.semibold)
            
            FrostedCard(style: .standard) {
                VStack(spacing: 16) {
                    // Chart
                    if #available(iOS 16.0, *) {
                        Chart(moodData, id: \.date) { dataPoint in
                            LineMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Mood", dataPoint.moodValue)
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
                            PointMark(
                                x: .value("Date", dataPoint.date),
                                y: .value("Mood", dataPoint.moodValue)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(50)
                        }
                        .frame(height: 200)
                        .chartYScale(domain: 1...10)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: max(1, selectedTimeframe.days / 7))) { value in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let moodValue = value.as(Double.self) {
                                        Text(moodEmoji(for: Int(moodValue)))
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    } else {
                        // Fallback for iOS 15
                        MoodTrendChart(moodTrend: viewModel.getMoodTrend(days: selectedTimeframe.days))
                            .frame(height: 200)
                    }
                    
                    // Chart Legend
                    HStack {
                        Text("Average: \(String(format: "%.1f", averageMood))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(moodData.count) entries")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Average Mood",
                    value: String(format: "%.1f", averageMood),
                    subtitle: "Last \(selectedTimeframe.days) days",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                StatCard(
                    title: "Best Day",
                    value: String(format: "%.1f", bestMood),
                    subtitle: bestMoodDate,
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "Consistency",
                    value: String(format: "%.0f%%", consistencyScore),
                    subtitle: "Mood stability",
                    icon: "waveform.path.ecg",
                    color: .green
                )
                
                StatCard(
                    title: "Total Entries",
                    value: "\(moodData.count)",
                    subtitle: "Logged moods",
                    icon: "heart.fill",
                    color: .red
                )
            }
        }
    }
    
    // MARK: - Recent Mood Entries Section
    private var recentMoodEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Entries")
                .font(.headline)
                .fontWeight(.semibold)
            
            FrostedCard(style: .standard) {
                VStack(spacing: 12) {
                    ForEach(recentMoodEntries.prefix(5), id: \.objectID) { entry in
                        MoodEntryRow(moodEntry: entry)
                    }
                    
                    if recentMoodEntries.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "heart")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Text("No mood entries yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Start tracking your mood to see trends here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Computed Properties
    private var moodData: [MoodDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeframe.days, to: endDate) ?? endDate
        
        return viewModel.moodEntries
            .filter { entry in
                guard let date = entry.createdAt else { return false }
                return date >= startDate && date <= endDate
            }
            .sorted { ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast) }
            .map { entry in
                MoodDataPoint(
                    date: entry.createdAt ?? Date(),
                    moodValue: Double(entry.rating),
                    emoji: entry.emoji ?? "😐"
                )
            }
    }
    
    private var averageMood: Double {
        guard !moodData.isEmpty else { return 0 }
        return moodData.map(\.moodValue).reduce(0, +) / Double(moodData.count)
    }
    
    private var bestMood: Double {
        moodData.map(\.moodValue).max() ?? 0
    }
    
    private var bestMoodDate: String {
        guard let bestEntry = moodData.max(by: { $0.moodValue < $1.moodValue }) else {
            return "N/A"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: bestEntry.date)
    }
    
    private var consistencyScore: Double {
        guard moodData.count > 1 else { return 100 }
        
        let values = moodData.map(\.moodValue)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // Convert to percentage (lower deviation = higher consistency)
        return max(0, 100 - (standardDeviation * 10))
    }
    
    private var recentMoodEntries: [MoodEntry] {
        viewModel.moodEntries
            .sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
    }
    
    // MARK: - Helper Methods
    private func moodEmoji(for value: Int) -> String {
        switch value {
        case 1...2: return "😢"
        case 3...4: return "😔"
        case 5...6: return "😐"
        case 7...8: return "😊"
        case 9...10: return "😄"
        default: return "😐"
        }
    }
}

// MARK: - Supporting Types
struct MoodDataPoint {
    let date: Date
    let moodValue: Double
    let emoji: String
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        FrostedCard(style: .compact) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
        }
    }
}

struct MoodEntryRow: View {
    let moodEntry: MoodEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Text(moodEntry.emoji ?? "😐")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mood: \(Int(moodEntry.rating))/10")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let notes = moodEntry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if let date = moodEntry.createdAt {
                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct MoodTrendsView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        let viewModel = JournalViewModel(dataManager: dataManager, encryptionService: encryptionService)
        
        MoodTrendsView(viewModel: viewModel)
    }
}

