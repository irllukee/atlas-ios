import SwiftUI
import CoreData

struct FocusView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var node: Node
    @Binding var navigationPath: NavigationPath
    let dataManager: DataManager
    
    // MARK: - State Management
    @ObservedObject var stateManager: MindMapStateManager
    
    // MARK: - Computed Properties
    /// Use the state manager's focused node (which updates on navigation)
    private var currentNode: Node {
        let focusedNode = stateManager.focusedNode ?? node
        print("🔍 FocusView currentNode: \(focusedNode.title ?? "unknown") (from stateManager: \(stateManager.focusedNode?.title ?? "nil"))")
        return focusedNode
    }
    
    // MARK: - Repositories
    private let nodeRepository: NodeRepository
    
    // MARK: - Initialization
    init(node: Node, navigationPath: Binding<NavigationPath>, dataManager: DataManager, stateManager: MindMapStateManager) {
        self.node = node
        self._navigationPath = navigationPath
        self.dataManager = dataManager
        self.stateManager = stateManager
        self.nodeRepository = NodeRepository(context: dataManager.coreDataStack.viewContext)
    }

    @State private var appeared = false
    @State private var haptics = UIImpactFeedbackGenerator(style: .soft)
    @State private var cameraOffsetForParallax: CGSize = .zero
    @FocusState private var isTextFieldFocused: Bool
    
    // Data validation constants
    private let maxNodeNameLength = 50
    private let minNodeNameLength = 1
    
    // MARK: - Computed Properties for Safe Core Data Access
    
    private var editNode: Node? {
        return stateManager.editingNode
    }
    
    private var renameNode: Node? {
        return stateManager.renamingNode
    }
    
    private var newChildParentNode: Node? {
        return currentNode // Use the current focused node as parent
    }
    
    private func fetchNode(with id: UUID) -> Node? {
        let request: NSFetchRequest<Node> = Node.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            stateManager.showError("Failed to load node: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    private func handleMemoryWarning() {
        print("🧠 Memory warning in FocusView - cleaning up resources")
        
        // Clear any cached data or temporary state
        // Note: Core Data objects and essential state are kept
        
        // The haptics generator will be automatically released when the view is deallocated
        // No explicit cleanup needed for @State variables
    }
    
    private func validateNodeName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return "Node name cannot be empty"
        }
        
        if trimmed.count < minNodeNameLength {
            return "Node name must be at least \(minNodeNameLength) character"
        }
        
        if name.count > maxNodeNameLength {
            return "Node name must be \(maxNodeNameLength) characters or less"
        }
        
        return nil
    }

    var body: some View {
        ZStack {
            // Space background
            SpaceBackgroundView()
            
            VStack(spacing: 0) {
                header

                // Simplified mind map view - center node with children around it
                SimpleMindMapView(
                    centerNode: currentNode,
                    childNodes: Array(currentNode.children as? Set<Node> ?? []),
                    onNodeTap: { selectedNode in 
                        print("🔍 onNodeTap callback called with: \(selectedNode.title ?? "unknown")")
                        haptics.impactOccurred()
                        print("🔍 Focusing on node: \(selectedNode.title ?? "unknown")")
                        // Update the state manager's focused node
                        stateManager.focusedNode = selectedNode
                        print("🔍 Updated stateManager.focusedNode to: \(stateManager.focusedNode?.title ?? "nil")")
                        // Navigate to the selected node using the navigation path
                        navigationPath.append(selectedNode)
                        print("🔍 Navigation path count after append: \(navigationPath.count)")
                    }
                )
                .padding(.bottom, 12)

                Spacer()
            }
            .onAppear { 
                appeared = true
                haptics.prepare() 
            }
            .onDisappear {
                // Cleanup haptics generator to prevent memory leak
                // haptics will be automatically released when view is deallocated
            }
            
            
            // Floating + Button
            VStack {
                Spacer()
                floatingAddButton
            }
        }
        .navigationBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            handleMemoryWarning()
        }
    }

    private var header: some View {
        HStack {
            if currentNode.parent != nil {
                Button {
                    // Use navigation path to go back
                    if !navigationPath.isEmpty {
                        navigationPath.removeLast()
                        // Update the state manager's focused node to the parent
                        stateManager.focusedNode = currentNode.parent
                        print("🔙 Back button: Updated stateManager.focusedNode to: \(stateManager.focusedNode?.title ?? "nil")")
                    } else {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                }
                .accessibilityLabel("Back to \(currentNode.parent?.title ?? "parent")")
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(currentNode.title ?? "Untitled")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Undo/Redo Toolbar
                HStack {
                    Spacer()
                    SyncStatusIndicator()
                }
            }
            
            Spacer()
            
            // Empty space where the 3 dots menu was
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        Button(action: { 
            let newNode = Node(context: viewContext)
            newNode.uuid = UUID()
            newNode.title = "New Idea"
            newNode.createdAt = Date()
            newNode.updatedAt = Date()
            newNode.parent = currentNode
            
            do {
                try viewContext.save()
            } catch {
                stateManager.showError("Failed to add node: \(error.localizedDescription)")
            }
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(AtlasTheme.Colors.primary)
                .padding(8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40) // Safe area padding
        .padding(.top, 8)
    }
    
    
    private func createNode() {
        guard let parent = newChildParentNode else { return }
        
        let trimmedName = stateManager.newMindMapName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let _ = nodeRepository.createNode(
            title: trimmedName,
            parent: parent,
            mindMap: parent.mindMap
        ) {
            haptics.impactOccurred()
            // Clean up and dismiss keyboard
            stateManager.showingCreateDialog = false
            isTextFieldFocused = false
        } else {
            stateManager.showError("Failed to create node")
        }
    }
    
    
    
    private func reorganizeNodes() {
        // Trigger a layout recalculation with haptic feedback
        // Use a safer approach that doesn't modify node properties
        haptics.impactOccurred(intensity: 0.7)
        
        // Force a layout update with improved animation timing
        // Use a more responsive spring animation that handles interruptions better
        withAnimation(.easeInOut(duration: 0.3)) {
            // The RadialMindMap will automatically recalculate layout
            // when it detects changes in the children array or layout cache
            // This animation is more responsive and handles interruptions gracefully
        }
    }
}
