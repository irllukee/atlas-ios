import SwiftUI

// MARK: - Notes List View
struct NotesListView: View {
    @EnvironmentObject private var notesService: NotesService
    @State private var showingNewNote = false
    @State private var showingNoteDetail = false
    @State private var showingFolderManagement = false
    @State private var showingTagManagement = false
    @State private var selectedNote: Note?
    @State private var searchText = ""
    @State private var sortOption: SortOption = .updatedAt
    
    // Selection state
    @State private var isSelectionMode = false
    @State private var selectedNotes: Set<Note> = []
    @State private var showingMoveToFolder = false
    @State private var showingDeleteConfirmation = false
    
    enum SortOption: String, CaseIterable {
        case updatedAt = "Last Updated"
        case createdAt = "Created"
        case title = "Title"
        case folder = "Folder"
        
        var sortDescriptor: NSSortDescriptor {
            switch self {
            case .updatedAt: return NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)
            case .createdAt: return NSSortDescriptor(keyPath: \Note.createdAt, ascending: false)
            case .title: return NSSortDescriptor(keyPath: \Note.title, ascending: true)
            case .folder: return NSSortDescriptor(keyPath: \Note.folder?.name, ascending: true)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search and Filters
                searchAndFiltersView
                
                // Content
                if notesService.isLoading {
                    loadingView
                } else if notesService.filteredNotes.isEmpty {
                    emptyStateView
                } else {
                    notesContentView
                }
            }
            .background(AtlasTheme.Colors.background)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showingNewNote) {
            NotesDetailView(note: nil)
                .onAppear {
                    print("🔧 DEBUG: NotesDetailView fullscreen appeared")
                }
        }
        .sheet(isPresented: $showingFolderManagement) {
            FolderManagementView()
        }
        .sheet(isPresented: $showingTagManagement) {
            TagManagementView()
        }
        .fullScreenCover(isPresented: $showingNoteDetail) {
            if let note = selectedNote {
                NotesDetailView(note: note)
            }
        }
        .onAppear {
            notesService.loadData()
        }
        .onChange(of: searchText) { _, newValue in
            notesService.searchText = newValue
        }
        .alert("Delete Selected Notes", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedNotes()
            }
        } message: {
            Text("Are you sure you want to delete \(selectedNotes.count) note(s)? This action cannot be undone.")
        }
        .sheet(isPresented: $showingMoveToFolder) {
            MoveToFolderView(selectedNotes: Array(selectedNotes))
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(AtlasTheme.Typography.largeTitle)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                if isSelectionMode {
                    Text("\(selectedNotes.count) selected")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.primary)
                } else {
                    Text("\(notesService.notes.count) notes")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.tertiaryText)
                }
            }
            
            Spacer()
            
            HStack(spacing: AtlasTheme.Spacing.sm) {
                if isSelectionMode {
                    // Selection mode controls
                    selectionModeControls
                } else {
                    // Normal mode controls
                    normalModeControls
                }
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.md)
        .padding(.top, AtlasTheme.Spacing.sm)
    }
    
    // MARK: - Normal Mode Controls
    private var normalModeControls: some View {
        HStack(spacing: AtlasTheme.Spacing.sm) {
            // Selection Button
            Button(action: {
                isSelectionMode = true
                AtlasTheme.Haptics.light()
            }) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AtlasTheme.Colors.text)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(AtlasTheme.Colors.glassBackground)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Circle())
            
            // New Note Button
            Button(action: {
                print("🔧 DEBUG: Plus button in header tapped")
                showingNewNote = true
                print("🔧 DEBUG: showingNewNote set to: \(showingNewNote)")
                AtlasTheme.Haptics.medium()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(AtlasTheme.Colors.primary)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Circle())
        }
    }
    
    // MARK: - Selection Mode Controls
    private var selectionModeControls: some View {
        HStack(spacing: AtlasTheme.Spacing.sm) {
            // Cancel Selection
            Button(action: {
                isSelectionMode = false
                selectedNotes.removeAll()
                AtlasTheme.Haptics.light()
            }) {
                Text("Cancel")
                    .font(AtlasTheme.Typography.button)
                    .foregroundColor(AtlasTheme.Colors.text)
            }
            
            // Select All
            Button(action: {
                if selectedNotes.count == sortedNotes.count {
                    selectedNotes.removeAll()
                } else {
                    selectedNotes = Set(sortedNotes)
                }
                AtlasTheme.Haptics.light()
            }) {
                Text(selectedNotes.count == sortedNotes.count ? "Deselect All" : "Select All")
                    .font(AtlasTheme.Typography.button)
                    .foregroundColor(AtlasTheme.Colors.primary)
            }
            
            // Actions Menu
            if !selectedNotes.isEmpty {
                Menu {
                    Button("Move to Folder") {
                        showingMoveToFolder = true
                    }
                    
                    Button("Delete Selected", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AtlasTheme.Colors.text)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(AtlasTheme.Colors.glassBackground)
                        )
                }
            }
        }
    }
    
    // MARK: - Search and Filters View
    private var searchAndFiltersView: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AtlasTheme.Colors.tertiaryText)
                
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AtlasTheme.Typography.body)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        AtlasTheme.Haptics.light()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AtlasTheme.Colors.tertiaryText)
                    }
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.vertical, AtlasTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                    .fill(AtlasTheme.Colors.glassBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                    .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
            )
            
            // Filters and Sort
            HStack {
                // Sort Menu
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: {
                            sortOption = option
                            AtlasTheme.Haptics.light()
                        }) {
                            HStack {
                                Text(option.rawValue)
                                if sortOption == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14))
                        Text(sortOption.rawValue)
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
                
                Spacer()
                
                // Filter Buttons
                HStack(spacing: AtlasTheme.Spacing.xs) {
                    // Folders Filter
                    Menu {
                        Button("All Folders") {
                            notesService.selectedFolder = nil
                            AtlasTheme.Haptics.light()
                        }
                        
                        ForEach(notesService.folders, id: \.uuid) { folder in
                            Button(folder.name ?? "Unnamed") {
                                notesService.selectedFolder = folder
                                AtlasTheme.Haptics.light()
                            }
                        }
                        
                        Divider()
                        
                        Button("Manage Folders") {
                            showingFolderManagement = true
                        }
                    } label: {
                        filterButton(
                            title: notesService.selectedFolder?.name ?? "Folders",
                            icon: "folder",
                            isActive: notesService.selectedFolder != nil
                        )
                    }
                    
                    // Tags Filter
                    Menu {
                        Button("All Tags") {
                            notesService.selectedTag = nil
                            AtlasTheme.Haptics.light()
                        }
                        
                        ForEach(notesService.tags, id: \.uuid) { tag in
                            Button(tag.name ?? "Unnamed") {
                                notesService.selectedTag = tag
                                AtlasTheme.Haptics.light()
                            }
                        }
                        
                        Divider()
                        
                        Button("Manage Tags") {
                            showingTagManagement = true
                        }
                    } label: {
                        filterButton(
                            title: notesService.selectedTag?.name ?? "Tags",
                            icon: "tag",
                            isActive: notesService.selectedTag != nil
                        )
                    }
                }
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.md)
    }
    
    // MARK: - Content Views
    private var notesContentView: some View {
        ScrollView {
            LazyVStack(spacing: AtlasTheme.Spacing.sm) {
                ForEach(sortedNotes, id: \.uuid) { note in
                    NoteCardView(
                        note: note,
                        isSelected: selectedNotes.contains(note),
                        isSelectionMode: isSelectionMode
                    ) {
                        if isSelectionMode {
                            // Toggle selection
                            if selectedNotes.contains(note) {
                                selectedNotes.remove(note)
                            } else {
                                selectedNotes.insert(note)
                            }
                            AtlasTheme.Haptics.light()
                        } else {
                            // Open note
                            selectedNote = note
                            showingNoteDetail = true
                            AtlasTheme.Haptics.light()
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        if !isSelectionMode {
                            // Hold to delete (only in normal mode)
                            notesService.deleteNote(note)
                            AtlasTheme.Haptics.success()
                        }
                    }
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.bottom, AtlasTheme.Spacing.xl)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: AtlasTheme.Colors.primary))
            
            Text("Loading notes...")
                .font(AtlasTheme.Typography.body)
                .foregroundColor(AtlasTheme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AtlasTheme.Spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(AtlasTheme.Colors.tertiaryText)
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                Text("No notes found")
                    .font(AtlasTheme.Typography.title2)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("Create your first note to get started")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                print("🔧 DEBUG: Plus button in empty state tapped")
                showingNewNote = true
                print("🔧 DEBUG: showingNewNote set to: \(showingNewNote)")
                AtlasTheme.Haptics.medium()
            }) {
                HStack(spacing: AtlasTheme.Spacing.sm) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                    Text("Create Note")
                        .font(AtlasTheme.Typography.button)
                }
                .foregroundColor(.white)
                .padding(.horizontal, AtlasTheme.Spacing.lg)
                .padding(.vertical, AtlasTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                        .fill(AtlasTheme.Colors.primary)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AtlasTheme.Spacing.xl)
    }
    
    // MARK: - Helper Views
    private func filterButton(title: String, icon: String, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(title)
                .font(AtlasTheme.Typography.caption)
        }
        .foregroundColor(isActive ? AtlasTheme.Colors.primary : AtlasTheme.Colors.text)
        .padding(.horizontal, AtlasTheme.Spacing.sm)
        .padding(.vertical, AtlasTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.small)
                .fill(isActive ? AtlasTheme.Colors.primary.opacity(0.2) : AtlasTheme.Colors.glassBackground)
        )
    }
    
    // MARK: - Actions
    private func deleteSelectedNotes() {
        for note in selectedNotes {
            notesService.deleteNote(note)
        }
        selectedNotes.removeAll()
        isSelectionMode = false
        AtlasTheme.Haptics.success()
    }
    
    // MARK: - Computed Properties
    private var sortedNotes: [Note] {
        let filtered = notesService.filteredNotes
        return filtered.sorted { note1, note2 in
            switch sortOption {
            case .updatedAt:
                return (note1.updatedAt ?? Date.distantPast) > (note2.updatedAt ?? Date.distantPast)
            case .createdAt:
                return (note1.createdAt ?? Date.distantPast) > (note2.createdAt ?? Date.distantPast)
            case .title:
                return (note1.title ?? "") < (note2.title ?? "")
            case .folder:
                let folder1 = note1.folder?.name ?? ""
                let folder2 = note2.folder?.name ?? ""
                return folder1 < folder2
            }
        }
    }
}

