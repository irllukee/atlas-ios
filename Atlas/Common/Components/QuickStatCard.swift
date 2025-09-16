import SwiftUI

// MARK: - Quick Stat Card Component
struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double
    
    @State private var isPressed = false
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        FrostedCard(style: .compact) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .frame(width: 24, height: 24)
                    
                    Spacer()
                    
                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 3)
                            .frame(width: 32, height: 32)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: progress)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .offset(y: animationOffset)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animationOffset)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animationOffset = 0
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            QuickStatCard(
                title: "Tasks Done",
                value: "12",
                subtitle: "of 15 today",
                icon: "checkmark.circle.fill",
                color: .green,
                progress: 0.8
            )
            
            QuickStatCard(
                title: "Notes",
                value: "8",
                subtitle: "this week",
                icon: "note.text",
                color: .blue,
                progress: 0.6
            )
        }
        
        HStack(spacing: 16) {
            QuickStatCard(
                title: "Journal",
                value: "3",
                subtitle: "entries today",
                icon: "book.fill",
                color: .purple,
                progress: 0.4
            )
            
            QuickStatCard(
                title: "Events",
                value: "5",
                subtitle: "remaining today",
                icon: "calendar",
                color: .orange,
                progress: 0.7
            )
        }
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}

