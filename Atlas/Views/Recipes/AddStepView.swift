import SwiftUI

struct AddStepView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var steps: [RecipeStep]
    @ObservedObject var recipesService: RecipesService
    
    @State private var content = ""
    @State private var timerMinutes = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AtlasTheme.Spacing.lg) {
                        FrostedCard {
                            VStack(spacing: AtlasTheme.Spacing.md) {
                                SectionHeader(title: "Step Details")
                                
                                VStack(spacing: AtlasTheme.Spacing.md) {
                                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                                        Text("Instructions")
                                            .font(AtlasTheme.Typography.caption)
                                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                                        
                                        TextEditor(text: $content)
                                            .frame(minHeight: 120)
                                            .padding(AtlasTheme.Spacing.sm)
                                            .background(AtlasTheme.Colors.cardBackground.opacity(0.3))
                                            .cornerRadius(AtlasTheme.CornerRadius.small)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                                        Text("Timer (Optional)")
                                            .font(AtlasTheme.Typography.caption)
                                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                                        
                                        HStack {
                                            Stepper("\(timerMinutes) minutes", value: $timerMinutes, in: 0...180, step: 1)
                                                .font(AtlasTheme.Typography.body)
                                            
                                            Spacer()
                                            
                                            if timerMinutes > 0 {
                                                Button(action: {
                                                    timerMinutes = 0
                                                }) {
                                                    Text("Clear")
                                                        .font(AtlasTheme.Typography.caption)
                                                        .foregroundColor(.red)
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Preview
                                    if !content.isEmpty {
                                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                                            Text("Preview")
                                                .font(AtlasTheme.Typography.caption)
                                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                                            
                                            HStack(alignment: .top, spacing: AtlasTheme.Spacing.md) {
                                                Text("\(steps.count + 1)")
                                                    .font(AtlasTheme.Typography.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(AtlasTheme.Colors.primary)
                                                    .frame(width: 24, height: 24)
                                                    .background(AtlasTheme.Colors.primary.opacity(0.1))
                                                    .clipShape(Circle())
                                                
                                                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                                                    Text(content)
                                                        .font(AtlasTheme.Typography.body)
                                                        .foregroundColor(AtlasTheme.Colors.text)
                                                    
                                                    if timerMinutes > 0 {
                                                        HStack(spacing: AtlasTheme.Spacing.xs) {
                                                            Image(systemName: "timer")
                                                                .font(.caption)
                                                            Text("\(timerMinutes) minutes")
                                                                .font(AtlasTheme.Typography.caption)
                                                        }
                                                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                                                        .padding(.horizontal, AtlasTheme.Spacing.sm)
                                                        .padding(.vertical, AtlasTheme.Spacing.xs)
                                                        .background(AtlasTheme.Colors.cardBackground.opacity(0.3))
                                                        .cornerRadius(AtlasTheme.CornerRadius.small)
                                                    }
                                                }
                                            }
                                            .padding(AtlasTheme.Spacing.md)
                                            .background(AtlasTheme.Colors.primary.opacity(0.05))
                                            .cornerRadius(AtlasTheme.CornerRadius.small)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Common Cooking Actions
                        commonActionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    .padding(.top, AtlasTheme.Spacing.md)
                }
            }
            .navigationTitle("Add Step")
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
                        addStep()
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
                    .disabled(content.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Common Actions Section
    private var commonActionsSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Common Actions")
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AtlasTheme.Spacing.sm) {
                    ForEach(commonActions, id: \.self) { action in
                        Button(action: {
                            content = action
                        }) {
                            Text(action)
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.text)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AtlasTheme.Spacing.md)
                                .padding(.vertical, AtlasTheme.Spacing.sm)
                                .background(AtlasTheme.Colors.cardBackground.opacity(0.3))
                                .cornerRadius(AtlasTheme.CornerRadius.small)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Common Actions
    private var commonActions: [String] {
        [
            "Preheat oven to 350°F",
            "Heat oil in a large pan",
            "Season with salt and pepper",
            "Bring to a boil",
            "Reduce heat and simmer",
            "Mix until combined",
            "Let cool completely",
            "Garnish and serve"
        ]
    }
    
    // MARK: - Helper Methods
    private func addStep() {
        let step = RecipeStep()
        step.uuid = UUID()
        step.content = content
        step.order = Int16(steps.count)
        step.timerMinutes = Int16(timerMinutes)
        step.createdAt = Date()
        step.updatedAt = Date()
        
        steps.append(step)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AddStepView(
        steps: .constant([]),
        recipesService: RecipesService(dataManager: DataManager.shared)
    )
}


