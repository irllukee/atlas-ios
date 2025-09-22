import SwiftUI

// MARK: - Notes List View
struct NotesListView: View {
    @StateObject private var notesService = NotesService.shared
    @State private var showingNewNote = false
    @State private var showingNoteDetail = false
    @State private var showingFolderManagement = false
    @State private var showingTagManagement = false
    @State private var selectedNote: Note?
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .list
    @State private var sortOption: SortOption = .updatedAt
    @State private var showingTestAlert = false
    
    enum ViewMode: CaseIterable {
        case list, grid
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .grid: return "square.grid.2x2"
            }
        }
    }
    
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
        .sheet(isPresented: $showingNewNote) {
            NotesDetailView(note: nil)
                .onAppear {
                    print("🔧 DEBUG: NotesDetailView sheet appeared")
                }
        }
        .sheet(isPresented: $showingFolderManagement) {
            FolderManagementView()
        }
        .sheet(isPresented: $showingTagManagement) {
            TagManagementView()
        }
        .sheet(isPresented: $showingNoteDetail) {
            if let note = selectedNote {
                NotesDetailView(note: note)
            }
        }
        .alert("Test Alert", isPresented: $showingTestAlert) {
            Button("OK") { }
        } message: {
            Text("Plus button is working!")
        }
        .onAppear {
            notesService.loadData()
        }
        .onChange(of: searchText) { _, newValue in
            notesService.searchText = newValue
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(AtlasTheme.Typography.largeTitle)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("\(notesService.notes.count) notes")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.tertiaryText)
            }
            
            Spacer()
            
            HStack(spacing: AtlasTheme.Spacing.sm) {
                // View Mode Toggle
                Menu {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Button(action: {
                            viewMode = mode
                            AtlasTheme.Haptics.light()
                        }) {
                            HStack {
                                Image(systemName: mode.icon)
                                Text(mode == .list ? "List View" : "Grid View")
                                if viewMode == mode {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: viewMode.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AtlasTheme.Colors.text)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(AtlasTheme.Colors.glassBackground)
                        )
                }
                
                // New Note Button
                Button(action: {
                    print("🔧 DEBUG: Plus button in header tapped")
                    showingTestAlert = true
                    print("🔧 DEBUG: showingTestAlert set to: \(showingTestAlert)")
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
        .padding(.horizontal, AtlasTheme.Spacing.md)
        .padding(.top, AtlasTheme.Spacing.sm)
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
                    NoteCardView(note: note, viewMode: viewMode) {
                        selectedNote = note
                        showingNoteDetail = true
                        AtlasTheme.Haptics.light()
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        // Hold to delete
                        notesService.deleteNote(note)
                        AtlasTheme.Haptics.success()
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
    let viewMode: NotesListView.ViewMode
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            if viewMode == .list {
                listCardView
            } else {
                gridCardView
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
    
    private var listCardView: some View {
        HStack(spacing: AtlasTheme.Spacing.md) {
            // Note Icon
            Image(systemName: noteIcon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(noteColor)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(note.title ?? "Untitled Note")
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
                    Text(content)
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
    
    private var gridCardView: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            // Header
            HStack {
                Image(systemName: noteIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(noteColor)
                
                Spacer()
                
                if note.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AtlasTheme.Colors.warning)
                }
            }
            
            // Title
            Text(note.title ?? "Untitled Note")
                .font(AtlasTheme.Typography.headline)
                .foregroundColor(AtlasTheme.Colors.text)
                .lineLimit(2)
            
            // Content Preview
            if let content = note.content, !content.isEmpty {
                Text(content)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .lineLimit(3)
            }
            
            Spacer()
            
            // Footer
            VStack(alignment: .leading, spacing: 4) {
                if let folder = note.folder {
                    folderTag(name: folder.name ?? "Folder", color: folder.color ?? "#FF6B35")
                }
                
                Text(formatDate(note.updatedAt ?? note.createdAt ?? Date()))
                    .font(AtlasTheme.Typography.caption2)
                    .foregroundColor(AtlasTheme.Colors.tertiaryText)
            }
        }
        .padding(AtlasTheme.Spacing.md)
        .frame(height: 140)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .fill(Color(hex: color) ?? AtlasTheme.Colors.primary)
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
                    .fill(Color(hex: color) ?? AtlasTheme.Colors.secondary)
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
            return Color(hex: colorString) ?? AtlasTheme.Colors.primary
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
}


// MARK: - Preview
#Preview {
    NotesListView()
}
