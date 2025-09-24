import Foundation
import CoreData

// MARK: - Migration Manager
@MainActor
final class CoreDataMigrationManager: @unchecked Sendable {
    static let shared = CoreDataMigrationManager()
    
    private init() {}
    
    func requiresMigration(at storeURL: URL, to version: String) -> Bool {
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL) else {
            return false
        }
        
        return (metadata[NSStoreModelVersionHashesKey] as? [String: Any]) != nil
    }
    
    func performMigration(from sourceURL: URL, to destinationURL: URL) throws {
        let sourceMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: sourceURL)
        guard let destinationModel = NSManagedObjectModel.mergedModel(from: Bundle.allBundles) else {
            throw NSError(domain: "MigrationError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Could not load destination model"])
        }
        
        guard let sourceModel = NSManagedObjectModel(contentsOf: sourceURL.appendingPathComponent("Contents")) else {
            throw NSError(domain: "MigrationError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Could not load source model"])
        }
        
        // Perform lightweight migration
        let mappingModel = try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
        
        let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        
        try migrationManager.migrateStore(from: sourceURL, sourceType: NSSQLiteStoreType, options: nil, with: mappingModel, toDestinationURL: destinationURL, destinationType: NSSQLiteStoreType, destinationOptions: nil)
    }
}

// MARK: - CoreDataStack
@MainActor
final class CoreDataStack {
    static let shared = CoreDataStack() // Singleton

    let persistentContainer: NSPersistentContainer
    private let migrationManager = CoreDataMigrationManager.shared

    private init() {
        print("📋 CoreDataStack: Initializing...")
        // Use regular NSPersistentContainer for local storage only
        persistentContainer = NSPersistentContainer(name: "Atlas")

        // Configure store for local storage only
        guard let description = persistentContainer.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // Configure migration settings
        setupMigration(description: description)
        
        persistentContainer.loadPersistentStores { [weak self] description, error in
            self?.handleStoreLoading(description: description, error: error)
        }
        
        // Automatically merge changes from other contexts
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    private func setupMigration(description: NSPersistentStoreDescription) {
        // Enable automatic migration for lightweight changes
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        // Enable history tracking to prevent read-only mode issues
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        // Set migration options for better performance
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        // Configure SQLite options for better performance
        var sqliteOptions: [String: Any] = [:]
        sqliteOptions["journal_mode"] = "WAL" // Write-Ahead Logging for better concurrency
        sqliteOptions["synchronous"] = "NORMAL" // Balance between performance and safety
        sqliteOptions["cache_size"] = 10000 // Increase cache size
        sqliteOptions["temp_store"] = "MEMORY" // Store temporary tables in memory
        description.setOption(sqliteOptions as NSDictionary, forKey: NSSQLitePragmasOption)
    }
    
    private func handleStoreLoading(description: NSPersistentStoreDescription, error: Error?) {
        if let error = error {
            print("❌ Core Data Error: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            
            // Attempt migration if needed
            if let storeURL = description.url, 
               migrationManager.requiresMigration(at: storeURL, to: "1.0") {
                do {
                    try performStoreMigration(from: storeURL)
                    // Retry loading after migration
                    retryStoreLoading(description: description)
                    return
                } catch {
                    print("❌ Migration failed: \(error)")
                }
            }
            
            // Try to delete the store and recreate it as last resort
            if let storeURL = description.url {
                do {
                    try FileManager.default.removeItem(at: storeURL)
                    print("✅ Deleted corrupted store, will recreate on next launch")
                } catch {
                    print("❌ Failed to delete store: \(error)")
                }
            }
            
            fatalError("Failed to load Core Data stack: \(error.localizedDescription)")
        } else {
            print("✅ Core Data stack loaded successfully")
            logDatabaseStats()
        }
    }
    
    private func performStoreMigration(from storeURL: URL) throws {
        print("🔄 Performing Core Data migration...")
        
        let backupURL = storeURL.appendingPathExtension("backup")
        
        // Create backup
        try FileManager.default.copyItem(at: storeURL, to: backupURL)
        print("📦 Created backup at: \(backupURL)")
        
        // Perform migration
        try migrationManager.performMigration(from: storeURL, to: storeURL)
        
        // Remove backup after successful migration
        try FileManager.default.removeItem(at: backupURL)
        print("✅ Migration completed successfully")
    }
    
    private func retryStoreLoading(description: NSPersistentStoreDescription) {
        persistentContainer.loadPersistentStores { [weak self] description, error in
            self?.handleStoreLoading(description: description, error: error)
        }
    }

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    func newDerivedContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }

    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func saveAsync() {
        guard viewContext.hasChanges else { return }
        
        performBackgroundTask { backgroundContext in
            do {
                try backgroundContext.save()
                print("✅ Background save completed successfully")
            } catch {
                print("❌ Background save failed: \(error)")
                // Fallback to main thread save
                DispatchQueue.main.async {
                    self.save()
                }
            }
        }
    }
    
    func autoSave() {
        guard viewContext.hasChanges else { return }
        
        // Use background save for better performance
        saveAsync()
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    // MARK: - Data Validation & Cleanup
    func validateContext() -> Bool {
        return viewContext.persistentStoreCoordinator != nil
    }

    func deleteAllData() {
        let entities = persistentContainer.managedObjectModel.entities
        for entity in entities {
            if let entityName = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                do {
                    try viewContext.execute(batchDeleteRequest)
                } catch {
                    print("Error deleting all data for entity \(entityName): \(error)")
                }
            }
        }
        save()
    }

    func logDatabaseStats() {
        let entities = persistentContainer.managedObjectModel.entities
        // Core Data Database Statistics
        for entity in entities {
            if let entityName = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                do {
                    let count = try viewContext.count(for: fetchRequest)
                    print("  - \(entityName): \(count) records")
                } catch {
                    print("  - Error fetching count for \(entityName): \(error)")
                }
            }
        }
    }
}
