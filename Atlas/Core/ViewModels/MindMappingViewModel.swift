import SwiftUI
import CoreData
import Combine

/// View model for mind mapping operations
/// Provides a clean interface between the UI and the state manager
@MainActor
class MindMappingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var mindMaps: [MindMap] = []
    // Removed search results for simplified mind mapping
    @Published var isSearching = false
    
    // MARK: - Dependencies
    
    private let stateManager: MindMapStateManager
    let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        self.stateManager = MindMapStateManager(dataManager: dataManager)
        
        setupBindings()
        loadMindMaps()
    }
    
    // MARK: - Public Interface
    
    /// Get the state manager
    var state: MindMapStateManager {
        return stateManager
    }
    
    // Removed search service for simplified mind mapping
    
    /// Load all mind maps
    func loadMindMaps() {
        isLoading = true
        
        let request: NSFetchRequest<MindMap> = MindMap.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MindMap.createdAt, ascending: false)]
        
        do {
            mindMaps = try dataManager.coreDataStack.viewContext.fetch(request)
        } catch {
            stateManager.showError("Failed to load mind maps: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Refresh mind maps
    func refreshMindMaps() {
        loadMindMaps()
    }
    
    // Removed search functionality for simplified mind mapping
    
    /// Refresh all data when Core Data changes
    func refreshData() {
        loadMindMaps()
        // Refresh the current mind map if it exists
        if let currentMindMap = stateManager.currentMindMap {
            stateManager.selectMindMap(currentMindMap)
        }
    }
    
    /// Navigate to a specific node by ID
    func navigateToNode(nodeId: UUID) {
        let request: NSFetchRequest<Node> = Node.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", nodeId as CVarArg)
        request.fetchLimit = 1
        
        do {
            if let node = try dataManager.coreDataStack.viewContext.fetch(request).first {
                // Set the mind map if needed
                if let mindMap = node.mindMap, stateManager.currentMindMap != mindMap {
                    stateManager.selectMindMap(mindMap)
                }
                
                // Focus on the specific node
                stateManager.focusOnNode(node)
                
                // Dismiss search sheet
                stateManager.showingSearch = false
            } else {
                stateManager.showError("Node not found")
            }
        } catch {
            stateManager.showError("Failed to navigate to node: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Listen for state changes
        stateManager.$currentMindMap
            .sink { [weak self] _ in
                // Refresh mind maps when current mind map changes
                self?.loadMindMaps()
            }
            .store(in: &cancellables)
        
        stateManager.$errorMessage
            .sink { error in
                if error != nil {
                    // Handle error state if needed
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Convenience Methods

extension MindMappingViewModel {
    
    /// Check if we can create a new mind map
    var canCreateMindMap: Bool {
        return !stateManager.newMindMapName.isEmpty && 
               stateManager.mindMapValidationError == nil
    }
    
    /// Get the current mind map name
    var currentMindMapName: String {
        return stateManager.currentMindMap?.name ?? "Untitled"
    }
    
    /// Get the current focused node title
    var currentFocusedNodeTitle: String {
        return stateManager.focusedNode?.title ?? "Untitled"
    }
    
    // Removed search result properties for simplified mind mapping
}
