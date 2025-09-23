import SwiftUI

// MARK: - Notes Detail View
struct NotesDetailView: View {
    let note: Note?
    
    @EnvironmentObject private var notesService: NotesService
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var html: String = "<p></p>"
    @State private var isFavorite: Bool = false
    @State private var selectedFolder: NoteFolder?
    @State private var selectedTags: Set<NoteTag> = []
    @State private var showingFolderPicker = false
    @State private var showingTagPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var hasUnsavedChanges = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingLinkCreation = false
    @State private var linkURL = ""
    @State private var linkText = ""
    @State private var showingColorPicker = false
    @State private var selectedTextColor: UIColor?
    @State private var showingFindReplace = false
    @State private var searchText = ""
    @State private var replaceText = ""
    @State private var foundRanges: [NSRange] = []
    @State private var currentMatchIndex = 0
    
    // Aztec Editor Controller
    @StateObject private var editorController = AztecEditorController()
    
    // Auto-save
    @State private var autoSaveTimer: Timer?
    private let autoSaveInterval: TimeInterval = 2.0
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 12) {
                    // Title Field
                    AtlasTextField("Title", placeholder: "Note Title", text: $title, style: .floating)
                        .padding(.horizontal, AtlasTheme.Spacing.md)
                        .onChange(of: title) { _, _ in
                            hasUnsavedChanges = true
                            scheduleAutoSave()
                        }
                    
                    // Aztec Editor
                    AztecEditorView(html: $html, controller: editorController, placeholder: "")
                        .frame(minHeight: 300)
                        .background(
                            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                .fill(AtlasTheme.Colors.glassBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, AtlasTheme.Spacing.md)
                        .onChange(of: html) { _, _ in
                            hasUnsavedChanges = true
                            scheduleAutoSave()
                        }
                    
                    // Metadata Bar
                    metadataBar
                    
                    Spacer()
                }
                
                // Floating Editor Toolbar (appears over keyboard)
                EditorToolbar(controller: editorController)
            }
            .background(AtlasTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            // Show save confirmation
                            saveAndDismiss()
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(AtlasTheme.Colors.text)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(note == nil ? "New Note" : "Edit Note")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(AtlasTheme.Colors.text)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: AtlasTheme.Spacing.sm) {
                        // Favorite Button
                        Button(action: toggleFavorite) {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isFavorite ? AtlasTheme.Colors.warning : AtlasTheme.Colors.text)
                        }
                        
                        // More Options
                        Menu {
                            Button("Folder") {
                                showingFolderPicker = true
                            }
                            
                            Button("Tags") {
                                showingTagPicker = true
                            }
                            
                            if note != nil {
                                Divider()
                                
                                Button("Delete Note", role: .destructive) {
                                    showingDeleteConfirmation = true
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AtlasTheme.Colors.text)
                        }
                        
                        // Save Button
                        Button("Save") {
                            saveAndDismiss()
                        }
                        .foregroundColor(AtlasTheme.Colors.primary)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            print("🔧 DEBUG: NotesDetailView appeared - note: \(note?.title ?? "nil (new note)")")
            print("🔧 DEBUG: Initial title: '\(title)'")
            print("🔧 DEBUG: Initial html: '\(html)'")
            setupNote()
            startAutoSave()
        }
        .onDisappear {
            stopAutoSave()
        }
        .sheet(isPresented: $showingFolderPicker) {
            FolderPickerView(selectedFolder: $selectedFolder)
        }
        .sheet(isPresented: $showingTagPicker) {
            NotesTagPickerView(selectedTags: $selectedTags)
        }
        .alert("Delete Note", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteNote()
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingLinkCreation) {
            LinkCreationView(url: $linkURL, linkText: $linkText)
        }
        .sheet(isPresented: $showingColorPicker) {
            TextColorPicker(selectedColor: $selectedTextColor)
        }
        .sheet(isPresented: $showingFindReplace) {
            FindReplaceView(
                searchText: $searchText,
                replaceText: $replaceText,
                foundRanges: $foundRanges,
                currentMatchIndex: $currentMatchIndex,
                onFind: {
                    foundRanges = editorController.findText(searchText)
                    currentMatchIndex = 0
                    if !foundRanges.isEmpty {
                        editorController.selectText(at: foundRanges[0])
                    }
                },
                onReplace: {
                    if !foundRanges.isEmpty && currentMatchIndex < foundRanges.count {
                        // Replace single occurrence
                        let replacementCount = editorController.replaceText(searchText, with: replaceText)
                        if replacementCount > 0 {
                            foundRanges = editorController.findText(searchText)
                            if currentMatchIndex >= foundRanges.count {
                                currentMatchIndex = max(0, foundRanges.count - 1)
                            }
                            if !foundRanges.isEmpty {
                                editorController.selectText(at: foundRanges[currentMatchIndex])
                            }
                        }
                    }
                },
                onReplaceAll: {
                    let replacementCount = editorController.replaceText(searchText, with: replaceText)
                    foundRanges = []
                    currentMatchIndex = 0
                    print("Replaced \(replacementCount) occurrences")
                },
                onSelectMatch: { index in
                    if index < foundRanges.count {
                        editorController.selectText(at: foundRanges[index])
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .insertImage)) { _ in
            showingImagePicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .insertLink)) { _ in
            linkURL = ""
            linkText = ""
            showingLinkCreation = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectTextColor)) { _ in
            showingColorPicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showFindReplace)) { _ in
            searchText = ""
            replaceText = ""
            foundRanges = []
            currentMatchIndex = 0
            showingFindReplace = true
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                editorController.insertImageFromData(imageData)
                selectedImage = nil // Reset after insertion
            }
        }
        .onChange(of: linkURL) { _, newURL in
            if !newURL.isEmpty && !showingLinkCreation {
                // Link was created, insert it
                editorController.insertLinkWithURL(newURL, text: linkText.isEmpty ? nil : linkText)
                linkURL = ""
                linkText = ""
            }
        }
        .onChange(of: selectedTextColor) { _, newColor in
            if let color = newColor {
                editorController.applyTextColor(color)
                selectedTextColor = nil // Reset after application
            }
        }
    }
    
    // MARK: - Metadata Bar
    private var metadataBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AtlasTheme.Colors.glassBorder)
            
            HStack(spacing: AtlasTheme.Spacing.md) {
                // Folder
                Button(action: { showingFolderPicker = true }) {
                    HStack(spacing: AtlasTheme.Spacing.xs) {
                        Image(systemName: "folder")
                            .font(.system(size: 14))
                        Text(selectedFolder?.name ?? "No Folder")
                            .font(AtlasTheme.Typography.caption)
                    }
                    .foregroundColor(AtlasTheme.Colors.text)
                    .padding(.horizontal, AtlasTheme.Spacing.sm)
                    .padding(.vertical, AtlasTheme.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.small)
                            .fill(AtlasTheme.Colors.glassBackground)
                    )
                }
                
                // Tags
                Button(action: { showingTagPicker = true }) {
                    HStack(spacing: AtlasTheme.Spacing.xs) {
                        Image(systemName: "tag")
                            .font(.system(size: 14))
                        Text("\(selectedTags.count) tags")
                            .font(AtlasTheme.Typography.caption)
                    }
                    .foregroundColor(AtlasTheme.Colors.text)
                    .padding(.horizontal, AtlasTheme.Spacing.sm)
                    .padding(.vertical, AtlasTheme.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.small)
                            .fill(AtlasTheme.Colors.glassBackground)
                    )
                }
                
                // Statistics
                HStack(spacing: AtlasTheme.Spacing.sm) {
                    Text("\(editorController.getWordCount()) words")
                        .font(AtlasTheme.Typography.caption2)
                        .foregroundColor(AtlasTheme.Colors.tertiaryText)
                    
                    Text("•")
                        .font(AtlasTheme.Typography.caption2)
                        .foregroundColor(AtlasTheme.Colors.tertiaryText)
                    
                    Text(editorController.getReadingTime())
                        .font(AtlasTheme.Typography.caption2)
                        .foregroundColor(AtlasTheme.Colors.tertiaryText)
                }
                
                Spacer()
                
                // Auto-save indicator
                if hasUnsavedChanges {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AtlasTheme.Colors.warning)
                            .frame(width: 6, height: 6)
                        Text("Unsaved")
                            .font(AtlasTheme.Typography.caption2)
                            .foregroundColor(AtlasTheme.Colors.warning)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AtlasTheme.Colors.success)
                        Text("Saved")
                            .font(AtlasTheme.Typography.caption2)
                            .foregroundColor(AtlasTheme.Colors.success)
                    }
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.vertical, AtlasTheme.Spacing.sm)
            .background(AtlasTheme.Colors.glassBackgroundLight)
        }
    }
    
    // MARK: - Setup
    private func setupNote() {
        if let note = note {
            title = note.title ?? ""
            // Convert content to HTML if it exists, otherwise use empty paragraph
            if let content = note.content, !content.isEmpty {
                html = content
            } else {
                html = "<p></p>"
            }
            isFavorite = note.isFavorite
            selectedFolder = note.folder
            selectedTags = Set(note.tags?.allObjects as? [NoteTag] ?? [])
            print("🔧 DEBUG: Setup existing note - title: '\(title)', html: '\(html)'")
        } else {
            title = ""
            html = "<p></p>"
            isFavorite = false
            selectedFolder = nil
            selectedTags = []
            print("🔧 DEBUG: Setup new note - title: '\(title)', html: '\(html)'")
        }
    }
    
    // MARK: - Actions
    private func toggleFavorite() {
        isFavorite.toggle()
        hasUnsavedChanges = true
        AtlasTheme.Haptics.light()
    }
    
    private func saveAndDismiss() {
        saveNote()
        dismiss()
    }
    
    private func deleteNote() {
        if let note = note {
            notesService.deleteNote(note)
            AtlasTheme.Haptics.success()
            dismiss()
        }
    }
    
    // MARK: - Auto-save
    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                if hasUnsavedChanges {
                    saveNote()
                }
            }
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func scheduleAutoSave() {
        // Debounce auto-save
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: false) { _ in
            DispatchQueue.main.async {
                saveNote()
            }
        }
    }
    
    private func saveNote() {
        // Derive clean title from content if title is empty or contains HTML
        let cleanTitle = deriveCleanTitle(from: title, content: html)
        
        if let note = note {
            // Update existing note
            notesService.updateNote(note, title: cleanTitle, content: html)
            note.isFavorite = isFavorite
            note.folder = selectedFolder
            
            // Update tags
            note.tags = NSSet(set: selectedTags)
        } else {
            // Create new note
            let newNote = notesService.createNote(title: cleanTitle, content: html, folder: selectedFolder)
            newNote.isFavorite = isFavorite
            newNote.tags = NSSet(set: selectedTags)
        }
        
        hasUnsavedChanges = false
        notesService.saveContext()
    }
    
    // MARK: - Title Derivation
    private func deriveCleanTitle(from title: String, content: String) -> String {
        // If we have a clean title, use it
        if !title.isEmpty && !title.contains("<") && !title.contains("&") {
            return title
        }
        
        // Otherwise derive from content
        if !content.isEmpty {
            let plainText = stripHTML(from: content)
            let lines = plainText.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        
        return "Untitled Note"
    }
    
    private func stripHTML(from html: String) -> String {
        // Remove DOCTYPE and HTML tags
        let cleanHTML = html
            .replacingOccurrences(of: "<!DOCTYPE[^>]*>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
        
        return cleanHTML
    }
}

// MARK: - Folder Picker View
struct FolderPickerView: View {
    @Binding var selectedFolder: NoteFolder?
    @EnvironmentObject private var notesService: NotesService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("No Folder") {
                        selectedFolder = nil
                        dismiss()
                    }
                    .foregroundColor(AtlasTheme.Colors.text)
                }
                
                Section("Folders") {
                    ForEach(notesService.folders, id: \.uuid) { folder in
                        Button(action: {
                            selectedFolder = folder
                            dismiss()
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: folder.color ?? "#007AFF") ?? AtlasTheme.Colors.primary)
                                    .frame(width: 12, height: 12)
                                
                                Text(folder.name ?? "Unnamed Folder")
                                    .foregroundColor(AtlasTheme.Colors.text)
                                
                                Spacer()
                                
                                if selectedFolder?.uuid == folder.uuid {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AtlasTheme.Colors.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Notes Tag Picker View
struct NotesTagPickerView: View {
    @Binding var selectedTags: Set<NoteTag>
    @EnvironmentObject private var notesService: NotesService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if notesService.tags.isEmpty {
                    VStack(spacing: AtlasTheme.Spacing.md) {
                        Image(systemName: "tag")
                            .font(.system(size: 48))
                            .foregroundColor(AtlasTheme.Colors.tertiaryText)
                        
                        Text("No tags yet")
                            .font(AtlasTheme.Typography.title3)
                            .foregroundColor(AtlasTheme.Colors.text)
                        
                        Text("Create tags to organize your notes")
                            .font(AtlasTheme.Typography.body)
                            .foregroundColor(AtlasTheme.Colors.tertiaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AtlasTheme.Spacing.xl)
                } else {
                    ForEach(notesService.tags, id: \.uuid) { tag in
                        Button(action: {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: tag.color ?? "#FF9500") ?? AtlasTheme.Colors.secondary)
                                    .frame(width: 12, height: 12)
                                
                                Text(tag.name ?? "Unnamed Tag")
                                    .foregroundColor(AtlasTheme.Colors.text)
                                
                                Spacer()
                                
                                if selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AtlasTheme.Colors.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            notesService.loadData()
        }
    }
}

// MARK: - Preview
#Preview {
    NotesDetailView(note: nil)
}
