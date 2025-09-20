import SwiftUI
import CoreData

/// Main Mind Mapping View - converted from SwiftData to CoreData
struct MindMappingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Node.createdAt, ascending: true)],
        predicate: NSPredicate(format: "parent == nil"),
        animation: .default)
    private var rootNodes: FetchedResults<Node>
    
    @State private var navigationPath = NavigationPath()
    
    let dataManager: DataManager
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let root = rootNodes.first {
                    FocusView(node: root, navigationPath: $navigationPath, dataManager: dataManager)
                } else {
                    VStack(spacing: 16) {
                        Text("Mind Map")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Create your first root idea.")
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Button {
                            createRootNode()
                        } label: {
                            Label("Create Root", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationDestination(for: Node.self) { node in
                FocusView(node: node, navigationPath: $navigationPath, dataManager: dataManager)
            }
        }
        .background(AtlasTheme.Colors.background.ignoresSafeArea())
    }
    
    private func createRootNode() {
        let root = Node(context: viewContext)
        root.uuid = UUID()
        root.title = "My Ideas"
        root.createdAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save root node: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    MindMappingView(dataManager: DataManager.shared)
        .environment(\.managedObjectContext, DataManager.shared.coreDataStack.viewContext)
}
