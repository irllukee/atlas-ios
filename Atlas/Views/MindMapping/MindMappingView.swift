import SwiftUI
import CoreData

/// Main Mind Mapping View - converted from SwiftData to CoreData
struct MindMappingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MindMap.createdAt, ascending: false)],
        animation: .default)
    private var mindMaps: FetchedResults<MindMap>
    
    @State private var navigationPath = NavigationPath()
    @State private var showingMenu = false
    @State private var selectedMindMap: MindMap?
    @State private var showingMindMapSelector = false
    @State private var showingCreateDialog = false
    @State private var newMindMapName = ""
    @State private var showingDebugger = false
    
    // Debugger
    @StateObject private var debugger = MindMappingDebugger.shared
    
    let dataManager: DataManager
    private var mindMapRepository: MindMapRepository
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        self.mindMapRepository = MindMapRepository(context: dataManager.coreDataStack.viewContext)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Space background
                SpaceBackgroundView()
                
                Group {
                    if let selectedMindMap = selectedMindMap,
                       let rootNode = selectedMindMap.rootNode {
                        FocusView(node: rootNode, navigationPath: $navigationPath, dataManager: dataManager)
                    } else {
                        VStack(spacing: 16) {
                            Text("Mind Map")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Select or create a mind map to get started.")
                                .foregroundStyle(.white.opacity(0.7))
                            
                            Button {
                                showingCreateDialog = true
                            } label: {
                                Label("Create Mind Map", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
                
                // Hamburger Menu
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showingMenu.toggle() }) {
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
                
                // Menu Overlay
                if showingMenu {
                    menuOverlay
                }
            }
            .navigationDestination(for: Node.self) { node in
                FocusView(node: node, navigationPath: $navigationPath, dataManager: dataManager)
            }
            .onAppear {
                loadLastViewedMindMap()
            }
            .sheet(isPresented: $showingCreateDialog) {
                createMindMapSheet
            }
            .sheet(isPresented: $showingMindMapSelector) {
                mindMapSelectorSheet
            }
            .sheet(isPresented: $showingDebugger) {
                debuggerSheet
            }
        }
        .background(AtlasTheme.Colors.background.ignoresSafeArea())
    }
    
    // MARK: - Mind Map Management
    
    private func loadLastViewedMindMap() {
        // Load the last viewed mind map from UserDefaults
        if let lastViewedUUIDString = UserDefaults.standard.string(forKey: "lastViewedMindMapUUID"),
           let lastViewedUUID = UUID(uuidString: lastViewedUUIDString),
           let mindMap = mindMapRepository.fetchMindMap(with: lastViewedUUID) {
            selectedMindMap = mindMap
        } else if let firstMindMap = mindMaps.first {
            // If no last viewed mind map, select the first one
            selectedMindMap = firstMindMap
        }
    }
    
    private func saveLastViewedMindMap() {
        if let selectedMindMap = selectedMindMap {
            UserDefaults.standard.set(selectedMindMap.uuid?.uuidString, forKey: "lastViewedMindMapUUID")
        }
    }
    
    private func createMindMap() {
        let name = newMindMapName.isEmpty ? mindMapRepository.generateUniqueName() : newMindMapName
        
        if let newMindMap = mindMapRepository.createMindMap(name: name) {
            selectedMindMap = newMindMap
            saveLastViewedMindMap()
            showingCreateDialog = false
            newMindMapName = ""
        }
    }
    
    private func deleteMindMap(_ mindMap: MindMap) {
        if mindMapRepository.deleteMindMap(mindMap) {
            if selectedMindMap?.uuid == mindMap.uuid {
                selectedMindMap = mindMaps.first
                saveLastViewedMindMap()
            }
        }
    }
    
    private func selectMindMap(_ mindMap: MindMap) {
        selectedMindMap = mindMap
        saveLastViewedMindMap()
        showingMindMapSelector = false
    }
    
    // MARK: - Menu Overlay
    private var menuOverlay: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showingMenu = false
                }
            
            // Menu panel
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Mind Map Features")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showingMenu = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Current Mind Map Display
                    if let selectedMindMap = selectedMindMap {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Mind Map")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(selectedMindMap.name ?? "Untitled")
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AtlasTheme.Colors.primary.opacity(0.2))
                        )
                    }
                    
                    menuItem(icon: "list.bullet", title: "Switch Mind Map", action: { 
                        showingMenu = false
                        showingMindMapSelector = true
                    })
                    
                    menuItem(icon: "plus.circle.fill", title: "Create Mind Map", action: { 
                        showingMenu = false
                        showingCreateDialog = true
                    })
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    menuItem(icon: "search", title: "Search Nodes", action: { 
                        showingMenu = false
                        // Search functionality
                    })
                    
                    menuItem(icon: "trash", title: "Delete Node", action: { 
                        showingMenu = false
                        // Delete functionality
                    })
                    
                    menuItem(icon: "pencil", title: "Edit Node", action: { 
                        showingMenu = false
                        // Edit functionality
                    })
                    
                    menuItem(icon: "note.text", title: "Add Note", action: { 
                        showingMenu = false
                        // Note functionality
                    })
                    
                    menuItem(icon: "camera", title: "Take Photo", action: { 
                        showingMenu = false
                        // Camera functionality
                    })
                    
                    menuItem(icon: "folder", title: "Export Map", action: { 
                        showingMenu = false
                        // Export functionality
                    })
                    
                    menuItem(icon: "gear", title: "Settings", action: { 
                        showingMenu = false
                        // Settings functionality
                    })
                    
                    Divider()
                    
                    menuItem(icon: debugger.isEnabled ? "stop.circle.fill" : "play.circle.fill", 
                            title: debugger.isEnabled ? "Stop Debugger" : "Start Debugger", 
                            action: { 
                        showingMenu = false
                        if debugger.isEnabled {
                            debugger.disable()
                        } else {
                            debugger.enable()
                        }
                    })
                    
                    if debugger.isEnabled {
                        menuItem(icon: "doc.text", title: "View Debug Log", action: { 
                            showingMenu = false
                            showingDebugger = true
                        })
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AtlasTheme.Colors.background.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AtlasTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding()
            .frame(maxWidth: 300)
            .position(x: UIScreen.main.bounds.width - 150, y: 200)
        }
    }
    
    private func menuItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AtlasTheme.Colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AtlasTheme.Colors.primary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Sheet Views
    
    private var createMindMapSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mind Map Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter mind map name", text: $newMindMapName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Create Mind Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCreateDialog = false
                        newMindMapName = ""
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createMindMap()
                    }
                    .disabled(newMindMapName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private var mindMapSelectorSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                if mindMaps.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Mind Maps")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create your first mind map to get started.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            showingMindMapSelector = false
                            showingCreateDialog = true
                        } label: {
                            Label("Create Mind Map", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(mindMaps, id: \.uuid) { mindMap in
                            mindMapRow(for: mindMap)
                        }
                        .onDelete(perform: deleteMindMaps)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Select Mind Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingMindMapSelector = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingMindMapSelector = false
                        showingCreateDialog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func mindMapRow(for mindMap: MindMap) -> some View {
        Button {
            selectMindMap(mindMap)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mindMap.name ?? "Untitled")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("Created \(mindMap.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if selectedMindMap?.uuid == mindMap.uuid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AtlasTheme.Colors.primary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func deleteMindMaps(offsets: IndexSet) {
        for index in offsets {
            deleteMindMap(mindMaps[index])
        }
    }
    
    // MARK: - Debugger Sheet
    private var debuggerSheet: some View {
        NavigationView {
            VStack {
                // Performance Metrics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Metrics")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    HStack {
                        Text("Memory:")
                        Spacer()
                        Text("\(String(format: "%.1f", debugger.performanceMetrics.memoryUsage))MB")
                    }
                    
                    HStack {
                        Text("Node Count:")
                        Spacer()
                        Text("\(debugger.performanceMetrics.nodeCount)")
                    }
                    
                    HStack {
                        Text("Gesture Count:")
                        Spacer()
                        Text("\(debugger.performanceMetrics.gestureCount)")
                    }
                    
                    HStack {
                        Text("Animation Count:")
                        Spacer()
                        Text("\(debugger.performanceMetrics.animationCount)")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Debug Log
                VStack(alignment: .leading) {
                    Text("Debug Log")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(debugger.debugLog.indices, id: \.self) { index in
                                let entry = debugger.debugLog[index]
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text("[\(entry.timestamp.formatted(date: .omitted, time: .standard))]")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("[\(entry.category.rawValue.uppercased())]")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    Text(entry.message)
                                        .font(.caption)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                
                Spacer()
                
                // Controls
                HStack {
                    Button("Capture Performance") {
                        debugger.capturePerformanceSnapshot()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Export Log") {
                        let logText = debugger.exportDebugLog()
                        // You could implement sharing here
                        print(logText)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Mind Mapping Debugger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingDebugger = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MindMappingView(dataManager: DataManager.shared)
        .environment(\.managedObjectContext, DataManager.shared.coreDataStack.viewContext)
}
