import CoreData
import Foundation

/// CoreData stack for Atlas app with offline-first architecture
final class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    // MARK: - Core Data Stack
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Atlas")
        
        // Configure for offline-first architecture
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Handle CoreData initialization errors
                print("❌ CoreData failed to load: \(error), \(error.userInfo)")
                // In production, you might want to show an alert or fallback
            } else {
                print("✅ CoreData loaded successfully")
            }
        }
        
        // Configure for better performance
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        
        return container
    }()
    
    // MARK: - Contexts
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private var backgroundContext: NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Save Operations
    func save() {
        let context = viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ CoreData saved successfully")
            } catch {
                print("❌ CoreData save failed: \(error)")
                handleSaveError(error)
            }
        }
    }
    
    func saveBackground() {
        let context = backgroundContext
        
        context.performAndWait {
            if context.hasChanges {
                do {
                    try context.save()
                    print("✅ CoreData background save successful")
                } catch {
                    print("❌ CoreData background save failed: \(error)")
                    handleSaveError(error)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    private func handleSaveError(_ error: Error) {
        // In production, you might want to:
        // - Log to crash reporting service
        // - Show user-friendly error messages
        // - Implement retry mechanisms
        print("💾 CoreData Save Error: \(error.localizedDescription)")
    }
    
    // MARK: - Data Validation
    func validateContext() -> Bool {
        let context = viewContext
        return context.persistentStoreCoordinator != nil
    }
    
    // MARK: - Cleanup Operations
    func deleteAllData() {
        let entities = ["Note", "NoteTag", "Task", "TaskCategory", "JournalEntry", "MoodEntry"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try viewContext.execute(deleteRequest)
                print("✅ Deleted all \(entityName) entities")
            } catch {
                print("❌ Failed to delete \(entityName): \(error)")
            }
        }
        
        save()
    }
    
    // MARK: - Performance Monitoring
    func logDatabaseStats() {
        let entities = ["Note", "NoteTag", "Task", "TaskCategory", "JournalEntry", "MoodEntry"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            
            do {
                let count = try viewContext.count(for: fetchRequest)
                print("📊 \(entityName): \(count) records")
            } catch {
                print("❌ Failed to count \(entityName): \(error)")
            }
        }
    }
}

// MARK: - Preview Support
extension CoreDataStack {
    static var preview: CoreDataStack = {
        let stack = CoreDataStack()
        let context = stack.viewContext
        
        // Add sample data for SwiftUI previews
        let sampleNote = Note(context: context)
        sampleNote.id = UUID()
        sampleNote.title = "Sample Note"
        sampleNote.content = "This is a sample note for previews"
        sampleNote.createdAt = Date()
        sampleNote.updatedAt = Date()
        sampleNote.isEncrypted = false
        
        let sampleTask = Task(context: context)
        sampleTask.id = UUID()
        sampleTask.title = "Sample Task"
        sampleTask.notes = "This is a sample task"
        sampleTask.createdAt = Date()
        sampleTask.updatedAt = Date()
        sampleTask.isCompleted = false
        sampleTask.priority = 1
        
        do {
            try context.save()
        } catch {
            print("❌ Preview data save failed: \(error)")
        }
        
        return stack
    }()
}