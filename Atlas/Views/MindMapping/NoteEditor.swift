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
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    @State private var titleValidationError: String?
    @State private var noteValidationError: String?
    
    // Data validation constants
    private let maxTitleLength = 100
    private let maxNoteLength = 10000
    private let minTitleLength = 1
    
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
    
    private func handleMemoryWarning() {
        print("🧠 Memory warning in NoteEditor - canceling pending saves")
        
        // Cancel any pending save operations to free up resources
        saveWorkItem?.cancel()
        saveWorkItem = nil
        
        // Note: Text content is kept as it's essential for user experience
        // The save operation will be retried when the user makes changes
    }
    
    private func validateTitle(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return "Title cannot be empty"
        }
        
        if trimmed.count < minTitleLength {
            return "Title must be at least \(minTitleLength) character"
        }
        
        if title.count > maxTitleLength {
            return "Title must be \(maxTitleLength) characters or less"
        }
        
        return nil
    }
    
    private func validateNote(_ note: String) -> String? {
        if note.count > maxNoteLength {
            return "Note must be \(maxNoteLength) characters or less"
        }
        
        return nil
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                Form {
                    Section("Title") {
                        TextField("Idea", text: $title)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.done)
                            .accessibilityLabel("Title field")
                            .id("titleField")
                            .onChange(of: title) { 
                                hasChanges = true
                                titleValidationError = validateTitle(title)
                                saveDebounced()
                            }
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("titleField", anchor: .center)
                                }
                            }
                        
                        // Character count and validation feedback
                        HStack {
                            Spacer()
                            Text("\(title.count)/\(maxTitleLength)")
                                .font(.caption)
                                .foregroundColor(title.count > maxTitleLength ? .red : .secondary)
                        }
                        
                        if let titleError = titleValidationError {
                            Text(titleError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    Section("Note") {
                        TextEditor(text: $note)
                            .frame(minHeight: 200)
                            .accessibilityLabel("Note text")
                            .id("noteEditor")
                            .onChange(of: note) { 
                                hasChanges = true
                                noteValidationError = validateNote(note)
                                saveDebounced()
                            }
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("noteEditor", anchor: .center)
                                }
                            }
                        
                        // Character count and validation feedback
                        HStack {
                            Spacer()
                            Text("\(note.count)/\(maxNoteLength)")
                                .font(.caption)
                                .foregroundColor(note.count > maxNoteLength ? .red : .secondary)
                        }
                        
                        if let noteError = noteValidationError {
                            Text(noteError)
                                .font(.caption)
                                .foregroundColor(.red)
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
                            .disabled(!hasChanges || titleValidationError != nil || noteValidationError != nil)
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
                .alert("Error", isPresented: $showingErrorAlert) {
                    Button("OK", role: .cancel) {
                        errorMessage = nil
                    }
                } message: {
                    Text(errorMessage ?? "An unknown error occurred")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    handleMemoryWarning()
                }
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
            
            // Save directly since we're already on the main queue
            do {
                try viewContext.save()
            } catch {
                showError("Failed to auto-save note: \(error.localizedDescription)")
            }
        }
        
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func save() {
        // Validate before saving
        if let titleError = validateTitle(title) {
            showError("Cannot save: \(titleError)")
            return
        }
        
        if let noteError = validateNote(note) {
            showError("Cannot save: \(noteError)")
            return
        }
        
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
            showError("Failed to save note: \(error.localizedDescription)")
        }
    }
}