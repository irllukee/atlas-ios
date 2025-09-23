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
    @State private var showStyleFor: Node?
    @State private var appeared = false
    @State private var haptics = UIImpactFeedbackGenerator(style: .soft)
    @State private var cameraOffsetForParallax: CGSize = .zero
    @State private var showSearch: Bool = true
    @State private var showingMenu = false
    @State private var searchText = ""
    @State private var isSearchFocused = false

    var body: some View {
        ZStack {
            // Space background
            SpaceBackgroundView()
            
            // Glass overlay for depth
            GlassBackgroundView(parallaxOffset: cameraOffsetForParallax)
            
            VStack(spacing: 0) {
                header

                RadialMindMap(
                    center: node,
                    children: Array(node.children as? Set<Node> ?? []),
                    onFocusChild: { _ in 
                        haptics.impactOccurred() 
                    },
                    onEditNote: { selectedNode in 
                        selectedForEdit = selectedNode 
                    },
                    onRename: { selectedNode in 
                        renameText = selectedNode.title ?? ""
                        showingRename = true 
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
            
            // Floating Search Bar
            VStack {
                Spacer()
                if showSearch {
                    modernSearchBar
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedForEdit) { selectedNode in
            NoteEditor(node: selectedNode)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $showStyleFor) { selectedNode in
            IconColorPicker(node: selectedNode)
                .presentationDetents([.fraction(0.55), .large])
        }
        .alert("Rename", isPresented: $showingRename) {
            TextField("Title", text: $renameText)
            Button("Save") {
                let trimmedTitle = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedTitle.isEmpty { 
                    node.title = trimmedTitle 
                }
                do {
                    try viewContext.save()
                } catch {
                    print("Failed to save rename: \(error)")
                }
            }
            Button("Cancel", role: .cancel) { }
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

    // MARK: - Modern Search Bar
    private var modernSearchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 16))
                
                TextField("Search nodes...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .onTapGesture {
                        isSearchFocused = true
                    }
                    .onSubmit {
                        isSearchFocused = false
                        // Handle search
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button(action: { 
                        searchText = ""
                        isSearchFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(AtlasTheme.Colors.primary.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                isSearchFocused ? AtlasTheme.Colors.primary : Color.clear, 
                                lineWidth: 2
                            )
                    )
            )
            
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
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40) // Safe area padding
        .padding(.top, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AtlasTheme.Colors.background.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal, 16)
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
                        renameText = node.title ?? ""
                        showingRename = true
                    })
                    
                    menuItem(icon: "note.text", title: "Edit Note", action: { 
                        showingMenu = false
                        selectedForEdit = node
                    })
                    
                    menuItem(icon: "paintpalette", title: "Style Node", action: { 
                        showingMenu = false
                        showStyleFor = node
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
    
    private func performSearch() {
        // Implement search functionality
        print("Searching for: \(searchText)")
    }
    
    private func reorganizeNodes() {
        // Trigger a layout recalculation with haptic feedback
        withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
            // This will cause the RadialMindMap to recalculate layout
            // due to the onChange modifier watching children.count
            // We can trigger it by temporarily modifying then restoring a property
            let originalTitle = node.title ?? ""
            node.title = originalTitle + " " // Tiny change
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                node.title = originalTitle // Restore
                haptics.impactOccurred(intensity: 0.7)
            }
        }
    }
}
