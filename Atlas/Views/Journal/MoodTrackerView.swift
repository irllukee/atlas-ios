import SwiftUI

struct MoodTrackerView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMood: MoodLevel = .neutral
    @State private var customEmoji: String = ""
    @State private var notes: String = ""
    @State private var showingCustomEmoji: Bool = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("How are you feeling?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Track your mood to understand patterns")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Mood Selection
                VStack(spacing: 16) {
                    Text("Select your mood:")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(MoodLevel.allCases) { mood in
                            MoodButton(
                                mood: mood,
                                isSelected: selectedMood == mood,
                                action: { selectedMood = mood }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Custom Emoji
                VStack(spacing: 12) {
                    Toggle("Use custom emoji", isOn: $showingCustomEmoji)
                        .padding(.horizontal)
                    
                    if showingCustomEmoji {
                        TextField("Enter emoji", text: $customEmoji)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (optional)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Mood Trend (if available)
                if !viewModel.moodEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Mood Trend")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        MoodTrendChart(moodTrend: viewModel.getMoodTrend(days: 7))
                            .frame(height: 60)
                            .padding(.horizontal)
                    }
                }
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle("Mood Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMood()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
    
    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                ProgressView()
            }
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    private func saveMood() {
        let emoji = showingCustomEmoji && !customEmoji.isEmpty ? customEmoji : selectedMood.emoji
        
        viewModel.createMoodEntry(
            rating: selectedMood,
            emoji: emoji,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

// MARK: - Mood Button
struct MoodButton: View {
    let mood: MoodLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: 40))
                
                Text(mood.description)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mood Trend Chart
struct MoodTrendChart: View {
    let moodTrend: [MoodLevel?]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(moodTrend.indices, id: \.self) { index in
                VStack(spacing: 2) {
                    if let mood = moodTrend[index] {
                        Text(mood.emoji)
                            .font(.caption)
                        
                        Rectangle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 20, height: CGFloat(mood.rawValue) * 8)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 20, height: 8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
struct MoodTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        let viewModel = JournalViewModel(dataManager: dataManager, encryptionService: encryptionService)
        
        MoodTrackerView(viewModel: viewModel)
    }
}
