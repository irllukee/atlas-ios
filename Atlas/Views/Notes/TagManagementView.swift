import SwiftUI

// MARK: - Tag Management View
struct TagManagementView: View {
    @EnvironmentObject private var notesService: NotesService
    @Environment(\.dismiss) private var dismiss
    
    @State private var newTagName = ""
    @State private var newTagColor = "#FF6B35"
    @State private var showingNewTag = false
    
    private let colors = [
        "#FF6B35", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
        "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Tags")
                        .font(AtlasTheme.Typography.largeTitle)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    Spacer()
                    
                    Button(action: {
                        showingNewTag = true
                        AtlasTheme.Haptics.light()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AtlasTheme.Colors.text)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(AtlasTheme.Colors.primary)
                            )
                    }
                }
                .padding(.horizontal, AtlasTheme.Spacing.md)
                .padding(.top, AtlasTheme.Spacing.sm)
                
                // Content
                if notesService.tags.isEmpty {
                    emptyStateView
                } else {
                    tagsList
                }
            }
            .background(AtlasTheme.Colors.background)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingNewTag) {
            newTagSheet
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AtlasTheme.Spacing.lg) {
            Image(systemName: "tag")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(AtlasTheme.Colors.tertiaryText)
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                Text("No tags yet")
                    .font(AtlasTheme.Typography.title2)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("Create tags to categorize your notes")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showingNewTag = true
                AtlasTheme.Haptics.medium()
            }) {
                HStack(spacing: AtlasTheme.Spacing.sm) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                    Text("Create Tag")
                        .font(AtlasTheme.Typography.button)
                }
                .foregroundColor(AtlasTheme.Colors.text)
                .padding(.horizontal, AtlasTheme.Spacing.lg)
                .padding(.vertical, AtlasTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                        .fill(AtlasTheme.Colors.primary)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AtlasTheme.Spacing.xl)
    }
    
    // MARK: - Tags List
    private var tagsList: some View {
        ScrollView {
            LazyVStack(spacing: AtlasTheme.Spacing.sm) {
                ForEach(notesService.tags, id: \.uuid) { tag in
                    TagRowView(tag: tag)
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.bottom, AtlasTheme.Spacing.xl)
        }
    }
    
    // MARK: - New Tag Sheet
    private var newTagSheet: some View {
        NavigationView {
            VStack(spacing: AtlasTheme.Spacing.lg) {
                // Tag Name
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Text("Tag Name")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    TextField("Enter tag name", text: $newTagName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(AtlasTheme.Typography.body)
                }
                
                // Color Selection
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Text("Color")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color) ?? AtlasTheme.Colors.primary)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(newTagColor == color ? Color.white : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    newTagColor = color
                                    AtlasTheme.Haptics.light()
                                }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(AtlasTheme.Spacing.lg)
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTag()
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            newTagName = ""
            newTagColor = "#FF6B35"
        }
    }
    
    // MARK: - Actions
    private func createTag() {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        _ = notesService.createTag(name: name, color: newTagColor)
        dismiss()
        AtlasTheme.Haptics.medium()
    }
}

// MARK: - Tag Row View
struct TagRowView: View {
    let tag: NoteTag
    @EnvironmentObject private var notesService: NotesService
    @State private var showingEditSheet = false
    @State private var editName = ""
    @State private var editColor = ""
    
    private let colors = [
        "#FF6B35", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
        "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"
    ]
    
    var body: some View {
        HStack(spacing: AtlasTheme.Spacing.md) {
            // Tag Icon
            Image(systemName: "tag.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: tag.color ?? "#FF6B35") ?? AtlasTheme.Colors.primary)
            
            // Tag Info
            VStack(alignment: .leading, spacing: 4) {
                Text(tag.name ?? "Unnamed Tag")
                    .font(AtlasTheme.Typography.headline)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("\(tag.notes?.count ?? 0) notes")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.tertiaryText)
            }
            
            Spacer()
            
            // Actions
            Menu {
                Button("Edit") {
                    editName = tag.name ?? ""
                    editColor = tag.color ?? "#FF6B35"
                    showingEditSheet = true
                }
                
                Button("Delete", role: .destructive) {
                    deleteTag()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AtlasTheme.Colors.tertiaryText)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(AtlasTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                .fill(AtlasTheme.Colors.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
        )
        .sheet(isPresented: $showingEditSheet) {
            editTagSheet
        }
    }
    
    private var editTagSheet: some View {
        NavigationView {
            VStack(spacing: AtlasTheme.Spacing.lg) {
                // Tag Name
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Text("Tag Name")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    TextField("Enter tag name", text: $editName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(AtlasTheme.Typography.body)
                }
                
                // Color Selection
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Text("Color")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color) ?? AtlasTheme.Colors.primary)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(editColor == color ? Color.white : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    editColor = color
                                    AtlasTheme.Haptics.light()
                                }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(AtlasTheme.Spacing.lg)
            .navigationTitle("Edit Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingEditSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateTag()
                    }
                    .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func updateTag() {
        let name = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        notesService.updateTag(tag, name: name, color: editColor)
        showingEditSheet = false
        AtlasTheme.Haptics.medium()
    }
    
    private func deleteTag() {
        notesService.deleteTag(tag)
        AtlasTheme.Haptics.medium()
    }
}

// MARK: - Preview
#Preview {
    TagManagementView()
}
