import SwiftUI
import CoreData

/// View for editing existing notes
struct EditNoteView: View {
    
    // MARK: - Properties
    let note: Note
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isEncrypted: Bool = false
    @State private var hasChanges = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Form
                Form {
                    Section("Note Details") {
                        TextField("Note Title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: title) { _ in
                                checkForChanges()
                            }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content")
                                .font(.headline)
                            
                            TextEditor(text: $content)
                                .frame(minHeight: 200)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .onChange(of: content) { _ in
                                    checkForChanges()
                                }
                        }
                    }
                    
                    Section("Options") {
                        // Encryption Toggle
                        Toggle("Encrypt Note", isOn: $isEncrypted)
                            .toggleStyle(SwitchToggleStyle())
                            .onChange(of: isEncrypted) { _ in
                                checkForChanges()
                            }
                    }
                    
                    Section("Note Info") {
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(note.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(note.updatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasChanges {
                            // Show confirmation dialog
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(!hasChanges || viewModel.isLoading)
                }
            }
            .onAppear {
                loadNoteData()
            }
        }
    }
    
    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                ProgressView("Saving note...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            
            HStack(spacing: 12) {
                Button("Delete Note") {
                    deleteNote()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                
                Button("Save Changes") {
                    saveNote()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!hasChanges || viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Actions
    private func loadNoteData() {
        title = note.title ?? ""
        content = note.content ?? ""
        isEncrypted = note.isEncrypted
    }
    
    private func checkForChanges() {
        hasChanges = title != (note.title ?? "") ||
                    content != (note.content ?? "") ||
                    isEncrypted != note.isEncrypted
    }
    
    private func saveNote() {
        guard hasChanges else { return }
        
        viewModel.updateNote(
            note,
            title: title,
            content: content
        )
        
        dismiss()
    }
    
    private func deleteNote() {
        viewModel.deleteNote(note)
        dismiss()
    }
}

// MARK: - Preview
struct EditNoteView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        let viewModel = NotesViewModel(dataManager: dataManager, encryptionService: encryptionService)
        
        // Create a sample note for preview
        let note = createSampleNote()
        
        return EditNoteView(note: note, viewModel: viewModel)
    }
    
    private static func createSampleNote() -> Note {
        let context = PersistenceController.preview.container.viewContext
        let note = Note(context: context)
        note.title = "Sample Note"
        note.content = "This is a sample note content for preview purposes."
        note.createdAt = Date()
        note.updatedAt = Date()
        return note
    }
}