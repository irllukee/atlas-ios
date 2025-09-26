import SwiftUI
import CoreData
import Combine

/// Centralized state management for mind mapping operations
/// Implements proper state management patterns with clear separation of concerns
@MainActor
class MindMapStateManager: ObservableObject {
    
    // MARK: - Published State
    
    /// Current mind map being viewed
    @Published var currentMindMap: MindMap?
    
    /// Current focused node
    @Published var focusedNode: Node?
    
    /// Navigation state
    @Published var navigationPath = NavigationPath()
    
    /// UI state
    @Published var showingMenu = false
    @Published var showingMindMapSelector = false
    @Published var showingCreateDialog = false
    @Published var showingSearch = false
    @Published var showingNoteEditor = false
    @Published var showingRenameDialog = false
    
    /// Form state
    @Published var newMindMapName = ""
    @Published var editingNode: Node?
    @Published var renamingNode: Node?
    
    /// Error state
    @Published var errorMessage: String?
    @Published var showingErrorAlert = false
    
    /// Validation state
    @Published var mindMapValidationError: String?
    
    // MARK: - Dependencies
    
    private let dataManager: DataManager
    private let mindMapRepository: MindMapRepository
    private let nodeRepository: NodeRepository
    // Removed search service for simplified mind mapping
    
    // MARK: - Constants
    
    private let maxMindMapNameLength = 100
    private let minMindMapNameLength = 1
    
    // MARK: - Initialization
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        self.mindMapRepository = MindMapRepository(context: dataManager.coreDataStack.viewContext)
        self.nodeRepository = NodeRepository(context: dataManager.coreDataStack.viewContext)
        // Removed search service initialization
    }
    
    // MARK: - Mind Map Operations
    
    /// Create a new mind map
    func createMindMap(name: String) {
        // Validate input
        guard validateMindMapName(name) else { return }
        
        let mindMap = mindMapRepository.createMindMap(name: name)
        currentMindMap = mindMap
        focusedNode = mindMap?.rootNode
        newMindMapName = ""
        showingCreateDialog = false
    }
    
    /// Select a mind map
    func selectMindMap(_ mindMap: MindMap) {
        currentMindMap = mindMap
        focusedNode = mindMap.rootNode
        showingMindMapSelector = false
        
        // Removed search index building for simplified mind mapping
    }
    
    /// Delete a mind map
    func deleteMindMap(_ mindMap: MindMap) {
        _ = mindMapRepository.deleteMindMap(mindMap)
        if currentMindMap?.uuid == mindMap.uuid {
            currentMindMap = nil
            focusedNode = nil
        }
    }
    
    // MARK: - Node Operations
    
    /// Focus on a specific node
    func focusOnNode(_ node: Node) {
        focusedNode = node
        navigationPath.append(node)
    }
    
    /// Add a child node
    func addNode(to parent: Node) {
        _ = nodeRepository.createNode(
            title: "New Node",
            parent: parent,
            mindMap: currentMindMap
        )
        // Refresh the focused node to show the new child
        refreshFocusedNode()
    }
    
    /// Rename a node
    func renameNode(_ node: Node, to newTitle: String) {
        _ = nodeRepository.updateNode(node, title: newTitle)
        renamingNode = nil
        showingRenameDialog = false
    }
    
    /// Delete a node
    func deleteNode(_ node: Node) {
        _ = nodeRepository.deleteNode(node)
        
        // If we deleted the focused node, go back to parent or root
        if focusedNode?.uuid == node.uuid {
            if let parent = node.parent {
                focusedNode = parent
            } else if let rootNode = currentMindMap?.rootNode {
                focusedNode = rootNode
            } else {
                focusedNode = nil
            }
        }
    }
    
    /// Edit node note
    func editNodeNote(_ node: Node) {
        editingNode = node
        showingNoteEditor = true
    }
    
    /// Update node note
    func updateNodeNote(_ node: Node, note: String) {
        _ = nodeRepository.updateNode(node, note: note)
        editingNode = nil
        showingNoteEditor = false
    }
    
    // MARK: - Navigation Operations
    
    /// Navigate back
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
            // Update focused node to the parent of the current focused node
            if let currentFocused = focusedNode, let parent = currentFocused.parent {
                focusedNode = parent
            } else {
                // If no parent, go to root
                focusedNode = currentMindMap?.rootNode
            }
        }
    }
    
    /// Navigate to root
    func navigateToRoot() {
        navigationPath = NavigationPath()
        focusedNode = currentMindMap?.rootNode
    }
    
    // MARK: - UI Operations
    
    /// Show mind map selector
    func showMindMapSelector() {
        showingMindMapSelector = true
    }
    
    /// Show create dialog
    func showCreateDialog() {
        showingCreateDialog = true
        newMindMapName = ""
    }
    
    /// Show search
    func showSearch() {
        showingSearch = true
    }
    
    /// Show rename dialog for a node
    func showRenameDialog(for node: Node) {
        renamingNode = node
        showingRenameDialog = true
    }
    
    /// Dismiss all dialogs
    func dismissAllDialogs() {
        showingMenu = false
        showingMindMapSelector = false
        showingCreateDialog = false
        showingSearch = false
        showingNoteEditor = false
        showingRenameDialog = false
        editingNode = nil
        renamingNode = nil
    }
    
    // MARK: - Validation
    
    private func validateMindMapName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            mindMapValidationError = "Mind map name cannot be empty"
            return false
        }
        
        if trimmedName.count < minMindMapNameLength {
            mindMapValidationError = "Mind map name must be at least \(minMindMapNameLength) character"
            return false
        }
        
        if trimmedName.count > maxMindMapNameLength {
            mindMapValidationError = "Mind map name must be no more than \(maxMindMapNameLength) characters"
            return false
        }
        
        mindMapValidationError = nil
        return true
    }
    
    // MARK: - Error Handling
    
    func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
    
    func clearError() {
        errorMessage = nil
        showingErrorAlert = false
    }
    
    // MARK: - Helper Methods
    
    private func refreshFocusedNode() {
        guard let focusedNode = focusedNode else { return }
        
        // Refresh the focused node from Core Data to get updated children
        if let refreshedNode = nodeRepository.fetchNode(with: focusedNode.uuid!) {
            self.focusedNode = refreshedNode
        }
    }
    
    /// Get child nodes for the currently focused node
    func getChildNodes() -> [Node] {
        guard let focusedNode = focusedNode else { return [] }
        return Array(focusedNode.children as? Set<Node> ?? [])
    }
    
    // Removed search service for simplified mind mapping
}

// MARK: - State Management Extensions

extension MindMapStateManager {
    
    /// Reset all state to initial values
    func reset() {
        currentMindMap = nil
        focusedNode = nil
        navigationPath = NavigationPath()
        showingMenu = false
        showingMindMapSelector = false
        showingCreateDialog = false
        showingSearch = false
        showingNoteEditor = false
        showingRenameDialog = false
        newMindMapName = ""
        editingNode = nil
        renamingNode = nil
        errorMessage = nil
        showingErrorAlert = false
        mindMapValidationError = nil
    }
    
    /// Check if we can navigate back
    var canNavigateBack: Bool {
        return !navigationPath.isEmpty
    }
    
    /// Check if we have a focused node
    var hasFocusedNode: Bool {
        return focusedNode != nil
    }
    
    /// Check if we have a current mind map
    var hasCurrentMindMap: Bool {
        return currentMindMap != nil
    }
}
