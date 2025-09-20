import SwiftUI
import CoreData

struct FocusView: View {
    @Environment(\.managedObjectContext) private var viewContext
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

    var body: some View {
        ZStack {
            GlassBackgroundView(parallaxOffset: cameraOffsetForParallax)
            
            VStack(spacing: 0) {
                header
                
                if showSearch {
                    SearchOverlay { jumpToNode in
                        // Navigate to the selected node
                        navigationPath.append(jumpToNode)
                    }
                    .transition(.opacity)
                }

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

                toolbar
            }
            .onAppear { 
                appeared = true
                haptics.prepare() 
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
                    navigationPath.removeLast()
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
            
            Menu {
                Button("Rename", systemImage: "pencil") {
                    renameText = node.title ?? ""
                    showingRename = true
                }
                Button("Edit Note", systemImage: "note.text") {
                    selectedForEdit = node
                }
                Button("Style…", systemImage: "paintpalette") {
                    showStyleFor = node
                }
                Divider()
                Toggle(isOn: $showSearch.animation(.easeInOut(duration: 0.2))) { 
                    Label("Show Search", systemImage: "magnifyingglass") 
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.white)
                    .imageScale(.large)
                    .accessibilityLabel("More options")
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                let child = Node(context: viewContext)
                child.uuid = UUID()
                child.title = "New Idea"
                child.createdAt = Date()
                child.parent = node
                
                do {
                    try viewContext.save()
                } catch {
                    print("Failed to add child: \(error)")
                }
            } label: { 
                Label("Add Child", systemImage: "plus.circle.fill") 
            }
            .buttonStyle(.borderedProminent)

            Button {
                selectedForEdit = node
            } label: { 
                Label("Edit Note", systemImage: "note.text") 
            }
            .buttonStyle(.bordered)

            Button {
                showStyleFor = node
            } label: { 
                Label("Style…", systemImage: "paintpalette") 
            }
            .buttonStyle(.bordered)
            
            if let children = node.children, children.count > 0 {
                Button {
                    reorganizeNodes()
                } label: {
                    Label("Reorganize", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
        .accessibilityElement(children: .contain)
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
