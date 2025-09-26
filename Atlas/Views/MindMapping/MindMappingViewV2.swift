import SwiftUI
import CoreData

/// Main Mind Mapping View with proper state management
/// Uses centralized state management patterns for better maintainability
struct MindMappingViewV2: View {
    
    // MARK: - State Management
    
    @StateObject private var viewModel: MindMappingViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Initialization
    
    init(dataManager: DataManager) {
        self._viewModel = StateObject(wrappedValue: MindMappingViewModel(dataManager: dataManager))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: Binding(
            get: { viewModel.state.navigationPath },
            set: { viewModel.state.navigationPath = $0 }
        )) {
            ZStack {
                // Space background
                SpaceBackgroundView()
                
                Group {
                    if let _ = viewModel.state.currentMindMap,
                       let rootNode = viewModel.state.currentMindMap?.rootNode {
                        // Show the root node directly - this is the initial view
                        FocusView(
                            node: rootNode, 
                            navigationPath: Binding(
                                get: { viewModel.state.navigationPath },
                                set: { viewModel.state.navigationPath = $0 }
                            ), 
                            dataManager: viewModel.dataManager,
                            stateManager: viewModel.state
                        )
                    } else {
                        emptyStateView
                    }
                }
                
                // Hamburger Menu
                hamburgerMenu
                
                // Menu Overlay
                if viewModel.state.showingMenu {
                    menuOverlay
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                // Refresh the view when Core Data changes
                viewModel.refreshData()
            }
            .navigationDestination(for: Node.self) { node in
                FocusView(
                    node: node, 
                    navigationPath: Binding(
                        get: { viewModel.state.navigationPath },
                        set: { viewModel.state.navigationPath = $0 }
                    ), 
                    dataManager: viewModel.dataManager,
                    stateManager: viewModel.state
                )
            }
            .onAppear {
                loadLastViewedMindMap()
            }
            .sheet(isPresented: Binding(
                get: { viewModel.state.showingMindMapSelector },
                set: { viewModel.state.showingMindMapSelector = $0 }
            )) {
                mindMapSelectorSheet
            }
            .sheet(isPresented: Binding(
                get: { viewModel.state.showingCreateDialog },
                set: { viewModel.state.showingCreateDialog = $0 }
            )) {
                createMindMapSheet
            }
            // Removed search sheet for simplified mind mapping
            .sheet(isPresented: Binding(
                get: { viewModel.state.showingNoteEditor },
                set: { viewModel.state.showingNoteEditor = $0 }
            )) {
                noteEditorSheet
            }
            .sheet(isPresented: Binding(
                get: { viewModel.state.showingRenameDialog },
                set: { viewModel.state.showingRenameDialog = $0 }
            )) {
                renameDialogSheet
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.state.showingErrorAlert },
                set: { viewModel.state.showingErrorAlert = $0 }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.state.clearError()
                }
            } message: {
                Text(viewModel.state.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - View Components
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("Mind Map")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Select or create a mind map to get started.")
                .foregroundStyle(.white.opacity(0.7))
            
            Button {
                viewModel.state.showCreateDialog()
            } label: {
                Label("Create Mind Map", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var hamburgerMenu: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { 
                    print("📋 Menu button tapped")
                    print("📋 Current menu state: \(viewModel.state.showingMenu)")
                    viewModel.state.showingMenu.toggle()
                    print("📋 New menu state: \(viewModel.state.showingMenu)")
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(AtlasTheme.Colors.primary.opacity(0.2))
                                .overlay(
                                    Circle()
                                        .stroke(AtlasTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .padding(.trailing)
                .padding(.top, 8)
            }
            Spacer()
        }
    }
    
    private var menuOverlay: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    Button("Select Mind Map") {
                        viewModel.state.showMindMapSelector()
                        viewModel.state.showingMenu = false
                    }
                    .foregroundColor(.white)
                    
                    // Removed search functionality for simplified mind mapping
                    
                    if viewModel.state.hasCurrentMindMap {
                        Button("Back to Root") {
                            viewModel.state.navigateToRoot()
                            viewModel.state.showingMenu = false
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AtlasTheme.Colors.primary.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AtlasTheme.Colors.primary, lineWidth: 1)
                        )
                )
                .padding(.trailing)
                .padding(.top, 8)
            }
            Spacer()
        }
    }
    
    // MARK: - Sheet Views
    
    private var mindMapSelectorSheet: some View {
        NavigationView {
            List {
                ForEach(viewModel.mindMaps, id: \.uuid) { mindMap in
                    Button(action: {
                        viewModel.state.selectMindMap(mindMap)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mindMap.name ?? "Untitled")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Created: \(mindMap.createdAt?.formatted() ?? "Unknown")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onDelete(perform: deleteMindMaps)
            }
            .navigationTitle("Select Mind Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.state.showingMindMapSelector = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.state.showCreateDialog()
                    }
                }
            }
        }
    }
    
    private var createMindMapSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Mind Map Name", text: Binding(
                    get: { viewModel.state.newMindMapName },
                    set: { viewModel.state.newMindMapName = $0 }
                ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: viewModel.state.newMindMapName) { _, _ in
                        // Clear validation error when user types
                        if viewModel.state.mindMapValidationError != nil {
                            viewModel.state.mindMapValidationError = nil
                        }
                    }
                
                if let error = viewModel.state.mindMapValidationError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Create Mind Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.state.showingCreateDialog = false
                        viewModel.state.newMindMapName = ""
                        viewModel.state.mindMapValidationError = nil
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.state.createMindMap(name: viewModel.state.newMindMapName)
                    }
                    .disabled(!viewModel.canCreateMindMap)
                }
            }
        }
    }
    
    // Removed search sheet for simplified mind mapping
    
    private var noteEditorSheet: some View {
        NavigationView {
            if let editingNode = viewModel.state.editingNode {
                NoteEditor(node: editingNode)
                .navigationTitle("Edit Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            viewModel.state.showingNoteEditor = false
                            viewModel.state.editingNode = nil
                        }
                    }
                }
            }
        }
    }
    
    private var renameDialogSheet: some View {
        NavigationView {
            if let renamingNode = viewModel.state.renamingNode {
                VStack(spacing: 20) {
                    TextField("Node Title", text: .constant(renamingNode.title ?? ""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Rename Node")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            viewModel.state.showingRenameDialog = false
                            viewModel.state.renamingNode = nil
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            // Implementation would go here
                            viewModel.state.showingRenameDialog = false
                            viewModel.state.renamingNode = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadLastViewedMindMap() {
        // Load the first available mind map if none is currently selected
        if viewModel.state.currentMindMap == nil && !viewModel.mindMaps.isEmpty {
            let firstMindMap = viewModel.mindMaps.first!
            viewModel.state.selectMindMap(firstMindMap)
        }
    }
    
    private func deleteMindMaps(offsets: IndexSet) {
        for index in offsets {
            let mindMap = viewModel.mindMaps[index]
            viewModel.state.deleteMindMap(mindMap)
        }
    }
}

// MARK: - Preview

#Preview {
    MindMappingViewV2(dataManager: DataManager.shared)
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
