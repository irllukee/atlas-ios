import SwiftUI
import CoreData

// MARK: - Mood Tracking View
struct MoodTrackingView: View {
    @ObservedObject var viewModel: JournalViewModel
    @State private var selectedMoodLevel = 5
    @State private var selectedScale = MoodScale.fivePoint
    @State private var moodNotes = ""
    @State private var customEmoji = ""
    @State private var showingMoodHistory = false
    @State private var moodEntries: [MoodEntry] = []
    @State private var selectedTimeframe = MoodTimeframe.week
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AtlasTheme.Spacing.lg) {
                    moodEntryCard
                    recentMoodHistorySection
                    moodHistorySection
                }
                .padding(AtlasTheme.Spacing.md)
            }
        }
        .sheet(isPresented: $showingMoodHistory) {
            MoodHistoryView(viewModel: viewModel)
        }
        .onAppear {
            selectedMoodLevel = selectedScale == .fivePoint ? 3 : 5
            loadMoodHistory()
        }
    }
    
    // MARK: - Computed Properties
    
    private var moodEntryCard: some View {
        FrostedCard(style: .floating) {
            VStack(spacing: AtlasTheme.Spacing.lg) {
                Text("How are you feeling?")
                    .font(AtlasTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                scaleSelection
                moodLevelSelector
                notesSection
                saveButton
            }
        }
    }
    
    private var scaleSelection: some View {
        Picker("Scale", selection: $selectedScale) {
            ForEach(MoodScale.allCases, id: \.self) { scale in
                Text(scale.rawValue.capitalized).tag(scale)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var moodLevelSelector: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            Text(selectedScale.emoji(for: selectedMoodLevel))
                .font(.system(size: 60))
                .scaleEffect(1.2)
                .animation(AtlasTheme.Animations.spring, value: selectedMoodLevel)
            
            Text(selectedScale.description(for: selectedMoodLevel))
                .font(AtlasTheme.Typography.headline)
                .foregroundColor(AtlasTheme.Colors.text)
            
            Slider(value: Binding(
                get: { Double(selectedMoodLevel) },
                set: { selectedMoodLevel = Int($0) }
            ), in: Double(selectedScale.range.lowerBound)...Double(selectedScale.range.upperBound), step: 1)
            .accentColor(AtlasTheme.Colors.accent)
            .sensoryFeedback(.selection, trigger: selectedMoodLevel)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            Text("Notes (Optional)")
                .font(AtlasTheme.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AtlasTheme.Colors.text)
            
            TextField("How are you feeling? What's on your mind?", text: $moodNotes, axis: .vertical)
                .font(AtlasTheme.Typography.body)
                .foregroundColor(AtlasTheme.Colors.text)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
    
    private var saveButton: some View {
        Button {
            AtlasTheme.Haptics.success()
            viewModel.logMood(
                level: selectedMoodLevel,
                scale: selectedScale,
                notes: moodNotes.isEmpty ? nil : moodNotes
            )
            
            // Reset form
            moodNotes = ""
            selectedMoodLevel = selectedScale == .fivePoint ? 3 : 5
        } label: {
            Text("Log Mood")
                .font(AtlasTheme.Typography.headline)
                .foregroundColor(AtlasTheme.Colors.textOnPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AtlasTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                        .fill(AtlasTheme.Colors.accent)
                )
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: selectedMoodLevel)
    }
    
    private var recentMoodHistorySection: some View {
        Group {
            if !viewModel.recentMoodEntries.isEmpty {
                FrostedCard(style: .standard) {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                        HStack {
                            Text("Recent Moods")
                                .font(AtlasTheme.Typography.headline)
                                .foregroundColor(AtlasTheme.Colors.text)
                            
                            Spacer()
                            
                            Button("View All") {
                                AtlasTheme.Haptics.light()
                                showingMoodHistory = true
                            }
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.accent)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AtlasTheme.Spacing.md) {
                                ForEach(viewModel.recentMoodEntries.prefix(5), id: \.id) { entry in
                                    RecentMoodCard(moodEntry: entry)
                                }
                            }
                            .padding(.horizontal, AtlasTheme.Spacing.xs)
                        }
                    }
                }
            }
        }
    }
    
    private var moodHistorySection: some View {
        Group {
            if !moodEntries.isEmpty {
                FrostedCard(style: .standard) {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                        HStack {
                            Text("Mood History")
                                .font(AtlasTheme.Typography.headline)
                                .foregroundColor(AtlasTheme.Colors.text)
                            
                            Spacer()
                            
                            Button("View All") {
                                AtlasTheme.Haptics.light()
                                showingMoodHistory = true
                            }
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.accent)
                        }
                        
                        LazyVStack(spacing: AtlasTheme.Spacing.md) {
                            ForEach(groupedMoodEntries.prefix(3), id: \.0) { date, entries in
                                MoodHistoryDaySection(date: date, entries: entries)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var groupedMoodEntries: [(Date, [MoodEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: moodEntries) { entry in
            calendar.startOfDay(for: entry.createdAt ?? Date())
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    // MARK: - Methods
    
    private func loadMoodHistory() {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let repository = DependencyContainer.shared.journalRepository
            moodEntries = try repository.fetchMoodEntries(dateRange: nil)
        } catch {
            print("Error loading mood history: \(error)")
        }
    }
}

// MARK: - Recent Mood Card
struct RecentMoodCard: View {
    let moodEntry: MoodEntry
    
    private var scale: MoodScale {
        MoodScale(rawValue: moodEntry.scale ?? "5-point") ?? .fivePoint
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(moodEntry.emoji ?? scale.emoji(for: Int(moodEntry.moodLevel)))
                .font(.title)
            
            Text(scale.description(for: Int(moodEntry.moodLevel)))
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if let notes = moodEntry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Text(moodEntry.createdAt?.formatted(date: .omitted, time: .shortened) ?? "Unknown")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 100)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Mood History View
struct MoodHistoryView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeframe = MoodTimeframe.month
    @State private var moodEntries: [MoodEntry] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading mood history...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if moodEntries.isEmpty {
                    EmptyStateView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "No mood data",
                        subtitle: "Start logging your moods to see your history here",
                        buttonTitle: "Log First Mood",
                        action: { dismiss() }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(groupedMoodEntries, id: \.0) { date, entries in
                                MoodHistoryDaySection(date: date, entries: entries)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mood History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadMoodHistory()
        }
    }
    
    private var groupedMoodEntries: [(Date, [MoodEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: moodEntries) { entry in
            calendar.startOfDay(for: entry.createdAt ?? Date())
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func loadMoodHistory() {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let repository = DependencyContainer.shared.journalRepository
            moodEntries = try repository.fetchMoodEntries(dateRange: nil)
        } catch {
            print("Error loading mood history: \(error)")
        }
    }
}

// MARK: - Mood History Day Section
struct MoodHistoryDaySection: View {
    let date: Date
    let entries: [MoodEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(date.formatted(date: .complete, time: .omitted))
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(entries, id: \.id) { entry in
                MoodHistoryEntryRow(entry: entry)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Mood History Entry Row
struct MoodHistoryEntryRow: View {
    let entry: MoodEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Text(entry.emoji ?? "😐")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Level \(entry.moodLevel)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(entry.createdAt?.formatted(date: .omitted, time: .shortened) ?? "Unknown")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}