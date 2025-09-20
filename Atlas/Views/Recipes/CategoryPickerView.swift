import SwiftUI

struct CategoryPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    let categories: [RecipeCategory]
    @Binding var selectedCategory: RecipeCategory?
    @ObservedObject var recipesService: RecipesService
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: AtlasTheme.Spacing.md) {
                        ForEach(categories, id: \.uuid) { category in
                            CategoryRow(
                                category: category,
                                isSelected: selectedCategory?.uuid == category.uuid,
                                onSelect: {
                                    selectedCategory = category
                                    presentationMode.wrappedValue.dismiss()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    .padding(.top, AtlasTheme.Spacing.md)
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
                }
            }
        }
    }
}

struct CategoryRow: View {
    let category: RecipeCategory
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            FrostedCard {
                HStack(spacing: AtlasTheme.Spacing.md) {
                    Image(systemName: category.icon ?? "questionmark")
                        .font(.title2)
                        .foregroundColor(isSelected ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                        Text(category.name ?? "Unknown Category")
                            .font(AtlasTheme.Typography.headline)
                            .foregroundColor(AtlasTheme.Colors.text)
                        
                        Text(isSelected ? "Selected" : "Tap to select")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(isSelected ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(AtlasTheme.Colors.primary)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let dataManager = DataManager.shared
    let recipesService = RecipesService(dataManager: dataManager)
    let categories = recipesService.fetchCategories()
    
    CategoryPickerView(
        categories: categories,
        selectedCategory: .constant(nil),
        recipesService: recipesService
    )
}

