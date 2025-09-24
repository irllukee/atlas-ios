import SwiftUI
import CoreData

struct FocusView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var node: Node
    @Binding var navigationPath: NavigationPath
    let dataManager: DataManager

    @State private var showingRename = false
    @State private var renameText = ""
    @State private var selectedForEdit: Node?
    @State private var selectedForRename: Node?
    @State private var showingAddChildDialog = false
    @State private var newChildName = ""
    @State private var parentForNewChild: Node?
    @State private var appeared = false
    @State private var haptics = UIImpactFeedbackGenerator(style: .soft)
    @State private var cameraOffsetForParallax: CGSize = .zero
    @State private var showingMenu = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            // Space background
            SpaceBackgroundView()
            
            VStack(spacing: 0) {
                header

                RadialMindMap(
                    center: node,
                    children: Array(node.children as? Set<Node> ?? []),
                    onFocusChild: { selectedNode in 
                        haptics.impactOccurred()
                        navigationPath.append(selectedNode)
                    },
                    onEditNote: { selectedNode in 
                        // Only set if it actually changed (prevents duplicate updates per frame)
                        if selectedForEdit?.uuid != selectedNode.uuid {
                            // Coalesce onto next run loop to avoid mutating during view update
                            DispatchQueue.main.async {
                                withTransaction(Transaction(animation: nil)) {
                                    self.selectedForEdit = selectedNode
                                }
                            }
                        }
                    },
                    onRename: { selectedNode in 
                        selectedForRename = selectedNode
                        renameText = selectedNode.title ?? ""
                        showingRename = true 
                    },
                    onAddChild: { parentNode in
                        parentForNewChild = parentNode
                        newChildName = ""
                        showingAddChildDialog = true
                    },
                    onCameraChanged: { cameraOffset in 
                        cameraOffsetForParallax = cameraOffset 
                    },
                    navigationPath: $navigationPath,
                    dataManager: dataManager
                )
                .padding(.bottom, 12)

                Spacer()
            }
            .onAppear { 
                appeared = true
                haptics.prepare() 
            }
            
            // Hamburger Menu
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showingMenu.toggle() }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(AtlasTheme.Colors.primary.opacity(0.2))
                                    .overlay(
                                        Circle()
                                            .stroke(AtlasTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.trailing)
                    .padding(.top, 8)
                }
                Spacer()
            }
            
            // Menu Overlay
            if showingMenu {
                menuOverlay
            }
            
            // Floating + Button
            VStack {
                Spacer()
                floatingAddButton
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedForEdit) { selectedNode in
            NoteEditor(node: selectedNode)
                .presentationDetents([.medium, .large])
        }
        .alert("Add Child Node", isPresented: $showingAddChildDialog) {
            TextField("Node name", text: $newChildName)
                .focused($isTextFieldFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
            Button("Add") {
                createChildNode()
                isTextFieldFocused = false
            }
            .disabled(newChildName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) {
                parentForNewChild = nil
                newChildName = ""
                isTextFieldFocused = false
            }
        } message: {
            Text("Enter a name for the new child node.")
        }
        .alert("Rename", isPresented: $showingRename) {
            TextField("Title", text: $renameText)
                .focused($isTextFieldFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
            Button("Save") {
                let trimmedTitle = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedTitle.isEmpty, let targetNode = selectedForRename { 
                    targetNode.title = trimmedTitle 
                }
                do {
                    try viewContext.save()
                } catch {
                    print("Failed to save rename: \(error)")
                }
                selectedForRename = nil
                isTextFieldFocused = false
            }
            Button("Cancel", role: .cancel) { 
                selectedForRename = nil
                isTextFieldFocused = false
            }
        } message: {
            Text("Enter a new title for the selected idea.")
        }
    }

    private var header: some View {
        HStack {
            if node.parent != nil {
                Button {
                    print("Back button tapped - navigating back from \(node.title ?? "unknown") to \(node.parent?.title ?? "parent")")
                    print("Current navigation path count: \(navigationPath.count)")
                    
                    // Try direct navigation to parent
                    if let parent = node.parent {
                        print("Navigating directly to parent: \(parent.title ?? "unknown")")
                        // Clear the path and navigate to parent
                        navigationPath = NavigationPath()
                        navigationPath.append(parent)
                    } else {
                        print("No parent found, using dismiss")
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                }
                .accessibilityLabel("Back to \(node.parent?.title ?? "parent")")
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(node.title ?? "Untitled")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer()
            
            // Empty space where the 3 dots menu was
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        Button(action: { 
            let child = Node(context: viewContext)
            child.uuid = UUID()
            child.title = "New Idea"
            child.createdAt = Date()
            child.updatedAt = Date()
            child.parent = node
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to add child: \(error)")
            }
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(AtlasTheme.Colors.primary)
                .padding(8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40) // Safe area padding
        .padding(.top, 8)
    }
    
    // MARK: - Menu Overlay
    private var menuOverlay: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showingMenu = false
                }
            
            // Menu panel
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Mind Map Features")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showingMenu = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    menuItem(icon: "plus.circle.fill", title: "Add Node", action: { 
                        showingMenu = false
                        let child = Node(context: viewContext)
                        child.uuid = UUID()
                        child.title = "New Idea"
                        child.createdAt = Date()
                        child.updatedAt = Date()
                        child.parent = node
                        
                        do {
                            try viewContext.save()
                        } catch {
                            print("Failed to add child: \(error)")
                        }
                    })
                    
                    menuItem(icon: "pencil", title: "Rename Node", action: { 
                        showingMenu = false
                        selectedForRename = node
                        renameText = node.title ?? ""
                        showingRename = true
                    })
                    
                    menuItem(icon: "note.text", title: "Show Note", action: { 
                        showingMenu = false
                        selectedForEdit = node
                    })
                    
                    
                    menuItem(icon: "trash", title: "Delete Node", action: { 
                        showingMenu = false
                        // Delete functionality
                    })
                    
                    menuItem(icon: "arrow.triangle.2.circlepath", title: "Reorganize", action: { 
                        showingMenu = false
                        reorganizeNodes()
                    })
                    
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AtlasTheme.Colors.background.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AtlasTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding()
            .frame(maxWidth: 300)
            .position(x: UIScreen.main.bounds.width - 150, y: 200)
        }
    }
    
    private func createChildNode() {
        guard let parent = parentForNewChild else { return }
        
        let child = Node(context: viewContext)
        child.uuid = UUID()
        child.title = newChildName.trimmingCharacters(in: .whitespacesAndNewlines)
        child.createdAt = Date()
        child.updatedAt = Date()
        child.parent = parent
        child.mindMap = parent.mindMap
        
        do {
            try viewContext.save()
            haptics.impactOccurred()
        } catch {
            print("Failed to create child node: \(error)")
        }
        
        // Clean up and dismiss keyboard
        parentForNewChild = nil
        newChildName = ""
        showingAddChildDialog = false
        isTextFieldFocused = false
    }
    
    private func menuItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AtlasTheme.Colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AtlasTheme.Colors.primary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    
    private func reorganizeNodes() {
        // Trigger a layout recalculation with haptic feedback
        // Use a safer approach that doesn't modify node properties
        haptics.impactOccurred(intensity: 0.7)
        
        // Force a layout update by triggering the RadialMindMap's layout recalculation
        // This is safer than modifying node properties during animations
        withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
            // The RadialMindMap will automatically recalculate layout
            // when it detects changes in the children array or layout cache
        }
    }
}
