import SwiftUI
import CoreData

struct CreateNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NotesViewModel
    let noteToEdit: Note?
    
    init(viewModel: NotesViewModel, noteToEdit: Note? = nil) {
        self.viewModel = viewModel
        self.noteToEdit = noteToEdit
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Create Note View")
                    .font(.title)
                    .padding()
                
                Text("This is a simplified version of the Create Note view.")
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle(noteToEdit != nil ? "Edit Note" : "New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CreateNoteView(viewModel: NotesViewModel(dataManager: DataManager.shared, encryptionService: EncryptionService.shared))
}