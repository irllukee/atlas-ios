import SwiftUI
import Foundation

// MARK: - Galaxy Manager
@MainActor
class GalaxyManager: ObservableObject {
    @Published var galaxies: [Galaxy] = []
    @Published var selectedGalaxy: Galaxy?
    
    private let userDefaults = UserDefaults.standard
    private let galaxiesKey = "saved_galaxies"
    
    init() {
        loadGalaxiesAsync()
    }
    
    // MARK: - Galaxy Management
    func createGalaxy(name: String, description: String = "", nodeTypes: [NodeType] = [.note], theme: GalaxyTheme = .cosmic) -> Galaxy {
        let galaxy = Galaxy(name: name, description: description, nodeTypes: nodeTypes, theme: theme)
        galaxies.append(galaxy)
        saveGalaxies()
        return galaxy
    }
    
    func selectGalaxy(_ galaxy: Galaxy) {
        selectedGalaxy = galaxy
    }
    
    func updateGalaxy(_ galaxy: Galaxy) {
        if let index = galaxies.firstIndex(where: { $0.id == galaxy.id }) {
            var updatedGalaxy = galaxy
            updatedGalaxy.lastModified = Date()
            galaxies[index] = updatedGalaxy
            saveGalaxies()
            
            if selectedGalaxy?.id == galaxy.id {
                selectedGalaxy = updatedGalaxy
            }
        }
    }
    
    func deleteGalaxy(_ galaxy: Galaxy) {
        galaxies.removeAll { $0.id == galaxy.id }
        if selectedGalaxy?.id == galaxy.id {
            selectedGalaxy = galaxies.first
        }
        saveGalaxies()
    }
    
    func duplicateGalaxy(_ galaxy: Galaxy) -> Galaxy {
        var duplicatedGalaxy = galaxy
        duplicatedGalaxy = Galaxy(
            name: "\(galaxy.name) Copy",
            description: galaxy.description,
            nodeTypes: galaxy.nodeTypes,
            theme: galaxy.theme
        )
        duplicatedGalaxy.nodes = galaxy.nodes
        duplicatedGalaxy.connections = galaxy.connections
        
        galaxies.append(duplicatedGalaxy)
        saveGalaxies()
        return duplicatedGalaxy
    }
    
    // MARK: - Node Management
    func addNode(to galaxy: Galaxy, node: GalaxyNode) {
        guard var updatedGalaxy = galaxies.first(where: { $0.id == galaxy.id }) else { return }
        updatedGalaxy.nodes.append(node)
        updatedGalaxy.lastModified = Date()
        updateGalaxy(updatedGalaxy)
    }
    
    func updateNode(in galaxy: Galaxy, node: GalaxyNode) {
        guard var updatedGalaxy = galaxies.first(where: { $0.id == galaxy.id }) else { return }
        if let index = updatedGalaxy.nodes.firstIndex(where: { $0.id == node.id }) {
            updatedGalaxy.nodes[index] = node
            updatedGalaxy.lastModified = Date()
            updateGalaxy(updatedGalaxy)
        }
    }
    
    func deleteNode(from galaxy: Galaxy, nodeId: UUID) {
        guard var updatedGalaxy = galaxies.first(where: { $0.id == galaxy.id }) else { return }
        updatedGalaxy.nodes.removeAll { $0.id == nodeId }
        updatedGalaxy.connections.removeAll { $0.fromNode.id == nodeId || $0.toNode.id == nodeId }
        updatedGalaxy.lastModified = Date()
        updateGalaxy(updatedGalaxy)
    }
    
    // MARK: - Connection Management
    func addConnection(to galaxy: Galaxy, connection: GalaxyConnection) {
        guard var updatedGalaxy = galaxies.first(where: { $0.id == galaxy.id }) else { return }
        updatedGalaxy.connections.append(connection)
        updatedGalaxy.lastModified = Date()
        updateGalaxy(updatedGalaxy)
    }
    
    func deleteConnection(from galaxy: Galaxy, connectionId: UUID) {
        guard var updatedGalaxy = galaxies.first(where: { $0.id == galaxy.id }) else { return }
        updatedGalaxy.connections.removeAll { $0.id == connectionId }
        updatedGalaxy.lastModified = Date()
        updateGalaxy(updatedGalaxy)
    }
    
    
    // MARK: - Persistence
    private func saveGalaxies() {
        if let encoded = try? JSONEncoder().encode(galaxies) {
            userDefaults.set(encoded, forKey: galaxiesKey)
        }
    }
    
    private func loadGalaxies() {
        if let data = userDefaults.data(forKey: galaxiesKey),
           let decoded = try? JSONDecoder().decode([Galaxy].self, from: data) {
            galaxies = decoded
        }
    }
    
    private func loadGalaxiesAsync() {
        // Capture data on main thread before going to background
        let data = userDefaults.data(forKey: galaxiesKey)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if let data = data,
               let decoded = try? JSONDecoder().decode([Galaxy].self, from: data) {
                
                DispatchQueue.main.async {
                    self.galaxies = decoded
                    self.createDefaultGalaxyIfNeeded()
                }
            } else {
                DispatchQueue.main.async {
                    self.createDefaultGalaxyIfNeeded()
                }
            }
        }
    }
    
    private func createDefaultGalaxyIfNeeded() {
        if galaxies.isEmpty {
            let defaultGalaxy = createGalaxy(
                name: "My First Galaxy",
                description: "A cosmic space for your thoughts and ideas",
                nodeTypes: [.note, .task, .journal],
                theme: .cosmic
            )
            selectedGalaxy = defaultGalaxy
        } else if selectedGalaxy == nil {
            selectedGalaxy = galaxies.first
        }
    }
}

// MARK: - Galaxy Preview Data
extension GalaxyManager {
    static let previewGalaxies: [Galaxy] = [
        Galaxy(name: "Dream Symbols", description: "Explore your dream patterns", nodeTypes: [.dream], theme: .dreamy),
        Galaxy(name: "Story Characters", description: "Character relationships and development", nodeTypes: [.note], theme: .creative),
        Galaxy(name: "Project Ideas", description: "Brainstorming and planning", nodeTypes: [.note, .task], theme: .analytical),
        Galaxy(name: "Spiritual Journey", description: "Personal growth and insights", nodeTypes: [.journal], theme: .mystical)
    ]
}
