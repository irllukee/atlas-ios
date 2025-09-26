import SwiftUI
import CoreData

/// Simplified mind map view that shows one center node with its immediate children around it
/// Implements the basic navigation flow: Root → Child A → Grandchild B → etc.
struct SimpleMindMapView: View {
    let centerNode: Node
    let childNodes: [Node]
    let onNodeTap: (Node) -> Void
    
    @State private var appeared = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                // Center node (always visible)
                BubbleView(
                    title: centerNode.title ?? "Untitled",
                    hasNote: !(centerNode.note ?? "").isEmpty,
                    isCenter: true
                )
                .frame(width: centerBubbleSize(for: geometry.size),
                       height: centerBubbleSize(for: geometry.size))
                .position(CGPoint(x: geometry.size.width/2, y: geometry.size.height/2))
                .onTapGesture {
                    // Center node tap - could be used for editing or other actions
                }
                .scaleEffect(appeared ? 1.0 : 0.8)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appeared)
                
                // Child nodes arranged in a circle around the center
                ForEach(Array(childNodes.enumerated()), id: \.element.uuid) { index, childNode in
                    let position = calculateChildPosition(
                        for: index,
                        totalChildren: childNodes.count,
                        in: geometry.size
                    )
                    
                    BubbleView(
                        title: childNode.title ?? "Untitled",
                        hasNote: !(childNode.note ?? "").isEmpty,
                        isCenter: false
                    )
                    .frame(width: childBubbleSize(for: geometry.size),
                           height: childBubbleSize(for: geometry.size))
                    .position(position)
                    .onTapGesture {
                        print("🔵 Child node tapped: \(childNode.title ?? "Untitled")")
                        print("🔵 About to call onNodeTap with: \(childNode.title ?? "Untitled")")
                        onNodeTap(childNode)
                        print("🔵 onNodeTap called successfully")
                    }
                    .scaleEffect(appeared ? 1.0 : 0.8)
                    .opacity(appeared ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(Double(index) * 0.1),
                        value: appeared
                    )
                }
            }
        }
        .onAppear {
            appeared = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func centerBubbleSize(for size: CGSize) -> CGFloat {
        let minSide = min(size.width, size.height)
        return max(80, minSide * 0.2)
    }
    
    private func childBubbleSize(for size: CGSize) -> CGFloat {
        let minSide = min(size.width, size.height)
        return max(60, minSide * 0.15)
    }
    
    private func calculateChildPosition(
        for index: Int,
        totalChildren: Int,
        in size: CGSize
    ) -> CGPoint {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Calculate radius based on screen size
        let radius = min(size.width, size.height) * 0.25
        
        // Distribute children evenly around the center
        let angle = (2 * .pi * Double(index)) / Double(totalChildren) - .pi / 2 // Start from top
        
        let x = centerX + radius * cos(angle)
        let y = centerY + radius * sin(angle)
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AtlasTheme.Colors.background.ignoresSafeArea()
        
        SimpleMindMapView(
            centerNode: Node(),
            childNodes: [
                Node(),
                Node(),
                Node(),
                Node()
            ],
            onNodeTap: { _ in }
        )
    }
}
