import SwiftUI
import CoreData

struct EditJournalEntryView: View {
    // MARK: - Properties
    @ObservedObject var entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var content: String = ""
    @State private var selectedMood: MoodLevel? = nil
    @State private var gratitudeEntries: [String] = []
    @State private var prompt: String = ""
    @State private var hasChanges = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section("Content") {
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .onChange(of: content) { checkForChanges() }
                    }
                    
                    // Gratitude entries (if any)
                    if !gratitudeEntries.isEmpty {
                        Section("Gratitude Entries") {
                            ForEach(gratitudeEntries.indices, id: \.self) { index in
                                HStack {
                                    TextField("Gratitude \(index + 1)", text: $gratitudeEntries[index])
                                        .onChange(of: gratitudeEntries[index]) { checkForChanges() }
                                    Button(action: {
                                        gratitudeEntries.remove(at: index)
                                        checkForChanges()
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            Button(action: {
                                gratitudeEntries.append("")
                                checkForChanges()
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Gratitude Entry")
                                }
                            }
                        }
                    }
                    
                    Section("Mood") {
                        HStack {
                            Text("Mood")
                            Spacer()
                            Picker("Mood", selection: $selectedMood) {
                                Text("None").tag(nil as MoodLevel?)
                                ForEach(MoodLevel.allCases) { mood in
                                    HStack {
                                        Text(mood.emoji)
                                        Text(mood.description)
                                    }
                                    .tag(mood as MoodLevel?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: selectedMood) { checkForChanges() }
                        }
                    }
                    
                    Section("Entry Info") {
                        HStack {
                            Text("Type")
                            Spacer()
                            Text(entryType.rawValue)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(entry.createdAt ?? Date(), formatter: itemFormatter)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(entry.updatedAt ?? Date(), formatter: itemFormatter)
                                .foregroundColor(.secondary)
                        }
                        
                        if entry.isEncrypted {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                Text("Encrypted Entry")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle("Edit Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(!hasChanges || viewModel.isLoading)
                }
            }
            .onAppear {
                loadEntryData()
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
    
    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Actions
    private func loadEntryData() {
        content = viewModel.getJournalContent(entry)
        selectedMood = MoodLevel(rawValue: entry.mood)
        gratitudeEntries = viewModel.getGratitudeEntries(entry)
        prompt = entry.prompt ?? ""
    }
    
    private func checkForChanges() {
        let originalContent = viewModel.getJournalContent(entry)
        let originalMood = MoodLevel(rawValue: entry.mood)
        let originalGratitude = viewModel.getGratitudeEntries(entry)
        
        hasChanges = content != originalContent ||
                    selectedMood != originalMood ||
                    gratitudeEntries != originalGratitude
    }
    
    private func saveEntry() {
        guard hasChanges else { return }
        
        viewModel.updateJournalEntry(
            entry,
            content: content,
            mood: selectedMood,
            gratitudeEntries: gratitudeEntries.filter { !$0.isEmpty }
        )
        
        dismiss()
    }
    
    private var entryType: JournalEntryType {
        if entry.isDream {
            return .dream
        } else if let gratitudeEntries = entry.gratitudeEntries, !gratitudeEntries.isEmpty {
            return .gratitude
        } else {
            return .daily
        }
    }
}

// MARK: - Preview
struct EditJournalEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        let viewModel = JournalViewModel(dataManager: dataManager, encryptionService: encryptionService)
        
        // Create a sample journal entry for preview
        let context = PersistenceController.preview.container.viewContext
        let entry = JournalEntry(context: context)
        entry.uuid = UUID()
        entry.content = "This is a sample journal entry for preview purposes."
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.isDream = false
        entry.mood = MoodLevel.good.rawValue
        
        return EditJournalEntryView(entry: entry, viewModel: viewModel)
    }
}
