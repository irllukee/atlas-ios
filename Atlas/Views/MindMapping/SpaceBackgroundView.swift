import SwiftUI

struct SpaceBackgroundView: View {
    @State private var starPositions: [CGPoint] = []
    @State private var distantStarPositions: [CGPoint] = []
    @State private var nebulaPositions: [CGPoint] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep space gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.02, green: 0.02, blue: 0.08),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Use Canvas for efficient star rendering
                Canvas { context, size in
                    // Draw static stars
                    for position in starPositions {
                        context.fill(
                            Path(ellipseIn: CGRect(x: position.x, y: position.y, width: 1, height: 1)),
                            with: .color(.white)
                        )
                    }
                    
                    // Draw distant stars
                    for position in distantStarPositions {
                        context.fill(
                            Path(ellipseIn: CGRect(x: position.x, y: position.y, width: 0.5, height: 0.5)),
                            with: .color(.white.opacity(0.3))
                        )
                    }
                }
                .onAppear {
                    generateStarPositions(for: geometry.size)
                }
                .onChange(of: geometry.size) { newSize in
                    generateStarPositions(for: newSize)
                }
                
                // Nebula clouds (only 3, with reduced blur for performance)
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(0.08),
                                    Color.blue.opacity(0.04),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .offset(
                            x: CGFloat(index * 200 - 200),
                            y: CGFloat(index * 150 - 150)
                        )
                        .blur(radius: 15) // Reduced from 20
                }
            }
        }
    }
    
    private func generateStarPositions(for size: CGSize) {
        // Generate positions only once per size change
        starPositions = (0..<150).map { _ in
            CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
        }
        
        distantStarPositions = (0..<200).map { _ in
            CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
        }
    }
}

#Preview {
    SpaceBackgroundView()
        .frame(width: 400, height: 800)
}
