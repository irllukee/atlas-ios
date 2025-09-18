import SwiftUI
import Charts

// MARK: - Widget Types
enum WidgetType: String, CaseIterable, Identifiable, Codable {
    case taskCompletion = "Task Completion"
    case moodTrend = "Mood Trend"
    case productivityScore = "Productivity Score"
    case habitStreak = "Habit Streak"
    case weeklyOverview = "Weekly Overview"
    case goalProgress = "Goal Progress"
    case timeDistribution = "Time Distribution"
    case insights = "Insights"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .taskCompletion: return "checkmark.circle.fill"
        case .moodTrend: return "face.smiling.fill"
        case .productivityScore: return "chart.line.uptrend.xyaxis"
        case .habitStreak: return "flame.fill"
        case .weeklyOverview: return "calendar"
        case .goalProgress: return "target"
        case .timeDistribution: return "clock.fill"
        case .insights: return "lightbulb.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .taskCompletion: return .blue
        case .moodTrend: return .orange
        case .productivityScore: return .green
        case .habitStreak: return .red
        case .weeklyOverview: return .purple
        case .goalProgress: return .cyan
        case .timeDistribution: return .indigo
        case .insights: return .yellow
        }
    }
}

// MARK: - Widget Configuration
struct WidgetConfiguration: Identifiable, Codable {
    let id: UUID
    var type: WidgetType
    var isEnabled: Bool
    var position: Int
    var size: WidgetSize
    var customSettings: [String: String]
    
    init(type: WidgetType, isEnabled: Bool = true, position: Int = 0, size: WidgetSize = .medium, customSettings: [String: String] = [:]) {
        self.id = UUID()
        self.type = type
        self.isEnabled = isEnabled
        self.position = position
        self.size = size
        self.customSettings = customSettings
    }
    
    enum WidgetSize: String, CaseIterable, Codable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        
        var dimensions: (width: Int, height: Int) {
            switch self {
            case .small: return (1, 1)
            case .medium: return (2, 1)
            case .large: return (2, 2)
            }
        }
    }
}

// MARK: - Dashboard Widgets View
struct DashboardWidgetsView: View {
    @StateObject private var viewModel = DashboardWidgetsViewModel()
    @State private var isEditing = false
    @State private var showingWidgetSettings = false
    @State private var selectedWidget: WidgetConfiguration?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.enabledWidgets) { widget in
                        WidgetView(
                            configuration: widget,
                            isEditing: isEditing,
                            onTap: {
                                if isEditing {
                                    selectedWidget = widget
                                    showingWidgetSettings = true
                                }
                            },
                            onDelete: {
                                viewModel.removeWidget(widget)
                            }
                        )
                    }
                    
                    if isEditing {
                        AddWidgetButton {
                            viewModel.showAddWidgetSheet = true
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard Widgets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddWidgetSheet) {
                AddWidgetSheet { widgetType in
                    viewModel.addWidget(type: widgetType)
                }
            }
            .sheet(isPresented: $showingWidgetSettings) {
                if let widget = selectedWidget {
                    WidgetSettingsSheet(
                        configuration: widget,
                        onSave: { updatedWidget in
                            viewModel.updateWidget(updatedWidget)
                            showingWidgetSettings = false
                        },
                        onCancel: {
                            showingWidgetSettings = false
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Widget View
struct WidgetView: View {
    let configuration: WidgetConfiguration
    let isEditing: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Group {
            switch configuration.type {
            case .taskCompletion:
                TaskCompletionWidget(configuration: configuration)
            case .moodTrend:
                MoodTrendWidget(configuration: configuration)
            case .productivityScore:
                ProductivityScoreWidget(configuration: configuration)
            case .habitStreak:
                HabitStreakWidget(configuration: configuration)
            case .weeklyOverview:
                WeeklyOverviewWidget(configuration: configuration)
            case .goalProgress:
                GoalProgressWidget(configuration: configuration)
            case .timeDistribution:
                TimeDistributionWidget(configuration: configuration)
            case .insights:
                InsightsWidget(configuration: configuration)
            }
        }
        .frame(height: widgetHeight)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            Group {
                if isEditing {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white, in: Circle())
                            }
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private var widgetHeight: CGFloat {
        switch configuration.size {
        case .small: return 120
        case .medium: return 120
        case .large: return 240
        }
    }
}

// MARK: - Task Completion Widget
struct TaskCompletionWidget: View {
    let configuration: WidgetConfiguration
    @State private var completionRate: Double = 0.75
    @State private var tasksCompleted: Int = 15
    @State private var totalTasks: Int = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: configuration.type.icon)
                    .foregroundColor(configuration.type.color)
                    .font(.title2)
                
                Text(configuration.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if configuration.size == .large {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(tasksCompleted)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("of \(totalTasks) tasks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(Int(completionRate * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(configuration.type.color)
                            
                            Text("Completion Rate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ProgressView(value: completionRate)
                        .progressViewStyle(LinearProgressViewStyle(tint: configuration.type.color))
                        .scaleEffect(y: 2)
                }
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(Int(completionRate * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(configuration.type.color)
                        
                        Text("\(tasksCompleted)/\(totalTasks) tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    CircularProgressView(
                        progress: completionRate,
                        color: configuration.type.color,
                        lineWidth: 6
                    )
                    .frame(width: 50, height: 50)
                }
            }
        }
        .padding()
    }
}

// MARK: - Mood Trend Widget
struct MoodTrendWidget: View {
    let configuration: WidgetConfiguration
    @State private var currentMood: Double = 4.2
    @State private var moodChange: Double = 0.3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: configuration.type.icon)
                    .foregroundColor(configuration.type.color)
                    .font(.title2)
                
                Text(configuration.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if configuration.size == .large {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(currentMood, specifier: "%.1f")")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Current Mood")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        TrendIndicator(value: moodChange, isPositive: moodChange > 0)
                    }
                    
                    // Mini mood chart
                    MiniMoodChart()
                        .frame(height: 60)
                }
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(currentMood, specifier: "%.1f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        TrendIndicator(value: moodChange, isPositive: moodChange > 0)
                    }
                    
                    Spacer()
                    
                    Image(systemName: moodChange > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.title2)
                        .foregroundColor(moodChange > 0 ? .green : .red)
                }
            }
        }
        .padding()
    }
}

