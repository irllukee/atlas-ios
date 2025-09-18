import SwiftUI

struct GalaxyView: View {
    @StateObject private var galaxyManager = GalaxyManager()
    @State private var selectedNode: GalaxyNode?
    @State private var expandedNode: GalaxyNode?
    @State private var subNodes: [GalaxyNode] = []
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var expansionAnimation: CGFloat = 0.0
    @State private var isLinkMode: Bool = false
    @State private var linkStartNode: GalaxyNode?
    @State private var linkEndPosition: CGPoint = .zero
    @State private var isCreatingLink: Bool = false
    @State private var showingGalaxySelection = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Cosmic background gradient
                cosmicBackground
                    .ignoresSafeArea()
                
                // Galaxy content
                galaxyContent
            }
            .navigationTitle(galaxyManager.selectedGalaxy?.name ?? "Brainstorm Galaxy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Galaxies") {
                        showingGalaxySelection = true
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Node") {
                            addNewNode()
                        }
                        
                        if let selectedGalaxy = galaxyManager.selectedGalaxy {
                            Button("Import Notes") {
                                importNotesToGalaxy(selectedGalaxy)
                            }
                            
                            Button("Import Tasks") {
                                importTasksToGalaxy(selectedGalaxy)
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingGalaxySelection) {
            GalaxySelectionView()
        }
    }
    
    // MARK: - Cosmic Background
    private var cosmicBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: galaxyManager.selectedGalaxy?.theme.backgroundGradient ?? GalaxyTheme.cosmic.backgroundGradient),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Galaxy Content
    private var galaxyContent: some View {
        GeometryReader { geometry in
            ZStack {
                if let selectedGalaxy = galaxyManager.selectedGalaxy {
                    // Connection lines
                    ForEach(selectedGalaxy.connections) { connection in
                        ConnectionLineView(connection: connection)
                            .scaleEffect(scale)
                            .offset(offset)
                    }
                    
                    // Active link being created
                    if isCreatingLink, let startNode = linkStartNode {
                        ConnectionLineView(
                            connection: GalaxyConnection(
                                id: UUID(),
                                fromNode: startNode,
                                toNode: GalaxyNode(
                                    id: UUID(),
                                    title: "Temp",
                                    type: .note,
                                    position: linkEndPosition,
                                    size: .small
                                ),
                                isTemporary: true
                            )
                        )
                        .scaleEffect(scale)
                        .offset(offset)
                    }
                    
                    // Galaxy nodes with lazy loading
                    LazyVStack(spacing: 0) {
                        ForEach(selectedGalaxy.nodes) { node in
                            GalaxyNodeView(
                                node: node, 
                                isSelected: selectedNode?.id == node.id,
                                isExpanded: expandedNode?.id == node.id,
                                isLinkMode: isLinkMode,
                                isLinkStart: linkStartNode?.id == node.id
                            )
                            .scaleEffect(scale)
                            .offset(offset)
                            .onTapGesture {
                                handleNodeTap(node)
                            }
                            .onLongPressGesture {
                                handleNodeLongPress(node)
                            }
                        }
                    }
                    
                    // Sub-nodes for expanded node with lazy loading
                    LazyVStack(spacing: 0) {
                        ForEach(subNodes) { subNode in
                            GalaxyNodeView(
                                node: subNode,
                                isSelected: false,
                                isExpanded: false,
                                isLinkMode: isLinkMode,
                                isLinkStart: false
                            )
                            .scaleEffect(scale * expansionAnimation)
                            .offset(calculateSubNodeOffset(subNode, from: expandedNode))
                            .opacity(expansionAnimation)
                            .onTapGesture {
                                selectNode(subNode)
                            }
                            .onLongPressGesture {
                                handleNodeLongPress(subNode)
                            }
                        }
                    }
                    
                    // Show empty state if no nodes
                    if selectedGalaxy.nodes.isEmpty {
                        EmptyGalaxyView(galaxy: selectedGalaxy)
                    }
                } else {
                    // No galaxy selected
                    NoGalaxySelectedView {
                        showingGalaxySelection = true
                    }
                }
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            scale = max(0.5, min(3.0, scale))
                        }
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                        isDragging = true
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            offset = .zero
                            isDragging = false
                        }
                    }
            )
        }
    }
    
    
    // MARK: - Actions
    private func selectNode(_ node: GalaxyNode) {
        withAnimation(.spring()) {
            selectedNode = selectedNode?.id == node.id ? nil : node
        }
    }
    
    private func handleNodeTap(_ node: GalaxyNode) {
        if isLinkMode {
            // In link mode, complete the connection
            completeLink(to: node)
        } else if expandedNode?.id == node.id {
            // Collapse if already expanded
            collapseNode()
        } else {
            // Expand the node
            expandNode(node)
        }
    }
    
    private func handleNodeLongPress(_ node: GalaxyNode) {
        if !isLinkMode {
            // Start link mode
            startLinkMode(from: node)
        }
    }
    
    private func expandNode(_ node: GalaxyNode) {
        // First collapse any currently expanded node
        if expandedNode != nil {
            collapseNode()
        }
        
        // Set the expanded node
        expandedNode = node
        
        // Generate sub-nodes based on node type
        subNodes = generateSubNodes(for: node)
        
        // Start expansion animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.1)) {
            expansionAnimation = 1.0
        }
        
        // Trigger ripple animations on connected nodes
        triggerRippleAnimations(for: node)
    }
    
    private func collapseNode() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.1)) {
            expansionAnimation = 0.0
        }
        
        // Clear expanded state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            expandedNode = nil
            subNodes = []
        }
    }
    
    private func generateSubNodes(for parentNode: GalaxyNode) -> [GalaxyNode] {
        let basePosition = parentNode.position
        let radius: CGFloat = 120
        
        switch parentNode.type {
        case .dream:
            return [
                GalaxyNode(id: UUID(), title: "Lucid Dreams", type: .dream, position: CGPoint(x: basePosition.x + radius * cos(0), y: basePosition.y + radius * sin(0)), size: .small),
                GalaxyNode(id: UUID(), title: "Nightmares", type: .dream, position: CGPoint(x: basePosition.x + radius * cos(.pi/2), y: basePosition.y + radius * sin(.pi/2)), size: .small),
                GalaxyNode(id: UUID(), title: "Recurring", type: .dream, position: CGPoint(x: basePosition.x + radius * cos(.pi), y: basePosition.y + radius * sin(.pi)), size: .small),
                GalaxyNode(id: UUID(), title: "Symbols", type: .dream, position: CGPoint(x: basePosition.x + radius * cos(3 * .pi/2), y: basePosition.y + radius * sin(3 * .pi/2)), size: .small)
            ]
        case .note:
            return [
                GalaxyNode(id: UUID(), title: "Ideas", type: .note, position: CGPoint(x: basePosition.x + radius * cos(0), y: basePosition.y + radius * sin(0)), size: .small),
                GalaxyNode(id: UUID(), title: "Research", type: .note, position: CGPoint(x: basePosition.x + radius * cos(.pi/2), y: basePosition.y + radius * sin(.pi/2)), size: .small),
                GalaxyNode(id: UUID(), title: "Quick Notes", type: .note, position: CGPoint(x: basePosition.x + radius * cos(.pi), y: basePosition.y + radius * sin(.pi)), size: .small),
                GalaxyNode(id: UUID(), title: "Inspiration", type: .note, position: CGPoint(x: basePosition.x + radius * cos(3 * .pi/2), y: basePosition.y + radius * sin(3 * .pi/2)), size: .small)
            ]
        case .task:
            return [
                GalaxyNode(id: UUID(), title: "Today", type: .task, position: CGPoint(x: basePosition.x + radius * cos(0), y: basePosition.y + radius * sin(0)), size: .small),
                GalaxyNode(id: UUID(), title: "This Week", type: .task, position: CGPoint(x: basePosition.x + radius * cos(.pi/2), y: basePosition.y + radius * sin(.pi/2)), size: .small),
                GalaxyNode(id: UUID(), title: "Projects", type: .task, position: CGPoint(x: basePosition.x + radius * cos(.pi), y: basePosition.y + radius * sin(.pi)), size: .small),
                GalaxyNode(id: UUID(), title: "Completed", type: .task, position: CGPoint(x: basePosition.x + radius * cos(3 * .pi/2), y: basePosition.y + radius * sin(3 * .pi/2)), size: .small)
            ]
        case .journal:
            return [
                GalaxyNode(id: UUID(), title: "Daily", type: .journal, position: CGPoint(x: basePosition.x + radius * cos(0), y: basePosition.y + radius * sin(0)), size: .small),
                GalaxyNode(id: UUID(), title: "Gratitude", type: .journal, position: CGPoint(x: basePosition.x + radius * cos(.pi/2), y: basePosition.y + radius * sin(.pi/2)), size: .small),
                GalaxyNode(id: UUID(), title: "Reflections", type: .journal, position: CGPoint(x: basePosition.x + radius * cos(.pi), y: basePosition.y + radius * sin(.pi)), size: .small),
                GalaxyNode(id: UUID(), title: "Goals", type: .journal, position: CGPoint(x: basePosition.x + radius * cos(3 * .pi/2), y: basePosition.y + radius * sin(3 * .pi/2)), size: .small)
            ]
        }
    }
    
    private func calculateSubNodeOffset(_ subNode: GalaxyNode, from parentNode: GalaxyNode?) -> CGSize {
        guard let parent = parentNode else { return .zero }
        
        let deltaX = subNode.position.x - parent.position.x
        let deltaY = subNode.position.y - parent.position.y
        
        return CGSize(width: deltaX * (1 - expansionAnimation), height: deltaY * (1 - expansionAnimation))
    }
    
    private func startLinkMode(from node: GalaxyNode) {
        withAnimation(.spring()) {
            isLinkMode = true
            linkStartNode = node
            isCreatingLink = true
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func completeLink(to endNode: GalaxyNode) {
        guard let startNode = linkStartNode, 
              let selectedGalaxy = galaxyManager.selectedGalaxy,
              startNode.id != endNode.id else {
            cancelLinkMode()
            return
        }
        
        // Check if connection already exists
        let connectionExists = selectedGalaxy.connections.contains { connection in
            (connection.fromNode.id == startNode.id && connection.toNode.id == endNode.id) ||
            (connection.fromNode.id == endNode.id && connection.toNode.id == startNode.id)
        }
        
        if !connectionExists {
            let newConnection = GalaxyConnection(
                id: UUID(),
                fromNode: startNode,
                toNode: endNode,
                isTemporary: false
            )
            
            galaxyManager.addConnection(to: selectedGalaxy, connection: newConnection)
            
            // Haptic feedback for successful connection
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        } else {
            // Haptic feedback for duplicate connection
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
        
        cancelLinkMode()
    }
    
    private func cancelLinkMode() {
        withAnimation(.spring()) {
            isLinkMode = false
            linkStartNode = nil
            isCreatingLink = false
        }
    }
    
    private func triggerRippleAnimations(for node: GalaxyNode) {
        guard let selectedGalaxy = galaxyManager.selectedGalaxy else { return }
        
        // Find connections involving this node
        let connectedNodes = selectedGalaxy.connections.compactMap { connection in
            if connection.fromNode.id == node.id {
                return connection.toNode
            } else if connection.toNode.id == node.id {
                return connection.fromNode
            }
            return nil
        }
        
        // Trigger ripple animations on connected nodes
        for _ in connectedNodes {
            // This will be handled by the ConnectionLineView's onChange observers
            // The ripple animation will automatically trigger when the connection changes
        }
    }
    
    private func addNewNode() {
        guard let selectedGalaxy = galaxyManager.selectedGalaxy else { return }
        
        let newNode = GalaxyNode(
            id: UUID(),
            title: "New Node",
            type: selectedGalaxy.nodeTypes.first ?? .note,
            position: CGPoint(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -100...100)),
            size: .medium
        )
        
        galaxyManager.addNode(to: selectedGalaxy, node: newNode)
    }
    
    private func importNotesToGalaxy(_ galaxy: Galaxy) {
        // For now, let's create some sample nodes to demonstrate the functionality
        // In a real implementation, we would fetch actual notes from DataManager
        let sampleNoteNodes = [
            GalaxyNode(
                title: "Project Ideas",
                type: .note,
                position: CGPoint(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -150...150)),
                size: .medium,
                linkedNoteId: UUID() // Simulated note ID
            ),
            GalaxyNode(
                title: "Meeting Notes",
                type: .note,
                position: CGPoint(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -150...150)),
                size: .medium,
                linkedNoteId: UUID() // Simulated note ID
            ),
            GalaxyNode(
                title: "Research Findings",
                type: .note,
                position: CGPoint(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -150...150)),
                size: .medium,
                linkedNoteId: UUID() // Simulated note ID
            )
        ]
        
        for node in sampleNoteNodes {
            galaxyManager.addNode(to: galaxy, node: node)
        }
    }
    
    private func importTasksToGalaxy(_ galaxy: Galaxy) {
        // Create goal nodes (larger) with orbiting task nodes (smaller)
        let goalPositions = [
            CGPoint(x: -100, y: -100),
            CGPoint(x: 100, y: -100),
            CGPoint(x: 0, y: 100)
        ]
        
        let goalTitles = ["App Development", "Marketing Campaign", "Research Project"]
        
        for (index, goalPosition) in goalPositions.enumerated() {
            // Create goal node (larger)
            let goalNode = GalaxyNode(
                title: goalTitles[index],
                type: .task,
                position: goalPosition,
                size: .large,
                isGoalNode: true
            )
            galaxyManager.addNode(to: galaxy, node: goalNode)
            
            // Create orbiting task nodes around this goal
            let taskTitles = [
                ["Design UI", "Implement Features", "Write Tests"],
                ["Create Ads", "Social Media", "Email Campaign"],
                ["Market Research", "User Interviews", "Data Analysis"]
            ]
            
            let taskStatuses: [TaskStatus] = [.pending, .inProgress, .completed]
            
            for (taskIndex, taskTitle) in taskTitles[index].enumerated() {
                let orbitalRadius: CGFloat = 80 + CGFloat(taskIndex * 20)
                let angle = Double(taskIndex) * (2 * Double.pi / Double(taskTitles[index].count))
                let taskPosition = CGPoint(
                    x: goalPosition.x + cos(angle) * orbitalRadius,
                    y: goalPosition.y + sin(angle) * orbitalRadius
                )
                
                let taskNode = GalaxyNode(
                    title: taskTitle,
                    type: .task,
                    position: taskPosition,
                    size: .small,
                    linkedTaskId: UUID(), // Simulated task ID
                    taskStatus: taskStatuses[taskIndex],
                    orbitalRadius: orbitalRadius,
                    orbitalSpeed: 1.0 + CGFloat(taskIndex) * 0.2,
                    parentGoalId: goalNode.id
                )
                galaxyManager.addNode(to: galaxy, node: taskNode)
            }
        }
    }
}

