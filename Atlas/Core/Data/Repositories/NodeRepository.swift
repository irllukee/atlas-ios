import Foundation
import CoreData

/// Repository for managing Node entities
class NodeRepository: BaseRepository<Node>, @unchecked Sendable {

    // MARK: - Services
    // TODO: Integrate with MindMapSyncManager when architecture is ready

    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - Create Operations
    
    /// Create a new node with the given title and parent
    func createNode(title: String, parent: Node?, mindMap: MindMap?) -> Node? {
        let node = Node.create(context: context, title: title, parent: parent, mindMap: mindMap)

        do {
            try context.save()
            
                    // TODO: Integrate with MindMapSyncManager when Swift 6 concurrency issues are resolved
            
            return node
        } catch {
            print("Failed to create node: \(error)")
            context.rollback()
            return nil
        }
    }
    
    // MARK: - Update Operations
    
    /// Update node title
    func updateNode(_ node: Node, title: String) -> Bool {
        return updateNode(node, title: title, note: nil, direction: nil, level: nil)
    }
    
    /// Update node note
    func updateNode(_ node: Node, note: String) -> Bool {
        return updateNode(node, title: nil, note: note, direction: nil, level: nil)
    }
    
    /// Update node details
    func updateNode(_ node: Node, title: String? = nil, note: String? = nil, direction: String? = nil, level: Int16? = nil) -> Bool {
        let _ = node.title
        let _ = node.note
        
        let _: [String: Any] = [
            "title": node.title ?? "",
            "note": node.note ?? "",
            "level": node.level,
            "direction": node.direction ?? "",
            "updatedAt": node.updatedAt ?? Date()
        ]
        
        node.update(title: title, note: note, direction: direction, level: level)

        do {
            try context.save()
            
            // TODO: Integrate with MindMapSyncManager when Swift 6 concurrency issues are resolved
            
            return true
        } catch {
            print("Failed to update node: \(error)")
            context.rollback()
            return false
        }
    }
    
    // MARK: - Move Operations
    
    /// Move a node to a new parent
    func moveNode(_ node: Node, to newParent: Node?) -> Bool {
        let _ = node.parent?.uuid
        
        let _: [String: Any] = [
            "parentUUID": node.parent?.uuid as Any,
            "updatedAt": node.updatedAt ?? Date()
        ]
        
        let _ = node.parent
        node.parent = newParent
        node.updatedAt = Date()

        do {
            try context.save()
            
            // TODO: Integrate with MindMapSyncManager when Swift 6 concurrency issues are resolved
            
            return true
        } catch {
            print("Failed to move node: \(error)")
            context.rollback()
            return false
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete a node and all its children
    func deleteNode(_ node: Node) -> Bool {
        let _ = node.title
        let _ = node.note
        let _ = node.parent?.uuid
        let _ = node.mindMap?.uuid
        let _ = node.uuid
        
        let _: [String: Any] = [
            "title": node.title ?? "",
            "note": node.note ?? "",
            "level": node.level,
            "direction": node.direction ?? "",
            "createdAt": node.createdAt ?? Date(),
            "updatedAt": node.updatedAt ?? Date(),
            "parentUUID": node.parent?.uuid as Any,
            "mindMapUUID": node.mindMap?.uuid as Any
        ]
        
        context.delete(node)
        
        do {
            try context.save()
            
            // TODO: Integrate with MindMapSyncManager when Swift 6 concurrency issues are resolved
            
            return true
        } catch {
            print("Failed to delete node: \(error)")
            context.rollback()
            return false
        }
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all nodes for a specific mind map
    func fetchNodes(for mindMap: MindMap) -> [Node] {
        let request: NSFetchRequest<Node> = Node.fetchRequest()
        request.predicate = NSPredicate(format: "mindMap == %@", mindMap)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Node.createdAt, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch nodes for mind map: \(error)")
            return []
        }
    }
    
    /// Fetch all children of a specific node
    func fetchChildren(of node: Node) -> [Node] {
        let request: NSFetchRequest<Node> = Node.fetchRequest()
        request.predicate = NSPredicate(format: "parent == %@", node)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Node.createdAt, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch children of node: \(error)")
            return []
        }
    }
    
    /// Fetch a node by UUID
    func fetchNode(with uuid: UUID) -> Node? {
        let request: NSFetchRequest<Node> = Node.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch node: \(error)")
            return nil
        }
    }
    
    // MARK: - Utility Operations
    
    /// Get the count of nodes for a specific mind map
    func getNodeCount(for mindMap: MindMap) -> Int {
        let request: NSFetchRequest<Node> = Node.fetchRequest()
        request.predicate = NSPredicate(format: "mindMap == %@", mindMap)
        
        do {
            return try context.count(for: request)
        } catch {
            print("Failed to count nodes: \(error)")
            return 0
        }
    }
    
    /// Check if a node has children
    func hasChildren(_ node: Node) -> Bool {
        let request: NSFetchRequest<Node> = Node.fetchRequest()
        request.predicate = NSPredicate(format: "parent == %@", node)
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Failed to check if node has children: \(error)")
            return false
        }
    }
    
    /// Get the depth level of a node
    func getNodeDepth(_ node: Node) -> Int {
        var depth = 0
        var current = node.parent
        
        while current != nil {
            depth += 1
            current = current?.parent
        }
        
        return depth
    }
}
