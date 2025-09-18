import SwiftUI
import CoreData

/// Main Notes view with frosted glassmorphism design and dreamy atmosphere
struct NotesView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: NotesViewModel
    @State private var showingCreateNote = false
    @State private var showingFilters = false
    @State private var isMenuOpen = false
    @State private var searchText = ""
    @State private var isSearchFocused = false
    @State private var selectedFolder: NoteFolder? = nil
    @State private var showingFavorites = false
    @State private var showingFolders = false
    @State private var showingRecent = false
    @State private var showingExport = false
    @State private var showingFullTextSearch = false
    @State private var showingShare = false
    
    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = -20
    @State private var notesOpacity: Double = 0
    @State private var notesOffset: CGFloat = 30
    @State private var fabScale: CGFloat = 0.8
    @State private var fabOpacity: Double = 0
    
    // MARK: - Initialization
    init(dataManager: DataManager, encryptionService: EncryptionService) {
        self._viewModel = StateObject(wrappedValue: NotesViewModel(dataManager: dataManager, encryptionService: encryptionService))
    }
    
    // MARK: - Body
    var body: some View {
            ZStack {
            // Dreamy sky-blue gradient background
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                // Frosted Header Bar
                frostedHeaderBar
                
                // Main Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Folders View
                        if showingFolders {
                            foldersView
                                .padding(.top, 20)
                        }
                        
                        // Recent Notes View
                        if showingRecent {
                            recentNotesView
                                .padding(.top, 20)
                        }
                        
                        // Notes List
                        notesList
                            .padding(.top, (showingFolders || showingRecent) ? 0 : 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Space for FAB
                }
                .refreshable {
                    await refreshNotes()
                }
            }
            
            // Floating Action Button
            floatingActionButton
        }
        .navigationBarHidden(true)
        .onAppear {
            animateOnAppear()
            viewModel.updateRecentNotes()
            viewModel.updateFavoriteNotes()
            }
            .sheet(isPresented: $showingCreateNote) {
                CreateNoteView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFilters) {
                NotesFilterView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingExport) {
                ExportNotesView(notes: currentNotes)
            }
            .fullScreenCover(isPresented: $showingFullTextSearch) {
                FullTextSearchView()
            }
            .sheet(isPresented: $showingShare) {
                ShareNotesView(notes: currentNotes)
            }
        .fullScreenCover(item: $viewModel.selectedNote) { note in
            CreateNoteView(viewModel: viewModel, noteToEdit: note)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    
    // MARK: - Frosted Header Bar
    private var frostedHeaderBar: some View {
        VStack(spacing: 0) {
            // Main header with frosted glass effect
            HStack {
                // Hamburger menu
                Menu {
                    Button(action: {
                        AtlasTheme.Haptics.light()
                        // TODO: Navigate to settings or other options
                    }) {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    Button(action: {
                        AtlasTheme.Haptics.light()
                        // TODO: Show help or about
                    }) {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        AtlasTheme.Haptics.light()
                        showingExport = true
                    }) {
                        Label("Export Notes", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        AtlasTheme.Haptics.light()
                        showingShare = true
                    }) {
                        Label("Share Notes", systemImage: "square.and.arrow.up.on.square")
                    }
                } label: {
                    Image(systemName: "line.horizontal.3")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .blur(radius: 1)
                        )
                }
                .scaleEffect(isMenuOpen ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isMenuOpen)
                
                Spacer()
                
                // Gradient "NOTES" title
                Text("NOTES")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.6, blue: 1.0), // #3399FF
                                Color(red: 0.6, green: 0.9, blue: 1.0)  // #99E6FF
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Favorites Button
                    Button(action: {
                        showingFavorites.toggle()
                        AtlasTheme.Haptics.light()
                    }) {
                        Image(systemName: showingFavorites ? "star.fill" : "star")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(showingFavorites ? .yellow : .white.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .blur(radius: 1)
                            )
                    }
                    
                    // Folders Button
                    Button(action: {
                        showingFolders.toggle()
                        AtlasTheme.Haptics.light()
                    }) {
                        Image(systemName: showingFolders ? "folder.fill" : "folder")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(showingFolders ? AtlasTheme.Colors.accent : .white.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .blur(radius: 1)
                            )
                    }
                    
                    // Recent Notes Button
                    Button(action: {
                        showingRecent.toggle()
                        AtlasTheme.Haptics.light()
                    }) {
                        Image(systemName: showingRecent ? "clock.fill" : "clock")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(showingRecent ? AtlasTheme.Colors.accent : .white.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .blur(radius: 1)
                            )
                    }
                    
                    // Search and Filter Menu
                    Menu {
                        Button(action: {
                            AtlasTheme.Haptics.light()
                            showingFullTextSearch = true
                        }) {
                            Label("Advanced Search", systemImage: "magnifyingglass")
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isSearchFocused.toggle()
                            }
                            AtlasTheme.Haptics.light()
                        }) {
                            Label("Quick Search", systemImage: "magnifyingglass.circle")
                        }
                        
                        Button(action: {
                            AtlasTheme.Haptics.light()
                            showingFilters = true
                        }) {
                            Label("Filter & Sort", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .blur(radius: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 15)
            
            // Search bar (appears when focused)
            if isSearchFocused {
                searchBar
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .background(
            // Frosted glass background
            ZStack {
                // Blur effect background
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .background(.ultraThinMaterial, in: Rectangle())
                
                // Subtle gradient overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .opacity(headerOpacity)
        .offset(y: headerOffset)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            TextField("Search notes...", text: $searchText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    viewModel.searchNotes(query: searchText)
                }
                .onChange(of: searchText) { _, newValue in
                    viewModel.searchNotes(query: newValue)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.searchNotes(query: "")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    // MARK: - Folders View
    private var foldersView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Folders")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    // TODO: Create new folder
                    AtlasTheme.Haptics.light()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AtlasTheme.Colors.accent)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // All Notes folder
                FolderCard(
                    name: "All Notes",
                    count: viewModel.allNotes.count,
                    color: .blue,
                    isSelected: selectedFolder == nil
                ) {
                    selectedFolder = nil
                    AtlasTheme.Haptics.light()
                }
                
                // Favorites folder
                FolderCard(
                    name: "Favorites",
                    count: viewModel.favoriteNotes.count,
                    color: .yellow,
                    isSelected: showingFavorites
                ) {
                    showingFavorites.toggle()
                    AtlasTheme.Haptics.light()
                }
                
                // TODO: Add actual folders from Core Data
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Recent Notes View
    private var recentNotesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            recentNotesHeader
            recentNotesContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
        .padding(.horizontal, 20)
    }
    
    private var recentNotesHeader: some View {
        HStack {
            Text("Recent Notes")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(viewModel.recentNotes.count)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                )
        }
    }
    
    private var recentNotesContent: some View {
        Group {
            if viewModel.recentNotes.isEmpty {
                recentNotesEmptyState
            } else {
                recentNotesList
            }
        }
    }
    
    private var recentNotesEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No recent notes")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var recentNotesList: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(viewModel.recentNotes.prefix(5).enumerated()), id: \.element.objectID) { index, note in
                recentNoteRow(note: note, index: index)
            }
        }
    }
    
    private func recentNoteRow(note: Note, index: Int) -> some View {
        HStack(spacing: 12) {
            // Clock icon
            Image(systemName: "clock.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AtlasTheme.Colors.accent)
                .frame(width: 20)
            
            // Note title
            Text(note.title ?? "Untitled")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            // Last accessed time
            if let lastAccessed = note.lastAccessedAt {
                Text(lastAccessed.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onTapGesture {
            viewModel.markNoteAsAccessed(note)
            viewModel.selectNote(note)
            AtlasTheme.Haptics.light()
        }
        .staggeredAnimation(delay: Double(index) * 0.1, preset: AnimationService.smoothSlide)
        .interactiveScale()
    }
    
    // MARK: - Notes List
    private var notesList: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if currentNotes.isEmpty {
                emptyStateView
            } else {
                OptimizedNotesList(
                    notes: currentNotes,
                    onNoteTap: { note in
                                viewModel.selectNote(note)
                    }
                )
            }
        }
        .opacity(notesOpacity)
        .offset(y: notesOffset)
    }
    
    // MARK: - Computed Properties
    private var currentNotes: [Note] {
        if showingFavorites {
            return viewModel.favoriteNotes
        } else if showingRecent {
            return viewModel.recentNotes
        } else if let folder = selectedFolder {
            return viewModel.notesInFolder(folder)
        } else {
            return viewModel.filteredNotes
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text("Loading notes...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Notes Yet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Create your first note to get started")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Create Note Button
            Button(action: {
                AtlasTheme.Haptics.light()
                showingCreateNote = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Create Note")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.6, blue: 1.0),
                                    Color(red: 0.6, green: 0.9, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        fabScale = 1.2
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            fabScale = 1.0
                        }
                    }
                    
                    AtlasTheme.Haptics.medium()
                    showingCreateNote = true
                }) {
                    ZStack {
                        // Ripple effect background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.6, blue: 1.0),
                                        Color(red: 0.6, green: 0.9, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .blur(radius: 8)
                            .opacity(0.3)
                        
                        // Main button
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.6, blue: 1.0),
                                        Color(red: 0.6, green: 0.9, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                        
                        // Plus icon
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(fabScale)
                .opacity(fabOpacity)
                
                Spacer()
            }
            .padding(.bottom, 105)
        }
    }
    
    // MARK: - Animations
    private func animateOnAppear() {
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            headerOpacity = 1.0
            headerOffset = 0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            notesOpacity = 1.0
            notesOffset = 0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            fabScale = 1.0
            fabOpacity = 1.0
        }
    }
    
    private func refreshNotes() async {
        // Simulate refresh delay
        try? await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000)
        viewModel.loadNotes()
    }
}

// MARK: - Frosted Note Card
struct FrostedNoteCard: View {
    let note: Note
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var glowIntensity: Double = 0
    @StateObject private var performanceService = PerformanceService.shared
    
    // Optimized preview text
    private var optimizedPreview: String {
        performanceService.getOptimizedNotePreview(for: note)
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            
            AtlasTheme.Haptics.light()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Title and encryption indicator
                HStack {
                    Text(note.title ?? "Untitled")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if note.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Optimized content preview
                if !optimizedPreview.isEmpty && optimizedPreview != "No content" {
                    Text(optimizedPreview)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Timestamp
                HStack {
                    Spacer()
                    
                    Text(note.updatedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(20)
            .background(
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.12))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    
                    // Glow effect when pressed
                    if isPressed {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .blur(radius: 4)
                    }
                }
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: isPressed ? 16 : 8,
                x: 0,
                y: isPressed ? 8 : 4
            )
            .scaleEffect(isPressed ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .interactiveGlow()
    }
}

// MARK: - Folder Card
struct FolderCard: View {
    let name: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            
            onTap()
        }) {
            VStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        
        NotesView(dataManager: dataManager, encryptionService: encryptionService)
    }
}

// MARK: - Optimized Notes List

struct OptimizedNotesList: View {
    let notes: [Note]
    let onNoteTap: (Note) -> Void
    
    @StateObject private var performanceService = PerformanceService.shared
    @State private var visibleRange: Range<Int> = 0..<50
    @State private var scrollOffset: CGFloat = 0
    
    private let batchSize = 25
    private let maxVisibleNotes = 50
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(visibleNotes.enumerated()), id: \.element.objectID) { index, note in
                FrostedNoteCard(note: note) {
                    onNoteTap(note)
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .onAppear {
                    loadMoreIfNeeded(at: index)
                }
                .performanceOptimized(for: note.uuid?.uuidString ?? "")
                .staggeredAnimation(delay: Double(index) * 0.05, preset: AnimationService.bouncyScale)
                .interactiveScale()
            }
            
            // Loading indicator for pagination
            if hasMoreNotes {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                    .padding(.vertical, 8)
            }
        }
        .onAppear {
            updateVisibleRange()
        }
    }
    
    private var visibleNotes: [Note] {
        let startIndex = max(0, visibleRange.lowerBound)
        let endIndex = min(notes.count, visibleRange.upperBound)
        return Array(notes[startIndex..<endIndex])
    }
    
    private var hasMoreNotes: Bool {
        visibleRange.upperBound < notes.count
    }
    
    private func loadMoreIfNeeded(at index: Int) {
        let currentEndIndex = visibleRange.upperBound
        let threshold = currentEndIndex - batchSize
        
        if index >= threshold && hasMoreNotes {
            loadMoreNotes()
        }
    }
    
    private func loadMoreNotes() {
        let newEndIndex = min(notes.count, visibleRange.upperBound + batchSize)
        visibleRange = visibleRange.lowerBound..<newEndIndex
    }
    
    private func updateVisibleRange() {
        let endIndex = min(maxVisibleNotes, notes.count)
        visibleRange = 0..<endIndex
    }
}