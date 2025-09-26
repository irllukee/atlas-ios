import SwiftUI

struct SpaceBackgroundView: View {
    @State private var starPositions: [CGPoint] = []
    @State private var distantStarPositions: [CGPoint] = []
    @State private var nebulaPositions: [CGPoint] = []
    @State private var cachedStarTexture: UIImage?
    
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
                
                // Use cached star texture for optimal performance
                Group {
                    if let starTexture = cachedStarTexture {
                        Image(uiImage: starTexture)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else {
                        // Fallback while texture is being generated
                        Color.clear
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                .onAppear {
                    generateStarPositions(for: geometry.size)
                    generateStarTexture(for: geometry.size)
                }
                .onChange(of: geometry.size) { _, newSize in
                    generateStarPositions(for: newSize)
                    generateStarTexture(for: newSize)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    handleMemoryWarning()
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
                        .blur(radius: 8) // Further optimized for performance
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
    
    private func generateStarTexture(for size: CGSize) {
        // Capture star positions on main thread before background work
        let stars = starPositions
        let distantStars = distantStarPositions
        
        // Generate cached texture on background queue for better performance
        DispatchQueue.global(qos: .userInitiated).async {
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                let cgContext = context.cgContext
                
                // Set background to clear
                cgContext.clear(CGRect(origin: .zero, size: size))
                
                // Draw static stars
                cgContext.setFillColor(UIColor.white.cgColor)
                for position in stars {
                    cgContext.fillEllipse(in: CGRect(x: position.x, y: position.y, width: 1, height: 1))
                }
                
                // Draw distant stars with reduced opacity
                cgContext.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
                for position in distantStars {
                    cgContext.fillEllipse(in: CGRect(x: position.x, y: position.y, width: 0.5, height: 0.5))
                }
            }
            
            DispatchQueue.main.async {
                self.cachedStarTexture = image
            }
        }
    }
    
    private func handleMemoryWarning() {
        print("🧠 Memory warning in SpaceBackgroundView - clearing cached texture")
        
        // Clear the cached star texture to free memory
        cachedStarTexture = nil
        
        // Note: Star positions are kept as they're small and essential for rendering
        // The texture will be regenerated when needed
    }
}

#Preview {
    SpaceBackgroundView()
        .frame(width: 400, height: 800)
}
