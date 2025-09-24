import Foundation
import CoreData

/// Repository for managing MindMap entities
class MindMapRepository: BaseRepository<MindMap>, @unchecked Sendable {
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all mind maps sorted by creation date
    func fetchAllMindMaps() -> [MindMap] {
        let request: NSFetchRequest<MindMap> = MindMap.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MindMap.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch mind maps: \(error)")
            return []
        }
    }
    
    /// Fetch a specific mind map by UUID
    func fetchMindMap(with uuid: UUID) -> MindMap? {
        let request: NSFetchRequest<MindMap> = MindMap.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch mind map: \(error)")
            return nil
        }
    }
    
    // MARK: - Create Operations
    
    /// Create a new mind map with the given name
    func createMindMap(name: String) -> MindMap? {
        let mindMap = MindMap.create(context: context, name: name)
        
        do {
            try context.save()
            return mindMap
        } catch {
            print("Failed to create mind map: \(error)")
            context.rollback()
            return nil
        }
    }
    
    // MARK: - Update Operations
    
    /// Update mind map name
    func updateMindMap(_ mindMap: MindMap, name: String) -> Bool {
        mindMap.update(name: name)
        
        do {
            try context.save()
            return true
        } catch {
            print("Failed to update mind map: \(error)")
            context.rollback()
            return false
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete a mind map and all its nodes
    func deleteMindMap(_ mindMap: MindMap) -> Bool {
        mindMap.deleteWithAllNodes()
        
        do {
            try context.save()
            return true
        } catch {
            print("Failed to delete mind map: \(error)")
            context.rollback()
            return false
        }
    }
    
    // MARK: - Utility Operations
    
    /// Get the count of mind maps
    func getMindMapCount() -> Int {
        let request: NSFetchRequest<MindMap> = MindMap.fetchRequest()
        
        do {
            return try context.count(for: request)
        } catch {
            print("Failed to count mind maps: \(error)")
            return 0
        }
    }
    
    /// Check if a mind map name already exists
    func mindMapNameExists(_ name: String, excluding: MindMap? = nil) -> Bool {
        let request: NSFetchRequest<MindMap> = MindMap.fetchRequest()
        
        if let excluding = excluding {
            request.predicate = NSPredicate(format: "name == %@ AND uuid != %@", name, excluding.uuid! as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "name == %@", name)
        }
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Failed to check mind map name: \(error)")
            return false
        }
    }
    
    /// Generate a unique name for a new mind map
    func generateUniqueName(baseName: String = "Mind Map") -> String {
        var counter = 1
        var name = baseName
        
        while mindMapNameExists(name) {
            counter += 1
            name = "\(baseName) \(counter)"
        }
        
        return name
    }
}
