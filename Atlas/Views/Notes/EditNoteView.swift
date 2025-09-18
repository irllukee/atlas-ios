import SwiftUI
import CoreData

/// Modern iOS Notes-style view for editing existing notes
struct EditNoteView: View {
    
    // MARK: - Properties
    let note: Note
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isEncrypted: Bool = false
    @State private var hasChanges = false
    @State private var showingFormattingToolbar = false
    @State private var showingMoreOptions = false
    @State private var showingDeleteConfirmation = false
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Clean white background like iOS Notes
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title Field - iOS Notes style
                titleField
                
                // Content Field - iOS Notes style
                contentField
                
                Spacer()
            }
        }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasChanges {
                            // Show confirmation dialog
                            dismiss()
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveNote()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    // Formatting toolbar
                    HStack(spacing: 20) {
                        // Bold
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            // TODO: Implement bold formatting
                        }) {
                            Image(systemName: "bold")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        
                        // Italic
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            // TODO: Implement italic formatting
                        }) {
                            Image(systemName: "italic")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        
                        // Underline
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            // TODO: Implement underline formatting
                        }) {
                            Image(systemName: "underline")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Checklist
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            // TODO: Implement checklist
                        }) {
                            Image(systemName: "checklist")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        
                        // Camera
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            // TODO: Implement camera/photo picker
                        }) {
                            Image(systemName: "camera")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        
                        // More options
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            showingMoreOptions = true
                        }) {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                }
            }
            .sheet(isPresented: $showingMoreOptions) {
                moreOptionsSheet
            }
            .alert("Delete Note", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteNote()
                }
            } message: {
                Text("Are you sure you want to delete this note? This action cannot be undone.")
            }
            .onAppear {
                loadNoteData()
            }
    }
    
    // MARK: - Title Field
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $title)
                .font(.system(size: 20, weight: .medium, design: .default))
                .foregroundColor(.primary)
                .focused($isTitleFocused)
                .submitLabel(.next)
                .onSubmit {
                    isContentFocused = true
                }
                .onChange(of: title) {
                    checkForChanges()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.clear)
        }
        .background(Color.white)
    }
    
    // MARK: - Content Field
    private var contentField: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextEditor(text: $content)
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.primary)
                .focused($isContentFocused)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .onChange(of: content) {
                    checkForChanges()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .background(Color.white)
    }
    
    // MARK: - More Options Sheet
    private var moreOptionsSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    Section {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Toggle("Encrypt Note", isOn: $isEncrypted)
                        }
                        .padding(.vertical, 4)
                        .onChange(of: isEncrypted) {
                            checkForChanges()
                        }
                    } header: {
                        Text("Security")
                    }
                    
                    Section {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text("Created")
                            Spacer()
                            Text(note.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Text("Last Updated")
                            Spacer()
                            Text(note.updatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Note Information")
                    }
                    
                    Section {
                        Button(action: {
                            // TODO: Implement sharing
                            AtlasTheme.Haptics.light()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text("Share Note")
                                Spacer()
                            }
                        }
                        .foregroundColor(.primary)
                        
                        Button(action: {
                            // TODO: Implement export
                            AtlasTheme.Haptics.light()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text("Export Note")
                                Spacer()
                            }
                        }
                        .foregroundColor(.primary)
                        
                        Button(action: {
                            showingMoreOptions = false
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                Text("Delete Note")
                                Spacer()
                            }
                        }
                        .foregroundColor(.red)
                    } header: {
                        Text("Actions")
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("More Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingMoreOptions = false
                    }
                }
            }
        }
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
            content: content,
            category: nil
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