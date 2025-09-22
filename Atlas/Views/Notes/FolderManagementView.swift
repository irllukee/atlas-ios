import SwiftUI

// MARK: - Folder Management View
struct FolderManagementView: View {
    @StateObject private var notesService = NotesService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var newFolderName = ""
    @State private var newFolderColor = "#FF6B35"
    @State private var showingNewFolder = false
    
    private let colors = [
        "#FF6B35", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
        "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Folders")
                        .font(AtlasTheme.Typography.largeTitle)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    Spacer()
                    
                    Button(action: {
                        showingNewFolder = true
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
                if notesService.folders.isEmpty {
                    emptyStateView
                } else {
                    foldersList
                }
            }
            .background(AtlasTheme.Colors.background)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingNewFolder) {
            newFolderSheet
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AtlasTheme.Spacing.lg) {
            Image(systemName: "folder")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(AtlasTheme.Colors.tertiaryText)
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                Text("No folders yet")
                    .font(AtlasTheme.Typography.title2)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("Create folders to organize your notes")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showingNewFolder = true
                AtlasTheme.Haptics.medium()
            }) {
                HStack(spacing: AtlasTheme.Spacing.sm) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                    Text("Create Folder")
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
    
    // MARK: - Folders List
    private var foldersList: some View {
        ScrollView {
            LazyVStack(spacing: AtlasTheme.Spacing.sm) {
                ForEach(notesService.folders, id: \.uuid) { folder in
                    FolderRowView(folder: folder)
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.bottom, AtlasTheme.Spacing.xl)
        }
    }
    
    // MARK: - New Folder Sheet
    private var newFolderSheet: some View {
        NavigationView {
            VStack(spacing: AtlasTheme.Spacing.lg) {
                // Folder Name
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Text("Folder Name")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    TextField("Enter folder name", text: $newFolderName)
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
                                        .stroke(newFolderColor == color ? Color.white : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    newFolderColor = color
                                    AtlasTheme.Haptics.light()
                                }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(AtlasTheme.Spacing.lg)
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createFolder()
                    }
                    .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            newFolderName = ""
            newFolderColor = "#FF6B35"
        }
    }
    
    // MARK: - Actions
    private func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        _ = notesService.createFolder(name: name, color: newFolderColor)
        dismiss()
        AtlasTheme.Haptics.medium()
    }
}

// MARK: - Folder Row View
struct FolderRowView: View {
    let folder: NoteFolder
    @StateObject private var notesService = NotesService.shared
    @State private var showingEditSheet = false
    @State private var editName = ""
    @State private var editColor = ""
    
    private let colors = [
        "#FF6B35", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
        "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"
    ]
    
    var body: some View {
        HStack(spacing: AtlasTheme.Spacing.md) {
            // Folder Icon
            Image(systemName: "folder.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: folder.color ?? "#FF6B35") ?? AtlasTheme.Colors.primary)
            
            // Folder Info
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name ?? "Unnamed Folder")
                    .font(AtlasTheme.Typography.headline)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("\(folder.notes?.count ?? 0) notes")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.tertiaryText)
            }
            
            Spacer()
            
            // Actions
            Menu {
                Button("Edit") {
                    editName = folder.name ?? ""
                    editColor = folder.color ?? "#FF6B35"
                    showingEditSheet = true
                }
                
                Button("Delete", role: .destructive) {
                    deleteFolder()
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
            editFolderSheet
        }
    }
    
    private var editFolderSheet: some View {
        NavigationView {
            VStack(spacing: AtlasTheme.Spacing.lg) {
                // Folder Name
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Text("Folder Name")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    TextField("Enter folder name", text: $editName)
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
            .navigationTitle("Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingEditSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateFolder()
                    }
                    .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func updateFolder() {
        let name = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        notesService.updateFolder(folder, name: name, color: editColor)
        showingEditSheet = false
        AtlasTheme.Haptics.medium()
    }
    
    private func deleteFolder() {
        notesService.deleteFolder(folder)
        AtlasTheme.Haptics.medium()
    }
}

// MARK: - Preview
#Preview {
    FolderManagementView()
}
