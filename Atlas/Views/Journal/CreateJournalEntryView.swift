import SwiftUI

struct CreateJournalEntryView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var content: String = ""
    @State private var selectedType: JournalEntryType = .daily
    @State private var selectedMood: MoodLevel? = nil
    @State private var gratitudeEntries: [String] = []
    @State private var prompt: String = ""
    @State private var isEncrypted: Bool = false
    @State private var showingGratitudeEditor: Bool = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section("Entry Type") {
                        Picker("Type", selection: $selectedType) {
                            ForEach(JournalEntryType.allCases, id: \.self) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.rawValue)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section("Content") {
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    
                    if selectedType == .gratitude {
                        Section("Gratitude Entries") {
                            ForEach(gratitudeEntries.indices, id: \.self) { index in
                                HStack {
                                    TextField("Gratitude \(index + 1)", text: $gratitudeEntries[index])
                                    Button(action: {
                                        gratitudeEntries.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            Button(action: {
                                gratitudeEntries.append("")
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
                            Text("Current Mood")
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
                        }
                    }
                    
                    Section("Options") {
                        Toggle("Encrypt Entry", isOn: $isEncrypted)
                            .toggleStyle(SwitchToggleStyle())
                        
                        TextField("Prompt (optional)", text: $prompt)
                    }
                }
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle("New Journal Entry")
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
                    .disabled(content.isEmpty || viewModel.isLoading)
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
    private func saveEntry() {
        guard !content.isEmpty else { return }
        
        viewModel.createJournalEntry(
            content: content,
            type: selectedType,
            mood: selectedMood,
            gratitudeEntries: gratitudeEntries.filter { !$0.isEmpty },
            prompt: prompt.isEmpty ? nil : prompt,
            isEncrypted: isEncrypted
        )
        
        dismiss()
    }
}

// MARK: - Preview
struct CreateJournalEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        let viewModel = JournalViewModel(dataManager: dataManager, encryptionService: encryptionService)
        
        CreateJournalEntryView(viewModel: viewModel)
    }
}
