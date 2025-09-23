import SwiftUI

struct MoodView: View {
    // MARK: - Properties
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedTab: MoodTab = .quickLog
    @State private var showingMoodDetails: Bool = false
    
    enum MoodTab: String, CaseIterable {
        case quickLog = "Quick Log"
        case trends = "Trends"
        
        var icon: String {
            switch self {
            case .quickLog: return "plus.circle.fill"
            case .trends: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    // MARK: - Initialization
    init(dataManager: DataManager, encryptionService: EncryptionService) {
        // Initialize dataManager
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    // Quick Log Tab
                    quickLogTab
                        .tag(MoodTab.quickLog)
                    
                    // Trends Tab
                    trendsTab
                        .tag(MoodTab.trends)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Mood Tracking")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingMoodDetails = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingMoodDetails) {
                MoodQuickLogView(dataManager: dataManager)
            }
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(MoodTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Quick Log Tab
    private var quickLogTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Today's Mood Summary
                todayMoodSummary
                
                // Quick Log Interface
                quickLogInterface
                
                // Recent Entries
                recentEntriesSection
            }
            .padding()
        }
    }
    
    // MARK: - Trends Tab
    private var trendsTab: some View {
        MoodTrendsView(dataManager: dataManager)
    }
    
    // MARK: - Today's Mood Summary
    private var todayMoodSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Mood")
                .font(.headline)
                .fontWeight(.semibold)
            
            FrostedCard(style: .standard) {
                VStack(spacing: 16) {
                    if let todayMood = todayMoodEntry {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(todayMood.emoji ?? "😐")
                                        .font(.system(size: 40))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(Int(todayMood.moodLevel))/10")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        
                                        Text(moodDescription(for: Int(todayMood.moodLevel)))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if let notes = todayMood.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                if let date = todayMood.createdAt {
                                    Text(date, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button("Edit") {
                                    // TODO: Implement edit functionality
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "heart")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("No mood logged today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Log Your Mood") {
                                showingMoodDetails = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 20)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Quick Log Interface
    private var quickLogInterface: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Log")
                .font(.headline)
                .fontWeight(.semibold)
            
            FrostedCard(style: .standard) {
                VStack(spacing: 20) {
                    Text("How are you feeling right now?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Mood Buttons
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(1...10, id: \.self) { moodValue in
                            Button(action: {
                                logQuickMood(moodValue)
                            }) {
                                VStack(spacing: 4) {
                                    Text(moodEmoji(for: moodValue))
                                        .font(.title2)
                                    
                                    Text("\(moodValue)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Text("Tap any number to quickly log your mood")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Recent Entries Section
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Entries")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = .trends
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            FrostedCard(style: .standard) {
                VStack(spacing: 12) {
                    ForEach(recentMoodEntries.prefix(3), id: \.objectID) { entry in
                        MoodEntryRow(moodEntry: entry)
                        
                        if entry != recentMoodEntries.prefix(3).last {
                            Divider()
                        }
                    }
                    
                    if recentMoodEntries.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "heart")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Text("No mood entries yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Start tracking your mood to see entries here")
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
    private var todayMoodEntry: MoodEntry? {
        let calendar = Calendar.current
        let today = Date()
        
        return dataManager.getMoodEntries().first { entry in
            guard let date = entry.createdAt else { return false }
            return calendar.isDate(date, inSameDayAs: today)
        }
    }
    
    private var recentMoodEntries: [MoodEntry] {
        dataManager.getMoodEntries()
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
    
    private func moodDescription(for value: Int) -> String {
        switch value {
        case 1...2: return "Very Low"
        case 3...4: return "Low"
        case 5...6: return "Neutral"
        case 7...8: return "Good"
        case 9...10: return "Excellent"
        default: return "Neutral"
        }
    }
    
    private func logQuickMood(_ value: Int) {
        let emoji = moodEmoji(for: value)
        
        dataManager.createMoodEntry(
            moodLevel: Int16(value),
            emoji: emoji,
            notes: nil
        )
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Preview
struct MoodView_Previews: PreviewProvider {
    static var previews: some View {
        MoodView(
            dataManager: DataManager.shared,
            encryptionService: EncryptionService()
        )
    }
}

