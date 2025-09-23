import Foundation
import CoreData

// MARK: - Journal Initialization Service
@MainActor
class JournalInitializationService {
    static let shared = JournalInitializationService()
    
    private init() {}
    
    func initializeJournalData() async {
        let context = CoreDataStack.shared.viewContext
        await setupBuiltInTemplates(context: context)
        await setupBuiltInPrompts(context: context)
    }
    
    private func setupBuiltInTemplates(context: NSManagedObjectContext) async {
        // Check if templates already exist
        let templateRequest: NSFetchRequest<JournalTemplate> = JournalTemplate.fetchRequest()
        templateRequest.predicate = NSPredicate(format: "isBuiltIn == YES")
        
        do {
            let existingTemplates = try context.fetch(templateRequest)
            
            if existingTemplates.isEmpty {
                // Add built-in templates
                for templateData in JournalTemplate.builtInTemplates {
                    let template = JournalTemplate(context: context)
                    template.uuid = UUID()
                    template.name = templateData.name
                    template.type = templateData.type.rawValue
                    template.content = templateData.content
                    template.isBuiltIn = true
                    template.createdAt = Date()
                    template.updatedAt = Date()
                    template.usageCount = 0
                }
                
                try context.save()
                print("✅ Journal built-in templates initialized")
            }
        } catch {
            print("❌ Error setting up journal templates: \(error)")
        }
    }
    
    private func setupBuiltInPrompts(context: NSManagedObjectContext) async {
        // Check if prompts already exist
        let promptRequest: NSFetchRequest<JournalPrompt> = JournalPrompt.fetchRequest()
        promptRequest.predicate = NSPredicate(format: "isCustom == NO")
        
        do {
            let existingPrompts = try context.fetch(promptRequest)
            
            if existingPrompts.isEmpty {
                // Add built-in prompts
                for promptData in JournalPrompt.builtInPrompts {
                    let prompt = JournalPrompt(context: context)
                    prompt.uuid = UUID()
                    prompt.text = promptData.text
                    prompt.type = promptData.type.rawValue
                    prompt.isCustom = false
                    prompt.createdAt = Date()
                    prompt.updatedAt = Date()
                    prompt.usageCount = 0
                }
                
                try context.save()
                print("✅ Journal built-in prompts initialized")
            }
        } catch {
            print("❌ Error setting up journal prompts: \(error)")
        }
    }
}
