import SwiftUI
import CoreData

struct NoteEditor: View, @preconcurrency Identifiable {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var node: Node
    var id: UUID { node.uuid ?? UUID() }

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var hasChanges = false

    var body: some View {
        NavigationView {
            Form {
                Section("Title") {
                    TextField("Idea", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .accessibilityLabel("Title field")
                        .onChange(of: title) { hasChanges = true }
                }
                Section("Note") {
                    TextEditor(text: $note)
                        .frame(minHeight: 200)
                        .accessibilityLabel("Note text")
                        .onChange(of: note) { hasChanges = true }
                }
                
                Section {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text((node.createdAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { 
                        if hasChanges {
                            // Could add confirmation alert here
                        }
                        dismiss() 
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(!hasChanges)
                }
            }
            .onAppear {
                title = node.title ?? ""
                note = node.note ?? ""
                hasChanges = false
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty { 
            node.title = trimmedTitle 
        }
        
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        node.note = trimmedNote.isEmpty ? nil : trimmedNote
        
        do {
            try viewContext.save()
            hasChanges = false
            dismiss()
        } catch {
            print("Failed to save note: \(error)")
        }
    }
}