// MARK: - Note Card View
struct NoteCardView: View {
    let note: Note
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            listCardView
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
    
    private var listCardView: some View {
        HStack(spacing: AtlasTheme.Spacing.md) {
            // Selection indicator or Note Icon
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? AtlasTheme.Colors.primary : AtlasTheme.Colors.tertiaryText)
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: noteIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(noteColor)
                    .frame(width: 24, height: 24)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(plainTextTitle(from: note.title, content: note.content))
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(AtlasTheme.Colors.text)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if note.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AtlasTheme.Colors.warning)
                    }
                }
                
                if let content = note.content, !content.isEmpty {
                    Text(plainTextPreview(from: content))
                        .font(AtlasTheme.Typography.body)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                        .lineLimit(2)
                }
                
                HStack {
                    if let folder = note.folder {
                        folderTag(name: folder.name ?? "Folder", color: folder.color ?? "#FF6B35")
                    }
                    
                    if let tags = note.tags, tags.count > 0 {
                        ForEach(Array(tags) as? [NoteTag] ?? [], id: \.uuid) { tag in
                            tagView(name: tag.name ?? "Tag", color: tag.color ?? "#FF6B35")
                        }
                    }
                    
                    Spacer()
                    
                    Text(formatDate(note.updatedAt ?? note.createdAt ?? Date()))
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.tertiaryText)
                }
            }
        }
        .padding(AtlasTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                .fill(AtlasTheme.Colors.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
        )
    }
    
    
    private func folderTag(name: String, color: String) -> some View {
        Text(name)
            .font(AtlasTheme.Typography.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(AtlasTheme.Colors.primary)
            )
    }
    
    private func tagView(name: String, color: String) -> some View {
        Text(name)
            .font(AtlasTheme.Typography.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(AtlasTheme.Colors.secondary)
            )
    }
    
    private var noteIcon: String {
        if note.content?.contains("# ") == true {
            return "textformat.abc"
        } else if note.content?.contains("• ") == true || note.content?.contains("1. ") == true {
            return "list.bullet"
        } else {
            return "doc.text"
        }
    }
    
    private var noteColor: Color {
        if let folder = note.folder, let colorString = folder.color {
            return AtlasTheme.Colors.primary
        }
        return AtlasTheme.Colors.primary
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: Date())?.contains(date) == true {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Plain Text Helpers
    private func plainTextTitle(from title: String?, content: String?) -> String {
        // If we have a clean title, use it
        if let title = title, !title.isEmpty, !title.contains("<") && !title.contains("&") {
            return title
        }
        
        // Otherwise derive from content
        if let content = content, !content.isEmpty {
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
    
    private func plainTextPreview(from content: String) -> String {
        let plainText = stripHTML(from: content)
        return preview(fromPlainText: plainText, limit: 140)
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
    
    private func preview(fromPlainText text: String, limit: Int = 140) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = trimmed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        if collapsed.count <= limit {
            return collapsed
        } else {
            let index = collapsed.index(collapsed.startIndex, offsetBy: limit)
            return String(collapsed[..<index]) + "..."
        }
    }
}


// MARK: - Move to Folder View
struct MoveToFolderView: View {
    let selectedNotes: [Note]
    @EnvironmentObject private var notesService: NotesService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFolder: NoteFolder?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("No Folder") {
                        moveNotesToFolder(nil)
                    }
                    .foregroundColor(AtlasTheme.Colors.text)
                }
                
                Section("Folders") {
                    ForEach(notesService.folders, id: \.uuid) { folder in
                        Button(action: {
                            moveNotesToFolder(folder)
                        }) {
                            HStack {
                                Circle()
                                    .fill(AtlasTheme.Colors.primary)
                                    .frame(width: 12, height: 12)
                                
                                Text(folder.name ?? "Unnamed Folder")
                                    .foregroundColor(AtlasTheme.Colors.text)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func moveNotesToFolder(_ folder: NoteFolder?) {
        for note in selectedNotes {
            note.folder = folder
        }
        notesService.saveContext()
        AtlasTheme.Haptics.success()
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    NotesListView()
}
