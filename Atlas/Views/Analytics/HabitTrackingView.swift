import SwiftUI
import Charts

/// Dedicated habit tracking view with detailed analytics
struct HabitTrackingView: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var selectedHabit: AnalyticsService.HabitData.HabitType = .notesCreated
    @State private var showingGoalEditor = false
    @State private var customGoals: [AnalyticsService.HabitData.HabitType: Double] = [
        .notesCreated: 3.0,
        .tasksCompleted: 5.0,
        .journalEntries: 1.0,
        .wordsWritten: 500.0,
        .moodLogged: 1.0
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Habit selector
                    habitSelector
                    
                    // Current streak and progress
                    streakProgressCard
                    
                    // Weekly chart
                    weeklyChart
                    
                    // Monthly overview
                    monthlyOverview
                    
                    // Goal settings
                    goalSettingsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Habit Tracking")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingGoalEditor.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingGoalEditor) {
                GoalEditorView(customGoals: $customGoals)
            }
        }
    }
    
    // MARK: - Habit Selector
    
    private var habitSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Habit")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AnalyticsService.HabitData.HabitType.allCases, id: \.self) { habit in
                        HabitButton(
                            habit: habit,
                            isSelected: selectedHabit == habit,
                            action: { selectedHabit = habit }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Streak Progress Card
    
    private var streakProgressCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedHabit.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Current Progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Day Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's Progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(todayProgress))/\(Int(currentGoal))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                ProgressView(value: todayProgress, total: currentGoal)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            // Weekly summary
            HStack(spacing: 20) {
                WeeklyStat(
                    title: "This Week",
                    value: "\(weeklyTotal)",
                    color: .blue
                )
                
                WeeklyStat(
                    title: "Goal Met",
                    value: "\(goalMetDays)/7",
                    color: .green
                )
                
                WeeklyStat(
                    title: "Best Day",
                    value: "\(bestDayValue)",
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
    
    // MARK: - Weekly Chart
    
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("7-Day Trend")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(weeklyHabitData) { habit in
                        BarMark(
                            x: .value("Day", habit.date, unit: .day),
                            y: .value("Count", habit.value)
                        )
                        .foregroundStyle(
                            habit.value >= currentGoal ? .green : .blue
                        )
                        .cornerRadius(4)
                    }
                    
                    // Goal line
                    RuleMark(y: .value("Goal", currentGoal))
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
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
    
    // MARK: - Monthly Overview
    
    private var monthlyOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Overview")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(monthlyHabitData) { habit in
                    MonthlyDayView(
                        date: habit.date,
                        value: habit.value,
                        goal: currentGoal,
                        isToday: Calendar.current.isDateInToday(habit.date)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Goal Settings Card
    
    private var goalSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(AnalyticsService.HabitData.HabitType.allCases, id: \.self) { habit in
                    GoalSettingRow(
                        habit: habit,
                        goal: customGoals[habit] ?? 1.0,
                        onGoalChanged: { newGoal in
                            customGoals[habit] = newGoal
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Computed Properties
    
    private var currentGoal: Double {
        customGoals[selectedHabit] ?? 1.0
    }
    
    private var todayProgress: Double {
        let today = Calendar.current.startOfDay(for: Date())
        let todayHabit = analyticsService.habitData.first { habit in
            habit.habitType == selectedHabit && Calendar.current.isDate(habit.date, inSameDayAs: today)
        }
        return todayHabit?.value ?? 0
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        while true {
            let dayHabit = analyticsService.habitData.first { habit in
                habit.habitType == selectedHabit && calendar.isDate(habit.date, inSameDayAs: currentDate)
            }
            
            if let habit = dayHabit, habit.value >= currentGoal {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var weeklyHabitData: [AnalyticsService.HabitData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var weeklyData: [AnalyticsService.HabitData] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dayHabit = analyticsService.habitData.first { habit in
                    habit.habitType == selectedHabit && calendar.isDate(habit.date, inSameDayAs: date)
                }
                weeklyData.append(dayHabit ?? AnalyticsService.HabitData(
                    date: date,
                    habitType: selectedHabit,
                    value: 0,
                    goal: currentGoal
                ))
            }
        }
        
        return weeklyData.reversed()
    }
    
    private var monthlyHabitData: [AnalyticsService.HabitData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let monthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
        var monthlyData: [AnalyticsService.HabitData] = []
        
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: i, to: monthStart) {
                let dayHabit = analyticsService.habitData.first { habit in
                    habit.habitType == selectedHabit && calendar.isDate(habit.date, inSameDayAs: date)
                }
                monthlyData.append(dayHabit ?? AnalyticsService.HabitData(
                    date: date,
                    habitType: selectedHabit,
                    value: 0,
                    goal: currentGoal
                ))
            }
        }
        
        return monthlyData
    }
    
    private var weeklyTotal: Int {
        weeklyHabitData.reduce(0) { $0 + Int($1.value) }
    }
    
    private var goalMetDays: Int {
        weeklyHabitData.filter { $0.value >= currentGoal }.count
    }
    
    private var bestDayValue: Int {
        Int(weeklyHabitData.map { $0.value }.max() ?? 0)
    }
}

// MARK: - Supporting Views

struct HabitButton: View {
    let habit: AnalyticsService.HabitData.HabitType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(habit.rawValue)
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

struct WeeklyStat: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MonthlyDayView: View {
    let date: Date
    let value: Double
    let goal: Double
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .white : .primary)
            
            Circle()
                .fill(dayColor)
                .frame(width: 8, height: 8)
        }
        .frame(width: 32, height: 32)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? .blue : .clear)
        )
    }
    
    private var dayColor: Color {
        if value >= goal {
            return .green
        } else if value > 0 {
            return .orange
        } else {
            return .gray.opacity(0.3)
        }
    }
}

struct GoalSettingRow: View {
    let habit: AnalyticsService.HabitData.HabitType
    let goal: Double
    let onGoalChanged: (Double) -> Void
    
    var body: some View {
        HStack {
            Text(habit.rawValue)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    if goal > 1 {
                        onGoalChanged(goal - 1)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
                .disabled(goal <= 1)
                
                Text("\(Int(goal))")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(minWidth: 30)
                
                Button {
                    onGoalChanged(goal + 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct GoalEditorView: View {
    @Binding var customGoals: [AnalyticsService.HabitData.HabitType: Double]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(AnalyticsService.HabitData.HabitType.allCases, id: \.self) { habit in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(habit.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Slider(
                                value: Binding(
                                    get: { customGoals[habit] ?? 1.0 },
                                    set: { customGoals[habit] = $0 }
                                ),
                                in: 1...20,
                                step: 1
                            )
                            
                            Text("\(Int(customGoals[habit] ?? 1.0))")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Goals")
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

#Preview {
    HabitTrackingView()
}
