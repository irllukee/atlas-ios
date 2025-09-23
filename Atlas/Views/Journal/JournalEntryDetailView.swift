import SwiftUI
import CoreData

// MARK: - Journal Entry Detail View
struct JournalEntryDetailView: View {
    let entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    
    private var entryType: JournalEntryType {
        JournalEntryType(rawValue: entry.type ?? "daily") ?? .daily
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 12) {
                                Text(entryType.emoji)
                                    .font(.largeTitle)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    if let title = entry.title, !title.isEmpty {
                                        Text(title)
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text(entryType.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Metadata
                        HStack {
                            Label((entry.createdAt ?? Date()).formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                            
                            if entry.wordCount > 0 {
                                Label("\(entry.wordCount) words", systemImage: "doc.text")
                            }
                            
                            if entry.readingTime > 0 {
                                Label("\(entry.readingTime) min", systemImage: "clock")
                            }
                            
                            if entry.isEncrypted {
                                Label("Encrypted", systemImage: "lock.fill")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Content
                    Text(entry.isEncrypted ? "🔒 This entry is encrypted" : (entry.content ?? ""))
                        .font(.body)
                        .lineSpacing(4)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditJournalEntryView(entry: entry, viewModel: viewModel)
        }
    }
}

// MARK: - Edit Journal Entry View
struct EditJournalEntryView: View {
    let entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var content: String
    @State private var hasChanges = false
    
    // Mood tracking
    @State private var selectedMoodLevel = 5
    @State private var selectedMoodScale = MoodScale.fivePoint
    @State private var includeMood = false
    
    init(entry: JournalEntry, viewModel: JournalViewModel) {
        self.entry = entry
        self.viewModel = viewModel
        self._title = State(initialValue: entry.title ?? "")
        self._content = State(initialValue: entry.isEncrypted ? "" : (entry.content ?? ""))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if entry.isEncrypted {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("This entry is encrypted")
                            .font(.headline)
                        
                        Text("Encrypted entries cannot be edited directly. You would need to decrypt them first.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
            ScrollView {
                VStack(spacing: 20) {
                    // Mood Tracking Section
                    if includeMood {
                        moodTrackingSection
                    }
                    
                    // Title Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.headline)
                                
                                TextField("Enter a title...", text: $title)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: title) { _, _ in
                                        hasChanges = true
                                    }
                            }
                            
                            // Content Editor
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Content")
                                    .font(.headline)
                                
                                TextEditor(text: $content)
                                    .frame(minHeight: 300)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                    .onChange(of: content) { _, _ in
                                        hasChanges = true
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!hasChanges)
                }
            }
        }
    }
    
    private func saveChanges() {
        do {
            let repository = DependencyContainer.shared.journalRepository
            _ = try repository.updateJournalEntry(
                entry,
                title: title.isEmpty ? nil : title,
                content: content
            )
            
            // Log mood if included
            if includeMood {
                viewModel.logMood(
                    level: selectedMoodLevel,
                    scale: selectedMoodScale,
                    notes: nil
                )
            }
            
            // Refresh the view model
            viewModel.loadData()
            dismiss()
        } catch {
            print("Error updating entry: \(error)")
        }
    }
    
    // MARK: - Mood Tracking Section
    private var moodTrackingSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Rate Your Mood")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(selectedMoodScale.description(for: selectedMoodLevel)) \(selectedMoodLevel)/\(selectedMoodScale.range.upperBound)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.yellow.opacity(0.2))
                    )
            }
            
            // Mood Slider with Emojis
            VStack(spacing: 12) {
                HStack {
                    Button(action: { selectedMoodLevel = max(selectedMoodScale.range.lowerBound, selectedMoodLevel - 1) }) {
                        Image(systemName: "minus")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Emoji faces
                    HStack(spacing: 8) {
                        ForEach(selectedMoodScale.range, id: \.self) { level in
                            Button(action: { selectedMoodLevel = level }) {
                                Text(selectedMoodScale.emoji(for: level))
                                    .font(.title)
                                    .scaleEffect(selectedMoodLevel == level ? 1.2 : 1.0)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedMoodLevel == level ? Color.accentColor : Color.clear, lineWidth: 2)
                                            .scaleEffect(1.3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { selectedMoodLevel = min(selectedMoodScale.range.upperBound, selectedMoodLevel + 1) }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Slider
                Slider(value: Binding(
                    get: { Double(selectedMoodLevel) },
                    set: { selectedMoodLevel = Int($0) }
                ), in: Double(selectedMoodScale.range.lowerBound)...Double(selectedMoodScale.range.upperBound), step: 1)
                .accentColor(.accentColor)
                .sensoryFeedback(.selection, trigger: selectedMoodLevel)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
    }
}