// MARK: - Empty Galaxy View
struct EmptyGalaxyView: View {
    let galaxy: Galaxy
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Your \(galaxy.name) is empty")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Tap the + button to add your first node")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - No Galaxy Selected View
struct NoGalaxySelectedView: View {
    let onSelectGalaxy: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            
            Text("No Galaxy Selected")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Choose a galaxy to start exploring")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Select Galaxy") {
                onSelectGalaxy()
            }
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .padding()
    }
}


// MARK: - Galaxy Node View
struct GalaxyNodeView: View {
    let node: GalaxyNode
    let isSelected: Bool
    let isExpanded: Bool
    let isLinkMode: Bool
    let isLinkStart: Bool
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowIntensity: CGFloat = 0.0
    @State private var expansionGlow: CGFloat = 0.0
    @State private var linkModeGlow: CGFloat = 0.0
        @State private var orbitalAngle: Double = 0.0
        @State private var currentPosition: CGPoint
        
        init(node: GalaxyNode, isSelected: Bool, isExpanded: Bool, isLinkMode: Bool, isLinkStart: Bool) {
            self.node = node
            self.isSelected = isSelected
            self.isExpanded = isExpanded
            self.isLinkMode = isLinkMode
            self.isLinkStart = isLinkStart
            self._currentPosition = State(initialValue: node.position)
        }
        
