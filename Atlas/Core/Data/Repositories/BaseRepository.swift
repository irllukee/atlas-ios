import Foundation
import CoreData

/// Base repository class providing common CRUD operations
class BaseRepository<T: NSManagedObject>: @unchecked Sendable {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create
    func create() -> T {
        return T(context: context)
    }
    
    // MARK: - Read
    func fetchAll() -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.fetchBatchSize = 20 // Batch loading for performance
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch \(T.self): \(error)")
            return []
        }
    }
    
    func fetch(by id: UUID) -> T? {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.predicate = NSPredicate(format: "uuid == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Failed to fetch \(T.self) by ID: \(error)")
            return nil
        }
    }
    
    func fetch(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor] = []) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch \(T.self) with predicate: \(error)")
            return []
        }
    }
    
    func count(predicate: NSPredicate? = nil) -> Int {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.predicate = predicate
        
        do {
            return try context.count(for: request)
        } catch {
            print("❌ Failed to count \(T.self): \(error)")
            return 0
        }
    }
    
    // MARK: - Update
    func save() -> Bool {
        guard context.hasChanges else { return true }
        
        do {
            try context.save()
            return true
        } catch {
            print("❌ Failed to save \(T.self): \(error)")
            return false
        }
    }
    
    // MARK: - Delete
    func delete(_ object: T) -> Bool {
        context.delete(object)
        return save()
    }
    
    func delete(by id: UUID) -> Bool {
        guard let object = fetch(by: id) else { return false }
        return delete(object)
    }
    
    func deleteAll() -> Bool {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: T.self))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            return save()
        } catch {
            print("❌ Failed to delete all \(T.self): \(error)")
            return false
        }
    }
    
    // MARK: - Utility
    func exists(id: UUID) -> Bool {
        return fetch(by: id) != nil
    }
    
    func first() -> T? {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Failed to fetch first \(T.self): \(error)")
            return nil
        }
    }
    
    func last() -> T? {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Failed to fetch last \(T.self): \(error)")
            return nil
        }
    }
}

// MARK: - Async Operations
extension BaseRepository {
    func fetchAllAsync() async -> [T] {
        return await withCheckedContinuation { continuation in
            context.perform {
                let result = self.fetchAll()
                continuation.resume(returning: result)
            }
        }
    }
    
    func fetchAsync(by id: UUID) async -> T? {
        return await withCheckedContinuation { continuation in
            context.perform {
                let result = self.fetch(by: id)
                continuation.resume(returning: result)
            }
        }
    }
    
    func saveAsync() async -> Bool {
        return await withCheckedContinuation { continuation in
            context.perform {
                let result = self.save()
                continuation.resume(returning: result)
            }
        }
    }
    
    func deleteAsync(_ object: T) async -> Bool {
        return await withCheckedContinuation { continuation in
            context.perform {
                let result = self.delete(object)
                continuation.resume(returning: result)
            }
        }
    }
}