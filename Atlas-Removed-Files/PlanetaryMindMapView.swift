import SwiftUI
import CoreData

/// Planetary Mind Map View - 8-directional compass-based mind mapping
struct PlanetaryMindMapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Node.createdAt, ascending: true)],
        predicate: NSPredicate(format: "parent == nil"),
        animation: .default)
    private var rootNodes: FetchedResults<Node>
    
    @State private var currentNode: Node?
    @State private var showPlusSlots = false
    @State private var nodeCounter = 1
    @State private var allNodes: [UUID: Node] = [:]
    @State private var navigationPath = NavigationPath()
    
    let dataManager: DataManager
    
    // Color scheme for different levels
    private let levelColors = [
        "#FFD700", // Gold for root
        "#FF6B6B", // Red for level 1
        "#4ECDC4", // Teal for level 2
        "#45B7D1", // Blue for level 3
        "#96CEB4", // Green for level 4
        "#FFEAA7", // Yellow for level 5
        "#DDA0DD", // Plum for level 6
        "#98D8C8"  // Mint for level 7
    ]
    
    // 8 compass directions for + slots
    private let directions = [
        CompassDirection(name: "N", angle: 0, x: 0, y: -120),
        CompassDirection(name: "NE", angle: 45, x: 85, y: -85),
        CompassDirection(name: "E", angle: 90, x: 120, y: 0),
        CompassDirection(name: "SE", angle: 135, x: 85, y: 85),
        CompassDirection(name: "S", angle: 180, x: 0, y: 120),
        CompassDirection(name: "SW", angle: 225, x: -85, y: 85),
        CompassDirection(name: "W", angle: 270, x: -120, y: 0),
        CompassDirection(name: "NW", angle: 315, x: -85, y: -85)
    ]
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Glass background with parallax effects
                GlassBackgroundView(parallaxOffset: .zero)
                
                GeometryReader { geo in
                    let centerX = geo.size.width / 2
                    let centerY = geo.size.height / 2
                    
                    ZStack {
                        // Connecting lines
                        connectingLinesView(centerX: centerX, centerY: centerY)
                        
                        // Central Node
                        if let current = currentNode {
                            centralNodeView(node: current, centerX: centerX, centerY: centerY)
                        }
                        
                        // Child Nodes
                        childNodesView(centerX: centerX, centerY: centerY)
                        
                        // Plus Slots
                        if showPlusSlots {
                            plusSlotsView(centerX: centerX, centerY: centerY)
                        }
                    }
                }
                
                // Navigation Info
                navigationInfoView
                
                // Instructions
                instructionsView
            }
            .navigationBarHidden(true)
            .onAppear {
                initializeNodes()
            }
        }
    }
    
    
    // MARK: - Connecting Lines
    private func connectingLinesView(centerX: CGFloat, centerY: CGFloat) -> some View {
        Canvas { context, size in
            guard let current = currentNode else { return }
            
            let children = current.childrenArray
            
            for child in children {
                if let direction = directions.first(where: { $0.name == child.direction }) {
                    let childX = centerX + direction.x
                    let childY = centerY + direction.y
                    
                    // Create curved orbital path
                    let midX = centerX + direction.x * 0.5
                    let midY = centerY + direction.y * 0.5
                    let controlX = midX + (direction.y > 0 ? -20 : 20)
                    let controlY = midY + (direction.x > 0 ? 20 : -20)
                    
                    var path = Path()
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    path.addQuadCurve(
                        to: CGPoint(x: childX, y: childY),
                        control: CGPoint(x: controlX, y: controlY)
                    )
                    
                    context.stroke(
                        path,
                        with: .color(.white.opacity(0.6)),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5])
                    )
                }
            }
        }
    }
    
    // MARK: - Central Node
    private func centralNodeView(node: Node, centerX: CGFloat, centerY: CGFloat) -> some View {
        Button {
            handleCenterNodeClick()
        } label: {
            ZStack {
                // Glow effect
                Circle()
                    .fill(Color(hex: levelColors[Int(node.level) % levelColors.count]) ?? .blue)
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                    .opacity(0.6)
                
                // Main node
                Circle()
                    .fill(Color(hex: levelColors[Int(node.level) % levelColors.count]) ?? .blue)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Text
                Text(node.title ?? "Central")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 8)
            }
        }
        .scaleEffect(showPlusSlots ? 1.1 : 1.0)
        .animation(.spring(duration: 0.3), value: showPlusSlots)
        .position(x: centerX, y: centerY)
    }
    
    // MARK: - Child Nodes
    private func childNodesView(centerX: CGFloat, centerY: CGFloat) -> some View {
        ForEach(currentNode?.childrenArray ?? [], id: \.uuid) { child in
            if let direction = directions.first(where: { $0.name == child.direction }) {
                Button {
                    handleChildNodeClick(child)
                } label: {
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(Color(hex: levelColors[Int(child.level) % levelColors.count]) ?? .blue)
                            .frame(width: 70, height: 70)
                            .blur(radius: 15)
                            .opacity(0.5)
                        
                        // Main node
                        Circle()
                            .fill(Color(hex: levelColors[Int(child.level) % levelColors.count]) ?? .blue)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.3), lineWidth: 3)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        // Text
                        Text(child.title?.components(separatedBy: " ").last ?? "Node")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .scaleEffect(1.0)
                .animation(.spring(duration: 0.3), value: showPlusSlots)
                .position(
                    x: centerX + direction.x,
                    y: centerY + direction.y
                )
            }
        }
    }
    
    // MARK: - Plus Slots
    private func plusSlotsView(centerX: CGFloat, centerY: CGFloat) -> some View {
        ForEach(directions, id: \.name) { direction in
            // Only show + slot if no child exists in this direction
            let hasChild = currentNode?.hasChildInDirection(direction.name) ?? false
            
            if !hasChild {
                Button {
                    handlePlusSlotClick(direction)
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.6), lineWidth: 2)
                            )
                            .background(.ultraThinMaterial, in: Circle())
                        
                        Text("+")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(1.0)
                .animation(.spring(duration: 0.3).repeatForever(autoreverses: true), value: showPlusSlots)
                .position(
                    x: centerX + direction.x,
                    y: centerY + direction.y
                )
            }
        }
    }
    
    // MARK: - Navigation Info
    private var navigationInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let current = currentNode {
                Text("Level: \(current.level)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Node: \(current.title ?? "Untitled")")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                if current.parent != nil {
                    Text("Tap center to go back")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                } else if !showPlusSlots {
                    Text("Tap center to expand")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 50)
        .padding(.leading, 20)
    }
    
    // MARK: - Instructions
    private var instructionsView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("• Tap center node to show/hide + slots")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            
            Text("• Tap + slots to create child nodes")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            
            Text("• Tap child nodes to zoom in")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            
            Text("• Tap center when expanded to go back")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.bottom, 50)
        .padding(.trailing, 20)
    }
    
    // MARK: - Actions
    private func handleCenterNodeClick() {
        if showPlusSlots {
            // If plus slots are showing, navigate back to parent
            if let parent = currentNode?.parent {
                currentNode = parent
                showPlusSlots = false
            } else {
                // If at root level, just hide plus slots
                showPlusSlots = false
            }
        } else {
            // Show plus slots
            showPlusSlots = true
        }
    }
    
    private func handlePlusSlotClick(_ direction: CompassDirection) {
        guard let current = currentNode else { return }
        
        let child = Node.create(
            context: viewContext,
            title: "Node \(nodeCounter)",
            parent: current,
            direction: direction.name,
            level: current.level + 1
        )
        
        do {
            try viewContext.save()
            nodeCounter += 1
            showPlusSlots = false
        } catch {
            print("Failed to add child: \(error)")
        }
    }
    
    private func handleChildNodeClick(_ child: Node) {
        currentNode = child
        showPlusSlots = false
    }
    
    private func initializeNodes() {
        if let root = rootNodes.first {
            currentNode = root
        } else {
            // Create root node if none exists
            let root = Node.create(
                context: viewContext,
                title: "Central Idea",
                parent: nil,
                direction: nil,
                level: 0
            )
            
            do {
                try viewContext.save()
                currentNode = root
            } catch {
                print("Failed to create root node: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types
private struct CompassDirection {
    let name: String
    let angle: Double
    let x: CGFloat
    let y: CGFloat
}


// MARK: - Preview
#Preview {
    PlanetaryMindMapView(dataManager: DataManager.shared)
        .environment(\.managedObjectContext, DataManager.shared.coreDataStack.viewContext)
}
