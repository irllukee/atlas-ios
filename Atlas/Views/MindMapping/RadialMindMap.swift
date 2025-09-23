import SwiftUI
import CoreData
import UniformTypeIdentifiers

private struct RingLayout {
    struct ItemPos: Hashable {
        let id: UUID
        let center: CGPoint
        let size: CGFloat
    }
    var items: [ItemPos] = []
    var ringRadii: [CGFloat] = []
    var contentBounds: CGRect = .zero
}

struct RadialMindMap: View {
    @Environment(\.managedObjectContext) private var viewContext

    var center: Node
    var children: [Node]
    var onFocusChild: (Node) -> Void
    var onEditNote: (Node) -> Void
    var onRename: (Node) -> Void
    var onCameraChanged: (CGSize) -> Void
    var navigationPath: Binding<NavigationPath>
    var dataManager: DataManager

    // Camera
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    @State private var lastPanVelocity: CGSize = .zero
    @State private var isFitting = true

    @State private var layoutCache = RingLayout()
    @State private var draggingNodeID: UUID?
    @State private var dropTargetNodeID: UUID?

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                // Orbit guides using Atlas theme
                ForEach(Array(layoutCache.ringRadii.enumerated()), id: \.offset) { _, radius in
                    Circle()
                        .stroke(AtlasTheme.Colors.primary.opacity(0.18), lineWidth: 1)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(applyCamera(to: CGPoint(x: size.width/2, y: size.height/2)))
                        .blur(radius: 0.3)
                        .overlay(
                            Circle()
                                .stroke(AtlasTheme.Colors.primary.opacity(dropTargetNodeID == nil ? 0.05 : 0.12),
                                        style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [6, 14]))
                                .frame(width: radius * 2, height: radius * 2)
                                .position(applyCamera(to: CGPoint(x: size.width/2, y: size.height/2)))
                        )
                }

                // Lines removed - keeping only circular nodes

                // Center bubble
                BubbleView(
                    title: center.title ?? "Untitled",
                    hasNote: !(center.note ?? "").isEmpty,
                    isCenter: true,
                    iconName: center.iconName,
                    colorHex: center.colorHex
                )
                .frame(width: bubbleSize(for: size, isCenter: true),
                       height: bubbleSize(for: size, isCenter: true))
                .position(applyCamera(to: CGPoint(x: size.width/2, y: size.height/2)))
                .onTapGesture { 
                    print("Center node tapped: \(center.title ?? "unknown")")
                    onEditNote(center) 
                }
                .contextMenu {
                    Button("Add Child", systemImage: "plus") {
                        let newChild = addChild(to: center)
                        onFocusChild(newChild)
                        navigationPath.wrappedValue.append(newChild)
                    }
                    Button("Rename", systemImage: "pencil") { 
                        onRename(center) 
                    }
                    Button("Edit Note", systemImage: "note.text") { 
                        onEditNote(center) 
                    }
                }
                .onDrop(of: [UTType.text], isTargeted: .constant(dropTargetNodeID == center.uuid)) { providers in
                    handleDrop(on: center, providers: providers)
                }

                // Children bubbles
                ForEach(children, id: \.uuid) { child in
                    if let pos = layoutCache.items.first(where: { $0.id == child.uuid }) {
                        BubbleView(
                            title: child.title ?? "Untitled",
                            hasNote: !(child.note ?? "").isEmpty,
                            isCenter: false,
                            iconName: child.iconName,
                            colorHex: child.colorHex
                        )
                        .frame(width: pos.size, height: pos.size)
                        .position(applyCamera(to: pos.center))
                        .onTapGesture(count: 1) {
                            print("Child node tapped: \(child.title ?? "unknown")")
                            onFocusChild(child)
                            navigationPath.wrappedValue.append(child)
                        }
                        .contextMenu {
                            Button("Add Sub-idea", systemImage: "plus") {
                                let newChild = addChild(to: child)
                                onFocusChild(newChild)
                                navigationPath.wrappedValue.append(newChild)
                            }
                            Button("Rename", systemImage: "pencil") { 
                                onRename(child) 
                            }
                            Button("Edit Note", systemImage: "note.text") { 
                                onEditNote(child) 
                            }
                            Divider()
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                deleteNode(child)
                            }
                        }
                        .onDrag {
                            draggingNodeID = child.uuid
                            return NSItemProvider(object: child.uuid?.uuidString as NSString? ?? "")
                        }
                        .onDrop(of: [UTType.text],
                                isTargeted: Binding(
                                    get: { dropTargetNodeID == child.uuid },
                                    set: { target in dropTargetNodeID = target ? child.uuid : nil }
                                )) { providers in
                            handleDrop(on: child, providers: providers)
                        }
                    }
                }
            }
            .scaleEffect(scale, anchor: .center)
            .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
            .contentShape(Rectangle())
            .gesture(gestures(in: size).exclusively(before: TapGesture()))
            .onChange(of: children.count) { _, _ in
                layoutCache = computeLayout(for: size)
                if isFitting { zoomToFit(in: size) }
            }
            .onAppear {
                layoutCache = computeLayout(for: size)
                zoomToFit(in: size)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { 
                    isFitting = false 
                }
            }
            .onChange(of: size) { _, _ in 
                layoutCache = computeLayout(for: size) 
            }
            .simultaneousGesture(
                TapGesture(count: 2).onEnded { 
                    zoomToFit(in: size) 
                }
            )
            .onChange(of: offset) { _, newVal in 
                onCameraChanged(newVal) 
            }
            .onChange(of: dragOffset) { _, _ in
                onCameraChanged(CGSize(
                    width: offset.width + dragOffset.width,
                    height: offset.height + dragOffset.height
                ))
            }
        }
    }

    // MARK: - Helper Methods
    
    private func addChild(to parent: Node) -> Node {
        let child = Node(context: viewContext)
        child.uuid = UUID()
        child.title = "New Idea"
        child.createdAt = Date()
        child.updatedAt = Date()
        child.parent = parent
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to add child: \(error)")
        }
        
        return child
    }
    
    private func deleteNode(_ node: Node) {
        viewContext.delete(node)
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete node: \(error)")
        }
    }

    // MARK: Gestures / camera
    private func gestures(in size: CGSize) -> some Gesture {
        let magnify = MagnificationGesture(minimumScaleDelta: 0.01)
            .onChanged { value in
                // Much slower, more controlled zoom with larger range
                let zoomSensitivity: CGFloat = 0.15  // Even slower zoom (reduced from 0.3 to 0.15)
                let newScale = scale * (1.0 + (value - 1.0) * zoomSensitivity)
                // Much larger zoom range: 0.1 to 8.0 for extensive zoom control
                scale = min(8.0, max(0.1, newScale))
            }

        let drag = DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                // Approximate velocity using predicted end
                let velocityX = (value.predictedEndLocation.x - value.location.x) / 0.25
                let velocityY = (value.predictedEndLocation.y - value.location.y) / 0.25
                lastPanVelocity = CGSize(width: velocityX, height: velocityY)

                // Inertial deceleration
                let decay: CGFloat = 0.92
                var current = CGSize(
                    width: offset.width + value.translation.width,
                    height: offset.height + value.translation.height
                )
                var velocity = lastPanVelocity
                
                _Concurrency.Task { @MainActor in
                    for _ in 0..<40 {
                        velocity.width *= decay
                        velocity.height *= decay
                        current.width += velocity.width * 0.016
                        current.height += velocity.height * 0.016
                        offset = current
                        try? await _Concurrency.Task.sleep(nanoseconds: 16_000_000)
                    }
                }
            }

        let doubleTap = TapGesture(count: 2)
            .onEnded {
                // Reset zoom to a comfortable level
                withAnimation(.easeInOut(duration: 0.5)) {
                    scale = 1.0
                    offset = .zero
                }
            }
        
        // Use simultaneous gesture to allow both zoom and tap to work
        // Use highPriorityGesture to ensure tap gestures work properly
        return magnify.simultaneously(with: drag).simultaneously(with: doubleTap)
    }

    private func zoomToFit(in size: CGSize) {
        guard layoutCache.contentBounds.width > 0 else { return }
        let padding: CGFloat = 80
        let available = CGSize(width: size.width - padding * 2, height: size.height - padding * 2)
        let scaleX = available.width / layoutCache.contentBounds.width
        let scaleY = available.height / layoutCache.contentBounds.height
        let fitScale = max(0.6, min(1.6, min(scaleX, scaleY)))

        let centerOfContent = CGPoint(
            x: layoutCache.contentBounds.midX, 
            y: layoutCache.contentBounds.midY
        )
        let viewCenter = CGPoint(x: size.width/2, y: size.height/2)
        
        withAnimation(.spring(duration: 0.55, bounce: 0.35)) {
            scale = fitScale
            offset = CGSize(
                width: viewCenter.x - centerOfContent.x,
                height: viewCenter.y - centerOfContent.y
            )
        }
        onCameraChanged(offset)
    }

    private func applyCamera(to point: CGPoint) -> CGPoint {
        // Position is scaled/offset by parent modifiers; here we return base point.
        point
    }

    private func bubbleSize(for size: CGSize, isCenter: Bool) -> CGFloat {
        let minSide = min(size.width, size.height)
        let base = max(56, minSide * 0.16)
        return isCenter ? base : base * 0.82
    }

    // MARK: Layout - Enhanced Automatic Spacing
    private func computeLayout(for size: CGSize) -> RingLayout {
        var cache = RingLayout()
        let centerSize = bubbleSize(for: size, isCenter: true)
        let minSide = min(size.width, size.height)
        
        // Adaptive base radius based on screen size and node count
        let nodeCount = children.count
        let densityFactor = min(1.0, max(0.7, 1.0 - Double(nodeCount) * 0.02))
        let baseRadius = minSide * CGFloat(0.25 + densityFactor * 0.1)

        guard !children.isEmpty else {
            let centerBounds = CGRect(
                x: size.width/2 - centerSize/2,
                y: size.height/2 - centerSize/2,
                width: centerSize, 
                height: centerSize
            )
            cache.contentBounds = centerBounds
            cache.ringRadii = []
            return cache
        }

        // Enhanced ring capacity calculation with better spacing
        func ringCapacity(radius: CGFloat, bubbleSize: CGFloat) -> Int {
            let circumference = 2 * .pi * radius
            let minSpacing = bubbleSize * 1.2 // Minimum spacing between bubbles
            let maxNodes = Int(circumference / minSpacing)
            return max(4, min(maxNodes, 12)) // Cap at reasonable limits
        }
        
        // Calculate optimal bubble sizes for each ring
        func bubbleSizeForRing(_ ringIndex: Int) -> CGFloat {
            let baseBubbleSize = bubbleSize(for: size, isCenter: false)
            let scaleFactor = pow(0.95, CGFloat(ringIndex)) // Gradual size reduction
            return baseBubbleSize * scaleFactor
        }
        
        // Calculate optimal radius for each ring with better spacing
        func radiusForRing(_ ringIndex: Int, previousRadius: CGFloat) -> CGFloat {
            let bubbleSize = bubbleSizeForRing(ringIndex)
            let minSpacing = bubbleSize * 0.8 + 20 // Minimum gap between rings
            let adaptiveSpacing = max(minSpacing, bubbleSize * 1.5)
            
            if ringIndex == 0 {
                return max(baseRadius, centerSize/2 + bubbleSize/2 + 20)
            } else {
                return previousRadius + adaptiveSpacing
            }
        }

        var remaining = children.sorted { a, b in
            // Sort by creation date for consistent positioning
            (a.createdAt ?? Date.distantPast) < (b.createdAt ?? Date.distantPast)
        }
        
        var ringIndex = 0
        var items: [RingLayout.ItemPos] = []
        var radii: [CGFloat] = []
        var previousRadius: CGFloat = 0

        while !remaining.isEmpty && ringIndex < 5 { // Allow up to 5 rings
            let currentBubbleSize = bubbleSizeForRing(ringIndex)
            let radius = radiusForRing(ringIndex, previousRadius: previousRadius)
            let capacity = ringCapacity(radius: radius, bubbleSize: currentBubbleSize)
            let take = min(capacity, remaining.count)
            let thisRing = Array(remaining.prefix(take))
            remaining.removeFirst(take)
            
            radii.append(radius)
            previousRadius = radius

            // Enhanced angular distribution with golden angle for better visual balance
            let goldenAngle = 2 * .pi * 0.618033988749 // Golden ratio angle
            let startAngle: CGFloat = ringIndex == 0 ? -.pi/2 : CGFloat(ringIndex) * goldenAngle
            
            for (index, child) in thisRing.enumerated() {
                let angleStep = 2 * .pi / CGFloat(take)
                let theta = startAngle + angleStep * CGFloat(index)
                
                // Add slight randomization for organic feel (but deterministic based on node ID)
                let randomOffset = sin(Double(child.uuid?.hashValue ?? 0)) * 0.1
                let adjustedRadius = radius + CGFloat(randomOffset) * 15
                
                let centerX = size.width/2 + adjustedRadius * cos(theta)
                let centerY = size.height/2 + adjustedRadius * sin(theta)
                
                items.append(.init(
                    id: child.uuid ?? UUID(), 
                    center: CGPoint(x: centerX, y: centerY), 
                    size: currentBubbleSize
                ))
            }
            ringIndex += 1
        }
        
        // Handle overflow nodes (more than 5 rings worth)
        if !remaining.isEmpty {
            // Place remaining nodes in a more compact outer ring
            let finalRadius = previousRadius + bubbleSizeForRing(4) * 1.2
            let finalBubbleSize = bubbleSizeForRing(4) * 0.8
            radii.append(finalRadius)
            
            for (index, child) in remaining.enumerated() {
                let theta = 2 * .pi * CGFloat(index) / CGFloat(remaining.count)
                let centerX = size.width/2 + finalRadius * cos(theta)
                let centerY = size.height/2 + finalRadius * sin(theta)
                
                items.append(.init(
                    id: child.uuid ?? UUID(),
                    center: CGPoint(x: centerX, y: centerY),
                    size: finalBubbleSize
                ))
            }
        }

        // Calculate content bounds with padding
        var minX = size.width/2 - centerSize/2
        var maxX = size.width/2 + centerSize/2
        var minY = size.height/2 - centerSize/2
        var maxY = size.height/2 + centerSize/2
        
        for item in items {
            let padding = item.size * 0.1 // Small padding around each bubble
            minX = min(minX, item.center.x - item.size/2 - padding)
            maxX = max(maxX, item.center.x + item.size/2 + padding)
            minY = min(minY, item.center.y - item.size/2 - padding)
            maxY = max(maxY, item.center.y + item.size/2 + padding)
        }
        
        cache.items = items
        cache.ringRadii = radii
        cache.contentBounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return cache
    }

    // MARK: Drop handling (reparent)
    private func handleDrop(on target: Node, providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        // Extract UUID string before entering closure to avoid Sendable warning
        let targetUUIDString = target.uuid?.uuidString
        
        _ = provider.loadObject(ofClass: NSString.self) { object, error in
            guard let idString = object as? String,
                  let uuid = UUID(uuidString: idString) else { return }

            _Concurrency.Task { @MainActor in
                guard let dragNode = findNode(with: uuid),
                      let targetUUIDString = targetUUIDString,
                      let targetUUID = UUID(uuidString: targetUUIDString),
                      let targetNode = findNode(with: targetUUID) else { return }
                
                // Prevent making a node its own ancestor
                if isAncestor(dragNode, of: targetNode) { return }

                // Remove from old parent
                if let oldParent = dragNode.parent {
                    oldParent.removeFromChildren(dragNode)
                }
                
                // Add to new parent
                dragNode.parent = targetNode
                targetNode.addToChildren(dragNode)
                
                do {
                    try viewContext.save()
                } catch {
                    print("Failed to save reparent: \(error)")
                }
                
                draggingNodeID = nil
                dropTargetNodeID = nil
            }
        }
        return true
    }

    private func findNode(with id: UUID) -> Node? {
        if center.uuid == id { return center }
        if let direct = children.first(where: { $0.uuid == id }) { return direct }
        // Fallback scan within immediate grandchildren
        for child in children {
            if let match = child.children?.first(where: { ($0 as? Node)?.uuid == id }) as? Node { return match }
        }
        return nil
    }

    private func isAncestor(_ ancestor: Node, of descendant: Node) -> Bool {
        var current: Node? = descendant.parent
        while let node = current {
            if node.uuid == ancestor.uuid { return true }
            current = node.parent
        }
        return false
    }
}
