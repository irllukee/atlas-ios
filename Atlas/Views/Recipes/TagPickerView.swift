import SwiftUI

struct TagPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTags: [RecipeTag]
    @ObservedObject var recipesService: RecipesService
    
    @State private var allTags: [RecipeTag] = []
    @State private var newTagName = ""
    @State private var showingAddTag = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Quick Add Tag
                    quickAddTagSection
                    
                    // Tags List
                    tagsListSection
                }
            }
            .navigationTitle("Select Tags")
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
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
                }
            }
        }
        .onAppear {
            loadTags()
        }
        .alert("Add New Tag", isPresented: $showingAddTag) {
            TextField("Tag name", text: $newTagName)
            Button("Cancel", role: .cancel) {
                newTagName = ""
            }
            Button("Add") {
                addNewTag()
            }
            .disabled(newTagName.isEmpty)
        }
    }
    
    // MARK: - Quick Add Tag Section
    private var quickAddTagSection: some View {
        FrostedCard(style: .compact) {
            HStack {
                TextField("Create new tag...", text: $newTagName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AtlasTheme.Typography.body)
                
                Button(action: {
                    if !newTagName.isEmpty {
                        addNewTag()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.primary)
                }
                .disabled(newTagName.isEmpty)
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.top, AtlasTheme.Spacing.md)
    }
    
    // MARK: - Tags List Section
    private var tagsListSection: some View {
        ScrollView {
            LazyVStack(spacing: AtlasTheme.Spacing.sm) {
                ForEach(allTags, id: \.uuid) { tag in
                    TagRow(
                        tag: tag,
                        isSelected: selectedTags.contains { $0.uuid == tag.uuid },
                        onToggle: {
                            toggleTag(tag)
                        }
                    )
                }
                
                if allTags.isEmpty {
                    emptyStateView
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.lg)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: AtlasTheme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "tag")
                .font(.system(size: 60))
                .foregroundColor(AtlasTheme.Colors.primary)
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                Text("No Tags Created")
                    .font(AtlasTheme.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("Create your first tag above")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, AtlasTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    private func loadTags() {
        allTags = recipesService.fetchTags()
    }
    
    private func addNewTag() {
        let newTag = recipesService.createTag(name: newTagName.trimmingCharacters(in: .whitespacesAndNewlines))
        allTags.append(newTag)
        newTagName = ""
    }
    
    private func toggleTag(_ tag: RecipeTag) {
        if let index = selectedTags.firstIndex(where: { $0.uuid == tag.uuid }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

struct TagRow: View {
    let tag: RecipeTag
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            FrostedCard(style: .compact) {
                HStack {
                    HStack(spacing: AtlasTheme.Spacing.sm) {
                        Circle()
                            .fill(Color(tag.color ?? "#007AFF"))
                            .frame(width: 12, height: 12)
                        
                        Text(tag.name ?? "Unknown Tag")
                            .font(AtlasTheme.Typography.body)
                            .foregroundColor(AtlasTheme.Colors.text)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let dataManager = DataManager.shared
    let recipesService = RecipesService(dataManager: dataManager)
    
    TagPickerView(
        selectedTags: .constant([]),
        recipesService: recipesService
    )
}


