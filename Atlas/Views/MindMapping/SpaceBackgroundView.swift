import SwiftUI

struct SpaceBackgroundView: View {
    @State private var animationOffset: CGFloat = 0
    @State private var starTwinkle: [Bool] = Array(repeating: false, count: 200)
    
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
                
                // Nebula clouds
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(0.1),
                                    Color.blue.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .offset(
                            x: CGFloat(index * 200 - 200) + animationOffset * 0.3,
                            y: CGFloat(index * 150 - 150) + animationOffset * 0.2
                        )
                        .blur(radius: 20)
                }
                
                // Twinkling stars
                ForEach(0..<starTwinkle.count, id: \.self) { index in
                    Circle()
                        .fill(starTwinkle[index] ? Color.white : Color.white.opacity(0.6))
                        .frame(width: starTwinkle[index] ? 2 : 1, height: starTwinkle[index] ? 2 : 1)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 0.5...2.0))
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 0...3.0)),
                            value: starTwinkle[index]
                        )
                }
                
                // Distant stars (smaller, dimmer)
                ForEach(0..<100, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 0.5, height: 0.5)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
                
                // Shooting stars (occasional)
                ForEach(0..<3, id: \.self) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.blue.opacity(0.8), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 2, height: 1)
                        .rotationEffect(.degrees(45))
                        .offset(
                            x: CGFloat(index * 200 - 100) + animationOffset * 2,
                            y: CGFloat(index * 150 - 75) + animationOffset * 1.5
                        )
                        .opacity(animationOffset.truncatingRemainder(dividingBy: 1000) < 50 ? 1 : 0)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Continuous slow movement
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            animationOffset = 1000
        }
        
        // Random star twinkling
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                let randomIndex = Int.random(in: 0..<starTwinkle.count)
                starTwinkle[randomIndex].toggle()
            }
        }
    }
}

#Preview {
    SpaceBackgroundView()
        .frame(width: 400, height: 800)
}
