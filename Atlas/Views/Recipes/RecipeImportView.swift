import SwiftUI

struct RecipeImportView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var recipesService: RecipesService
    @StateObject private var importService: RecipeImportService
    
    @State private var importMethod: ImportMethod = .url
    @State private var urlText = ""
    @State private var manualText = ""
    @State private var sourceURL = ""
    @State private var isImporting = false
    @State private var importResult: RecipeImportResult?
    @State private var showingResult = false
    
    enum ImportMethod: String, CaseIterable {
        case url = "URL"
        case manual = "Manual Text"
    }
    
    init(recipesService: RecipesService) {
        self.recipesService = recipesService
        self._importService = StateObject(wrappedValue: RecipeImportService(recipesService: recipesService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AtlasTheme.Spacing.lg) {
                        // Import Method Selection
                        importMethodSection
                        
                        // Import Content Section
                        importContentSection
                        
                        // Import Button
                        importButtonSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    .padding(.top, AtlasTheme.Spacing.md)
                }
            }
            .navigationTitle("Import Recipe")
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
        .alert("Import Result", isPresented: $showingResult) {
            if let result = importResult {
                if result.isSuccess {
                    Button("OK") {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    Button("OK") { }
                }
            }
        } message: {
            if let result = importResult {
                if result.isSuccess {
                    Text("Recipe imported successfully!")
                } else {
                    Text(result.errorMessage ?? "Unknown error occurred")
                }
            }
        }
    }
    
    // MARK: - Import Method Section
    private var importMethodSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Import Method")
                
                Picker("Import Method", selection: $importMethod) {
                    ForEach(ImportMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
    
    // MARK: - Import Content Section
    private var importContentSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: importMethod == .url ? "Recipe URL" : "Recipe Text")
                
                VStack(spacing: AtlasTheme.Spacing.md) {
                    if importMethod == .url {
                        // URL Import
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                            Text("Recipe URL")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            
                            TextField("https://example.com/recipe", text: $urlText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(AtlasTheme.Typography.body)
                                .padding(AtlasTheme.Spacing.md)
                                .background(AtlasTheme.Colors.glassBackground.opacity(0.3))
                                .cornerRadius(AtlasTheme.CornerRadius.small)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                            Text("Source URL (Optional)")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            
                            TextField("https://example.com", text: $sourceURL)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(AtlasTheme.Typography.body)
                                .padding(AtlasTheme.Spacing.md)
                                .background(AtlasTheme.Colors.glassBackground.opacity(0.3))
                                .cornerRadius(AtlasTheme.CornerRadius.small)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // URL Import Info
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                            Text("Supported Sites")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            
                            Text("• Most recipe websites with structured data\n• Allrecipes, Food Network, BBC Good Food\n• Any site with Recipe JSON-LD or microdata")
                                .font(AtlasTheme.Typography.caption2)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                        }
                        .padding(AtlasTheme.Spacing.md)
                        .background(AtlasTheme.Colors.primary.opacity(0.1))
                        .cornerRadius(AtlasTheme.CornerRadius.small)
                        
                    } else {
                        // Manual Text Import
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                            Text("Recipe Text")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            
                            TextEditor(text: $manualText)
                                .frame(minHeight: 200)
                                .padding(AtlasTheme.Spacing.sm)
                                .background(AtlasTheme.Colors.glassBackground.opacity(0.3))
                                .cornerRadius(AtlasTheme.CornerRadius.small)
                        }
                        
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                            Text("Source URL (Optional)")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            
                            TextField("https://example.com", text: $sourceURL)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(AtlasTheme.Typography.body)
                                .padding(AtlasTheme.Spacing.md)
                                .background(AtlasTheme.Colors.glassBackground.opacity(0.3))
                                .cornerRadius(AtlasTheme.CornerRadius.small)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Manual Import Info
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                            Text("Format Guidelines")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            
                            Text("• First line will be used as recipe title\n• Look for 'Ingredients' and 'Instructions' sections\n• Timing info like 'Prep: 15 min' will be parsed\n• Serving info like 'Serves 4' will be detected")
                                .font(AtlasTheme.Typography.caption2)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                        }
                        .padding(AtlasTheme.Spacing.md)
                        .background(AtlasTheme.Colors.primary.opacity(0.1))
                        .cornerRadius(AtlasTheme.CornerRadius.small)
                    }
                }
            }
        }
    }
    
    // MARK: - Import Button Section
    private var importButtonSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Import Recipe")
                
                Button(action: {
                    importRecipe()
                }) {
                    HStack {
                        if isImporting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title2)
                        }
                        
                        Text(isImporting ? "Importing..." : "Import Recipe")
                            .font(AtlasTheme.Typography.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AtlasTheme.Spacing.md)
                    .background(canImport ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)
                    .cornerRadius(AtlasTheme.CornerRadius.medium)
                }
                .disabled(!canImport || isImporting)
                
                if isImporting {
                    Text("Parsing recipe data...")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canImport: Bool {
        if importMethod == .url {
            return !urlText.isEmpty && URL(string: urlText) != nil
        } else {
            return !manualText.isEmpty
        }
    }
    
    // MARK: - Helper Methods
    private func importRecipe() {
        isImporting = true
        
        Task { @MainActor in
            let result: RecipeImportResult
            
            if importMethod == .url {
                result = await importService.importRecipeFromURL(urlText)
            } else {
                result = importService.importRecipeFromText(manualText, sourceURL: sourceURL.isEmpty ? nil : sourceURL)
            }
            
            await MainActor.run {
                self.importResult = result
                self.isImporting = false
                self.showingResult = true
            }
        }
    }
}

// MARK: - Import Preview
struct RecipeImportPreview: View {
    let text: String
    
    var body: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Import Preview")
                
                Text(text)
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    RecipeImportView(recipesService: RecipesService(dataManager: DataManager.shared))
}