// MARK: - Productivity Score Widget
struct ProductivityScoreWidget: View {
    let configuration: WidgetConfiguration
    @State private var productivityScore: Double = 85.0
    @State private var previousScore: Double = 78.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: configuration.type.icon)
                    .foregroundColor(configuration.type.color)
                    .font(.title2)
                
                Text(configuration.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(productivityScore))")
                        .font(configuration.size == .large ? .largeTitle : .title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("out of 100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: productivityScore / 100,
                    color: configuration.type.color,
                    lineWidth: 8
                )
                .frame(width: configuration.size == .large ? 80 : 50, height: configuration.size == .large ? 80 : 50)
            }
        }
        .padding()
    }
}

// MARK: - Habit Streak Widget
struct HabitStreakWidget: View {
    let configuration: WidgetConfiguration
    @State private var currentStreak: Int = 12
    @State private var habitName: String = "Journaling"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: configuration.type.icon)
                    .foregroundColor(configuration.type.color)
                    .font(.title2)
                
                Text(configuration.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(currentStreak)")
                        .font(configuration.size == .large ? .largeTitle : .title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if configuration.size == .large {
                    VStack(alignment: .trailing) {
                        Text(habitName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Keep it up!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Weekly Overview Widget
struct WeeklyOverviewWidget: View {
    let configuration: WidgetConfiguration
    @State private var weeklyData: [CategoryDataPoint] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: configuration.type.icon)
                    .foregroundColor(configuration.type.color)
                    .font(.title2)
                
                Text(configuration.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if configuration.size == .large && !weeklyData.isEmpty {
                Chart(weeklyData) { dataPoint in
                    BarMark(
                        x: .value("Day", dataPoint.category),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(dataPoint.color)
                    .cornerRadius(4)
                }
                .frame(height: 120)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack {
                    ForEach(weeklyData.prefix(7), id: \.id) { dataPoint in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(dataPoint.color)
                                .frame(width: 8, height: CGFloat(dataPoint.value))
                            
                            Text(dataPoint.category)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .onAppear {
            generateWeeklyData()
        }
    }
    
    private func generateWeeklyData() {
        let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
        weeklyData = weekdays.enumerated().map { index, day in
            let value = Double.random(in: 20...100)
            let color: Color = index < 5 ? .blue : .green
            return CategoryDataPoint(category: day, value: value, color: color)
        }
    }
}

// MARK: - Goal Progress Widget
struct GoalProgressWidget: View {
    let configuration: WidgetConfiguration
    @State private var goalProgress: Double = 0.65
    @State private var goalName: String = "Complete 50 Tasks"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: configuration.type.icon)
                    .foregroundColor(configuration.type.color)
                    .font(.title2)
                
                Text(configuration.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(goalName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                ProgressView(value: goalProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: configuration.type.color))
                    .scaleEffect(y: 2)
                
                Text("\(Int(goalProgress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Time Distribution Widget
struct TimeDistributionWidget: View {
    let configuration: WidgetConfiguration
    @State private var timeData: [CategoryDataPoint] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: configuration.type.icon)
                    .foregroundColor(configuration.type.color)
                    .font(.title2)
                
                Text(configuration.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if configuration.size == .large && !timeData.isEmpty {
                Chart(timeData) { dataPoint in
                    SectorMark(
                        angle: .value("Time", dataPoint.value),
                        innerRadius: .ratio(0.4),
                        angularInset: 2
                    )
                    .foregroundStyle(dataPoint.color)
                }
                .frame(height: 120)
            } else {
                HStack {
                    ForEach(timeData.prefix(4), id: \.id) { dataPoint in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(dataPoint.color)
                                .frame(width: 12, height: 12)
                            
                            Text(dataPoint.category)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .onAppear {
            generateTimeData()
        }
    }
    
    private func generateTimeData() {
        timeData = [
            CategoryDataPoint(category: "Tasks", value: 40, color: .blue),
            CategoryDataPoint(category: "Notes", value: 25, color: .green),
            CategoryDataPoint(category: "Journal", value: 20, color: .purple),
            CategoryDataPoint(category: "Other", value: 15, color: .orange)
        ]
    }
}

// MARK: - Insights Widget
struct InsightsWidget: View {
    let configuration: WidgetConfiguration
    @State private var insights: [String] = [
        "Your productivity peaks on Tuesdays",
        "Journaling correlates with better mood",
        "Complete tasks in the morning for best results"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: configuration.type.icon)
                    .foregroundColor(configuration.type.color)
                    .font(.title2)
                
                Text(configuration.type.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(insights.prefix(configuration.size == .large ? 3 : 2), id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(configuration.type.color)
                            .frame(width: 12)
                        
                        Text(insight)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Supporting Views
struct AddWidgetButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                
                Text("Add Widget")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(.secondary.opacity(0.5))
            )
        }
        .frame(height: 120)
    }
}

struct AddWidgetSheet: View {
    let onAdd: (WidgetType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(WidgetType.allCases) { widgetType in
                    Button(action: {
                        onAdd(widgetType)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: widgetType.icon)
                                .foregroundColor(widgetType.color)
                                .frame(width: 24)
                            
                            Text(widgetType.rawValue)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Add Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WidgetSettingsSheet: View {
    let configuration: WidgetConfiguration
    let onSave: (WidgetConfiguration) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEnabled: Bool
    @State private var size: WidgetConfiguration.WidgetSize
    
    init(configuration: WidgetConfiguration, onSave: @escaping (WidgetConfiguration) -> Void, onCancel: @escaping () -> Void) {
        self.configuration = configuration
        self.onSave = onSave
        self.onCancel = onCancel
        self._isEnabled = State(initialValue: configuration.isEnabled)
        self._size = State(initialValue: configuration.size)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Widget Settings") {
                    Toggle("Enabled", isOn: $isEnabled)
                    
                    Picker("Size", selection: $size) {
                        ForEach(WidgetConfiguration.WidgetSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                }
            }
            .navigationTitle("Widget Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedConfig = configuration
                        updatedConfig.isEnabled = isEnabled
                        updatedConfig.size = size
                        onSave(updatedConfig)
                    }
                }
            }
        }
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
        }
    }
}

// MARK: - Mini Mood Chart
struct MiniMoodChart: View {
    @State private var moodData: [ChartDataPoint] = []
    
    var body: some View {
        Chart(moodData) { dataPoint in
            LineMark(
                x: .value("Day", dataPoint.date),
                y: .value("Mood", dataPoint.value)
            )
            .foregroundStyle(.orange)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .onAppear {
            generateMoodData()
        }
    }
    
    private func generateMoodData() {
        let calendar = Calendar.current
        moodData = (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { return nil }
            return ChartDataPoint(date: date, value: Double.random(in: 1...5))
        }.reversed()
    }
}

// MARK: - Dashboard Widgets ViewModel
@MainActor
class DashboardWidgetsViewModel: ObservableObject {
    @Published var widgets: [WidgetConfiguration] = []
    @Published var showAddWidgetSheet = false
    
    var enabledWidgets: [WidgetConfiguration] {
        widgets.filter { $0.isEnabled }.sorted { $0.position < $1.position }
    }
    
    init() {
        loadDefaultWidgets()
    }
    
    func addWidget(type: WidgetType) {
        let newWidget = WidgetConfiguration(
            type: type,
            isEnabled: true,
            position: widgets.count,
            size: .medium,
            customSettings: [:]
        )
        widgets.append(newWidget)
        saveWidgets()
    }
    
    func removeWidget(_ widget: WidgetConfiguration) {
        widgets.removeAll { $0.id == widget.id }
        saveWidgets()
    }
    
    func updateWidget(_ widget: WidgetConfiguration) {
        if let index = widgets.firstIndex(where: { $0.id == widget.id }) {
            widgets[index] = widget
            saveWidgets()
        }
    }
    
    private func loadDefaultWidgets() {
        // Load default widget configuration
        widgets = [
            WidgetConfiguration(type: .taskCompletion, isEnabled: true, position: 0, size: .medium, customSettings: [:]),
            WidgetConfiguration(type: .moodTrend, isEnabled: true, position: 1, size: .medium, customSettings: [:]),
            WidgetConfiguration(type: .productivityScore, isEnabled: true, position: 2, size: .small, customSettings: [:]),
            WidgetConfiguration(type: .habitStreak, isEnabled: true, position: 3, size: .small, customSettings: [:]),
            WidgetConfiguration(type: .weeklyOverview, isEnabled: true, position: 4, size: .large, customSettings: [:]),
            WidgetConfiguration(type: .insights, isEnabled: true, position: 5, size: .medium, customSettings: [:])
        ]
    }
    
    private func saveWidgets() {
        // Save widget configuration to UserDefaults or Core Data
        // Implementation would depend on persistence requirements
    }
}

// MARK: - Preview
struct DashboardWidgetsView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardWidgetsView()
    }
}