        private var orbitalPosition: CGPoint {
            if node.type == .task && node.orbitalRadius > 0 {
                let radians = orbitalAngle * .pi / 180
                let x = node.position.x + cos(radians) * node.orbitalRadius
                let y = node.position.y + sin(radians) * node.orbitalRadius
                return CGPoint(x: x, y: y)
            }
            return node.position
        }
    
    var body: some View {
        ZStack {
            // Background effects
            backgroundEffects
            
            // Main node
            mainNode
        }
        .position(orbitalPosition)
        .onAppear {
            startAnimations()
            startOrbitalAnimation()
        }
        .onChange(of: isSelected) { _, selected in
            if selected {
                withAnimation(.easeInOut(duration: 0.3)) {
                    glowIntensity = 0.4
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    glowIntensity = 0.0
                }
            }
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    expansionGlow = 0.3
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    expansionGlow = 0.0
                }
            }
        }
        .onChange(of: isLinkMode) { _, linkMode in
            if linkMode {
                withAnimation(.easeInOut(duration: 0.3)) {
                    linkModeGlow = 0.2
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    linkModeGlow = 0.0
                }
            }
        }
    }
    
    private var backgroundEffects: some View {
        ZStack {
            // Link mode glow effect
            if isLinkMode {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: node.size.diameter + 20, height: node.size.diameter + 20)
                    .blur(radius: 5)
                    .opacity(linkModeGlow)
            }
            
            // Link start indicator
            if isLinkStart {
                Circle()
                    .fill(Color.cyan.opacity(0.4))
                    .frame(width: node.size.diameter + 20, height: node.size.diameter + 20)
                    .blur(radius: 3)
                    .opacity(0.8)
            }
            
            // Expansion glow effect
            if isExpanded {
                Circle()
                    .fill(node.type.color.opacity(0.2))
                    .frame(width: node.size.diameter + 30, height: node.size.diameter + 30)
                    .blur(radius: 8)
                    .opacity(expansionGlow)
            }
            
            // Glow effect
            Circle()
                .fill(node.type.color.opacity(0.3))
                .frame(width: node.size.diameter + 15, height: node.size.diameter + 15)
                .blur(radius: 5)
                .opacity(glowIntensity)
        }
    }
    
    private var mainNode: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: node.size.diameter, height: node.size.diameter)
            .overlay(nodeBorder)
            .overlay(centerPulse)
            .overlay(nodeIcon)
            .overlay(linkedIndicator)
            .overlay(taskStatusIndicator)
            .scaleEffect(isSelected ? 1.1 : (isExpanded ? 1.05 : (isLinkStart ? 1.1 : 1.0)))
            .shadow(color: isLinkStart ? Color.cyan.opacity(0.7) : node.type.color.opacity(0.5), radius: isSelected ? 15 : (isExpanded ? 12 : (isLinkStart ? 15 : 8)))
    }
    
    private var nodeBorder: some View {
        Circle()
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        isLinkStart ? Color.cyan : node.type.color.opacity(0.8),
                        isLinkStart ? Color.cyan.opacity(0.3) : node.type.color.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isExpanded ? 3 : (isLinkStart ? 3 : 2)
            )
    }
    
    private var centerPulse: some View {
        Circle()
            .fill(isLinkStart ? Color.cyan.opacity(0.8) : node.type.color.opacity(0.6))
            .frame(width: 8, height: 8)
            .scaleEffect(pulseScale)
    }
    
    private var nodeIcon: some View {
        Group {
            if node.type.icon == "galaxy" {
                GalaxyIcon(
                    size: node.size.diameter * 0.4,
                    color: isLinkStart ? Color.cyan : node.type.color
                )
            } else {
                Image(systemName: node.type.icon)
                    .font(.system(size: node.size.diameter * 0.3, weight: .medium))
                    .foregroundColor(isLinkStart ? Color.cyan : node.type.color)
            }
        }
    }
    
    private var linkedIndicator: some View {
        Group {
            if node.isLinked {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "link")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.green.opacity(0.8))
                                    .frame(width: 12, height: 12)
                            )
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var taskStatusIndicator: some View {
        Group {
            if let taskStatus = node.taskStatus {
                VStack {
                    HStack {
                        Image(systemName: taskStatus.icon)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(taskStatus.color.opacity(0.8))
                                    .frame(width: 12, height: 12)
                            )
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
    
    private func startAnimations() {
        // Simplified pulse animation - only for selected nodes
        if isSelected {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1 // Reduced scale
            }
        }
    }
        
        private func startOrbitalAnimation() {
            // Only animate if this is a task node with orbital properties
            guard node.type == .task && node.orbitalRadius > 0 else { return }
            
            withAnimation(.linear(duration: node.orbitalSpeed).repeatForever(autoreverses: false)) {
                orbitalAngle = 360
            }
        }
}


// MARK: - Connection Line View
struct ConnectionLineView: View {
    let connection: GalaxyConnection
    @State private var rippleProgress: CGFloat = 0.0
    @State private var isAnimating: Bool = false
    
    var body: some View {
        ZStack {
            // Main connection line
            Path { path in
                let startPoint = connection.fromNode.position
                let endPoint = connection.toNode.position
                
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        connection.isTemporary ? Color.cyan.opacity(0.6) : Color.white.opacity(0.8),
                        connection.isTemporary ? Color.cyan.opacity(0.3) : Color.white.opacity(0.4)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(
                    lineWidth: connection.isTemporary ? 2 : 1.5,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: connection.isTemporary ? [5, 5] : []
                )
            )
            .shadow(color: connection.isTemporary ? Color.cyan.opacity(0.5) : Color.white.opacity(0.3), radius: 3)
            .animation(.easeInOut(duration: 0.3), value: connection.isTemporary)
            
            // Ripple effect overlay
            if !connection.isTemporary && isAnimating {
                Path { path in
                    let startPoint = connection.fromNode.position
                    let endPoint = connection.toNode.position
                    
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.8),
                            Color.cyan.opacity(0.4),
                            Color.cyan.opacity(0.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .shadow(color: Color.cyan.opacity(0.6), radius: 5)
                .scaleEffect(x: rippleProgress, y: 1.0, anchor: .leading)
                .opacity(1.0 - rippleProgress)
                .animation(.easeOut(duration: 1.5), value: rippleProgress)
            }
        }
        .onAppear {
            startRippleAnimation()
        }
        .onChange(of: connection.fromNode.id) { _, _ in
            startRippleAnimation()
        }
        .onChange(of: connection.toNode.id) { _, _ in
            startRippleAnimation()
        }
    }
    
    private func startRippleAnimation() {
        guard !connection.isTemporary else { return }
        
        withAnimation(.easeOut(duration: 1.5)) {
            rippleProgress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            rippleProgress = 0.0
            isAnimating = false
            
            // Disabled random ripple animations for performance
            // Only animate on user interaction now
        }
    }
}

#Preview {
    GalaxyView()
}
