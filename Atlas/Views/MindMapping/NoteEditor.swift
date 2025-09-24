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
    @State private var isLoaded = false
    @State private var saveWorkItem: DispatchWorkItem?

    var body: some View {
        NavigationView {
            Form {
                Section("Title") {
                    TextField("Idea", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .accessibilityLabel("Title field")
                        .onChange(of: title) { 
                            hasChanges = true
                            saveDebounced()
                        }
                }
                Section("Note") {
                    TextEditor(text: $note)
                        .frame(minHeight: 200)
                        .accessibilityLabel("Note text")
                        .onChange(of: note) { 
                            hasChanges = true
                            saveDebounced()
                        }
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
            .task {
                // Load data off main thread to prevent UI blocking
                await loadNodeData()
            }
            .onDisappear {
                // Cancel any pending save operations
                saveWorkItem?.cancel()
            }
        }
    }
    
    private func loadNodeData() async {
        // Load node data in background to prevent UI blocking
        let nodeTitle = node.title ?? ""
        let nodeNote = node.note ?? ""
        
        // Update UI on main thread
        await MainActor.run {
            self.title = nodeTitle
            self.note = nodeNote
            self.hasChanges = false
            self.isLoaded = true
        }
    }
    
    private func saveDebounced() {
        // Cancel existing save operation
        saveWorkItem?.cancel()
        
        // Create new debounced save operation
        let workItem = DispatchWorkItem { [weak viewContext, weak node] in
            guard let viewContext = viewContext, let node = node else { return }
            
            // Update node properties
            let trimmedTitle = self.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedTitle.isEmpty {
                node.title = trimmedTitle
            }
            
            let trimmedNote = self.note.trimmingCharacters(in: .whitespacesAndNewlines)
            node.note = trimmedNote.isEmpty ? nil : trimmedNote
            
            // Save on background context to avoid blocking UI
            viewContext.perform {
                do {
                    try viewContext.save()
                } catch {
                    print("Failed to auto-save note: \(error)")
                }
            }
        }
        
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
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
