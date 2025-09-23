import SwiftUI
import CoreData

/// Main Mind Mapping View - converted from SwiftData to CoreData
struct MindMappingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Node.createdAt, ascending: true)],
        predicate: NSPredicate(format: "parent == nil"),
        animation: .default)
    private var rootNodes: FetchedResults<Node>
    
    @State private var navigationPath = NavigationPath()
    @State private var showingMenu = false
    
    let dataManager: DataManager
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Group {
                    if let root = rootNodes.first {
                        FocusView(node: root, navigationPath: $navigationPath, dataManager: dataManager)
                    } else {
                        VStack(spacing: 16) {
                            Text("Mind Map")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Create your first root idea.")
                                .foregroundStyle(.white.opacity(0.7))
                            
                            Button {
                                createRootNode()
                            } label: {
                                Label("Create Root", systemImage: "plus.circle.fill")
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
        }
        .background(AtlasTheme.Colors.background.ignoresSafeArea())
    }
    
    private func createRootNode() {
        let root = Node(context: viewContext)
        root.uuid = UUID()
        root.title = "My Ideas"
        root.createdAt = Date()
        root.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save root node: \(error)")
        }
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
                    menuItem(icon: "plus.circle.fill", title: "Add Node", action: { 
                        showingMenu = false
                        // Add node functionality
                    })
                    
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
}

// MARK: - Preview
#Preview {
    MindMappingView(dataManager: DataManager.shared)
        .environment(\.managedObjectContext, DataManager.shared.coreDataStack.viewContext)
}
