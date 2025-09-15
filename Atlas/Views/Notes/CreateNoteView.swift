import SwiftUI
import CoreData

/// View for creating new notes
struct CreateNoteView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isEncrypted: Bool = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Form
                Form {
                    Section("Note Details") {
                        TextField("Note Title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content")
                                .font(.headline)
                            
                            TextEditor(text: $content)
                                .frame(minHeight: 200)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }
                    
                    Section("Options") {
                        // Encryption Toggle
                        Toggle("Encrypt Note", isOn: $isEncrypted)
                            .toggleStyle(SwitchToggleStyle())
                    }
                }
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(title.isEmpty || viewModel.isLoading)
                }
            }
        }
    }
    
    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                ProgressView("Creating note...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            
            HStack(spacing: 12) {
                Button("From Template") {
                    viewModel.showingTemplates = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Save Note") {
                    saveNote()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(title.isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Actions
    private func saveNote() {
        guard !title.isEmpty else { return }
        
        viewModel.createNote(
            title: title,
            content: content,
            isEncrypted: isEncrypted
        )
    }
}


// MARK: - Preview
struct CreateNoteView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        let viewModel = NotesViewModel(dataManager: dataManager, encryptionService: encryptionService)
        
        CreateNoteView(viewModel: viewModel)
    }
}
