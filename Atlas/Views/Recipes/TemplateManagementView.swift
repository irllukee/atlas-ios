import SwiftUI

struct TemplateManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var recipesService: RecipesService
    
    @State private var templates: [Recipe] = []
    @State private var showCreateFromTemplate = false
    @State private var selectedTemplate: Recipe?
    @State private var newRecipeTitle = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Info
                    headerInfoSection
                    
                    // Templates List
                    templatesListSection
                }
            }
            .navigationTitle("Recipe Templates")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
                }
            }
        }
        .onAppear {
            loadTemplates()
        }
        .alert("Create Recipe from Template", isPresented: $showCreateFromTemplate) {
            TextField("Recipe Title", text: $newRecipeTitle)
            Button("Cancel", role: .cancel) {
                newRecipeTitle = ""
                selectedTemplate = nil
            }
            Button("Create") {
                createRecipeFromTemplate()
            }
            .disabled(newRecipeTitle.isEmpty)
        } message: {
            Text("Enter a name for your new recipe based on the template.")
        }
    }
    
    // MARK: - Header Info Section
    private var headerInfoSection: some View {
        FrostedCard(style: .compact) {
            VStack(spacing: AtlasTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "doc.on.doc")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.primary)
                    
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                        Text("Recipe Templates")
                            .font(AtlasTheme.Typography.headline)
                            .foregroundColor(AtlasTheme.Colors.text)
                        
                        Text("\(templates.count) templates available")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                }
                
                Text("Templates help you quickly create similar recipes. Create a template from any recipe, then use it to start new recipes with the same structure.")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.top, AtlasTheme.Spacing.md)
    }
    
    // MARK: - Templates List Section
    private var templatesListSection: some View {
        ScrollView {
            if templates.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: AtlasTheme.Spacing.sm) {
                    ForEach(templates, id: \.uuid) { template in
                        TemplateRow(
                            template: template,
                            onUse: {
                                selectedTemplate = template
                                newRecipeTitle = ""
                                showCreateFromTemplate = true
                            },
                            onEdit: {
                                // Navigate to edit template
                            },
                            onDelete: {
                                deleteTemplate(template)
                            }
                        )
                    }
                }
                .padding(.horizontal, AtlasTheme.Spacing.lg)
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: AtlasTheme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "doc.on.doc")
                .font(.system(size: 60))
                .foregroundColor(AtlasTheme.Colors.primary)
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                Text("No Templates Created")
                    .font(AtlasTheme.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("Create your first template from any recipe to get started")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                Text("How to create templates:")
                    .font(AtlasTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                    Text("1. Open any recipe")
                        .font(AtlasTheme.Typography.caption2)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    Text("2. Tap the menu (⋯) button")
                        .font(AtlasTheme.Typography.caption2)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    Text("3. Select 'Create Template'")
                        .font(AtlasTheme.Typography.caption2)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                }
            }
            .padding(AtlasTheme.Spacing.md)
            .background(AtlasTheme.Colors.primary.opacity(0.1))
            .cornerRadius(AtlasTheme.CornerRadius.small)
            
            Spacer()
        }
        .padding(.horizontal, AtlasTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    private func loadTemplates() {
        templates = recipesService.fetchRecipes(templatesOnly: true)
    }
    
    private func createRecipeFromTemplate() {
        guard let template = selectedTemplate else { return }
        
        _ = recipesService.createRecipeFromTemplate(template, title: newRecipeTitle)
        
        // Navigate to edit the new recipe
        newRecipeTitle = ""
        selectedTemplate = nil
        presentationMode.wrappedValue.dismiss()
    }
    
    private func deleteTemplate(_ template: Recipe) {
        recipesService.deleteRecipe(template)
        loadTemplates()
    }
}

// MARK: - Template Row Component
struct TemplateRow: View {
    let template: Recipe
    let onUse: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        FrostedCard(style: .compact) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                // Template Header
                HStack {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                        Text(template.title ?? "Untitled Template")
                            .font(AtlasTheme.Typography.headline)
                            .foregroundColor(AtlasTheme.Colors.text)
                        
                        HStack(spacing: AtlasTheme.Spacing.sm) {
                            if let category = template.category {
                                HStack(spacing: AtlasTheme.Spacing.xs) {
                                    Image(systemName: category.icon ?? "questionmark")
                                        .font(.caption)
                                    Text(category.name ?? "Unknown")
                                        .font(AtlasTheme.Typography.caption)
                                }
                                .foregroundColor(AtlasTheme.Colors.primary)
                            }
                            
                            Text("Template")
                                .font(AtlasTheme.Typography.caption)
                                .padding(.horizontal, AtlasTheme.Spacing.sm)
                                .padding(.vertical, AtlasTheme.Spacing.xs)
                                .background(AtlasTheme.Colors.secondary.opacity(0.2))
                                .foregroundColor(AtlasTheme.Colors.secondary)
                                .cornerRadius(AtlasTheme.CornerRadius.small)
                        }
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(action: onUse) {
                            Label("Use Template", systemImage: "plus.circle")
                        }
                        
                        Button(action: onEdit) {
                            Label("Edit Template", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete Template", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                }
                
                // Template Stats
                HStack(spacing: AtlasTheme.Spacing.lg) {
                    if let ingredients = template.ingredients, ingredients.count > 0 {
                        HStack(spacing: AtlasTheme.Spacing.xs) {
                            Image(systemName: "list.bullet")
                                .font(.caption)
                            Text("\(ingredients.count) ingredients")
                                .font(AtlasTheme.Typography.caption)
                        }
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    
                    if let steps = template.steps, steps.count > 0 {
                        HStack(spacing: AtlasTheme.Spacing.xs) {
                            Image(systemName: "list.number")
                                .font(.caption)
                            Text("\(steps.count) steps")
                                .font(AtlasTheme.Typography.caption)
                        }
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    
                    if template.prepTime > 0 || template.cookingTime > 0 {
                        HStack(spacing: AtlasTheme.Spacing.xs) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(timeText)
                                .font(AtlasTheme.Typography.caption)
                        }
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                }
                
                // Use Template Button
                Button(action: onUse) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Use This Template")
                            .font(AtlasTheme.Typography.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AtlasTheme.Spacing.sm)
                    .background(AtlasTheme.Colors.primary)
                    .cornerRadius(AtlasTheme.CornerRadius.small)
                }
            }
        }
        .alert("Delete Template?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("This template will be permanently deleted. This action cannot be undone.")
        }
    }
    
    private var timeText: String {
        let totalMinutes = template.prepTime + template.cookingTime
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
}

#Preview {
    TemplateManagementView(recipesService: RecipesService(dataManager: DataManager.shared))
}


