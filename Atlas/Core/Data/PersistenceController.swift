import Foundation
import CoreData

/// Persistence controller for CoreData operations and preview support
struct PersistenceController {
    static let shared = PersistenceController()
    
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        createSampleData(in: viewContext)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Atlas")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// Create sample data for previews
    private static func createSampleData(in context: NSManagedObjectContext) {
        // Create sample notes
        let note1 = Note(context: context)
        note1.id = UUID()
        note1.title = "Welcome to Atlas"
        note1.content = "This is your first note in Atlas. You can create, edit, and organize your notes here."
        // note1.category = "Getting Started" // Note: Using tags instead of category
        note1.createdAt = Date()
        note1.updatedAt = Date()
        note1.isEncrypted = false
        
        let note2 = Note(context: context)
        note2.id = UUID()
        note2.title = "Meeting Notes"
        note2.content = "## Project Planning Meeting\n\n**Date:** Today\n**Attendees:** Team\n\n### Agenda\n- Review project status\n- Plan next sprint\n- Discuss blockers\n\n### Action Items\n- [ ] Update documentation\n- [ ] Review code changes"
        // note2.category = "Work" // Note: Using tags instead of category
        note2.createdAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        note2.updatedAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        note2.isEncrypted = false
        
        let note3 = Note(context: context)
        note3.id = UUID()
        note3.title = "Private Thoughts"
        note3.content = "This is a private note with sensitive information."
        // note3.category = "Private" // Note: Using tags instead of category
        note3.createdAt = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        note3.updatedAt = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        note3.isEncrypted = true
        
        // Create sample tasks
        let task1 = Task(context: context)
        task1.id = UUID()
        task1.title = "Complete project documentation"
        task1.notes = "Update the README and API documentation"
        task1.createdAt = Date()
        task1.updatedAt = Date()
        task1.isCompleted = false
        task1.priority = 2
        task1.dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        
        let task2 = Task(context: context)
        task2.id = UUID()
        task2.title = "Review code changes"
        task2.notes = "Review the latest pull requests"
        task2.createdAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        task2.updatedAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        task2.isCompleted = true
        task2.completedAt = Date()
        task2.priority = 1
    }
}
