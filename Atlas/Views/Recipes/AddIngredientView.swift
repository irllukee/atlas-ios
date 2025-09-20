import SwiftUI

struct AddIngredientView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var ingredients: [RecipeIngredient]
    @ObservedObject var recipesService: RecipesService
    
    @State private var name = ""
    @State private var amount = 1.0
    @State private var unit = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AtlasTheme.Spacing.lg) {
                        FrostedCard {
                            VStack(spacing: AtlasTheme.Spacing.md) {
                                SectionHeader(title: "Ingredient Details")
                                
                                VStack(spacing: AtlasTheme.Spacing.md) {
                                    AtlasTextField(
                                        title: "Ingredient Name",
                                        text: $name,
                                        placeholder: "e.g., Flour, Salt, Olive Oil"
                                    )
                                    
                                    HStack(spacing: AtlasTheme.Spacing.md) {
                                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                                            Text("Amount")
                                                .font(AtlasTheme.Typography.caption)
                                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                                            
                                            TextField("1.0", value: $amount, format: .number)
                                                .textFieldStyle(PlainTextFieldStyle())
                                                .font(AtlasTheme.Typography.body)
                                                .padding(AtlasTheme.Spacing.md)
                                                .background(AtlasTheme.Colors.cardBackground.opacity(0.3))
                                                .cornerRadius(AtlasTheme.CornerRadius.small)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                                            Text("Unit")
                                                .font(AtlasTheme.Typography.caption)
                                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                                            
                                            TextField("cups", text: $unit)
                                                .textFieldStyle(PlainTextFieldStyle())
                                                .font(AtlasTheme.Typography.body)
                                                .padding(AtlasTheme.Spacing.md)
                                                .background(AtlasTheme.Colors.cardBackground.opacity(0.3))
                                                .cornerRadius(AtlasTheme.CornerRadius.small)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                                        Text("Notes (Optional)")
                                            .font(AtlasTheme.Typography.caption)
                                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                                        
                                        TextField("e.g., chopped, room temperature", text: $notes)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .font(AtlasTheme.Typography.body)
                                            .padding(AtlasTheme.Spacing.md)
                                            .background(AtlasTheme.Colors.cardBackground.opacity(0.3))
                                            .cornerRadius(AtlasTheme.CornerRadius.small)
                                    }
                                    
                                    // Preview
                                    if !name.isEmpty {
                                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                                            Text("Preview")
                                                .font(AtlasTheme.Typography.caption)
                                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                                            
                                            Text(previewText)
                                                .font(AtlasTheme.Typography.body)
                                                .foregroundColor(AtlasTheme.Colors.text)
                                                .padding(AtlasTheme.Spacing.md)
                                                .background(AtlasTheme.Colors.primary.opacity(0.1))
                                                .cornerRadius(AtlasTheme.CornerRadius.small)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Common Units
                        commonUnitsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    .padding(.top, AtlasTheme.Spacing.md)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addIngredient()
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Common Units Section
    private var commonUnitsSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Common Units")
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AtlasTheme.Spacing.sm) {
                    ForEach(commonUnits, id: \.self) { unit in
                        Button(action: {
                            self.unit = unit
                        }) {
                            Text(unit)
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(self.unit == unit ? .white : AtlasTheme.Colors.text)
                                .padding(.horizontal, AtlasTheme.Spacing.md)
                                .padding(.vertical, AtlasTheme.Spacing.sm)
                                .background(self.unit == unit ? AtlasTheme.Colors.primary : AtlasTheme.Colors.cardBackground.opacity(0.3))
                                .cornerRadius(AtlasTheme.CornerRadius.small)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var previewText: String {
        var text = "\(amount, specifier: "%.1f")"
        if !unit.isEmpty {
            text += " \(unit)"
        }
        text += " \(name)"
        if !notes.isEmpty {
            text += " (\(notes))"
        }
        return text
    }
    
    private var commonUnits: [String] {
        [
            "cups", "tbsp", "tsp", "oz", "lb", "g", "kg", "ml", "L", "pieces", "cloves", "slices", "pinch", "dash"
        ]
    }
    
    // MARK: - Helper Methods
    private func addIngredient() {
        let ingredient = RecipeIngredient()
        ingredient.uuid = UUID()
        ingredient.name = name
        ingredient.amount = amount
        ingredient.unit = unit.isEmpty ? nil : unit
        ingredient.notes = notes.isEmpty ? nil : notes
        ingredient.order = Int16(ingredients.count)
        ingredient.createdAt = Date()
        ingredient.updatedAt = Date()
        
        ingredients.append(ingredient)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AddIngredientView(
        ingredients: .constant([]),
        recipesService: RecipesService(dataManager: DataManager.shared)
    )
}


