import SwiftUI

// MARK: - Focus Card Component
struct FocusCard: View {
    let title: String
    let description: String
    let progress: Double
    let color: Color
    let icon: String
    
    @State private var isPressed = false
    @State private var progressAnimation: Double = 0
    
    var body: some View {
        FrostedCard(style: .standard) {
            HStack(spacing: 16) {
                // Icon and Progress
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .frame(width: 32, height: 32)
                    
                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 4)
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .trim(from: 0, to: progressAnimation)
                            .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.2), value: progressAnimation)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color.opacity(0.3))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(width: geometry.size.width * progressAnimation, height: 6)
                                .animation(.easeInOut(duration: 1.0), value: progressAnimation)
                        }
                    }
                    .frame(height: 6)
                }
                
                Spacer()
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
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
            withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
                progressAnimation = progress
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FocusCard(
            title: "Morning Routine",
            description: "Complete your daily morning routine",
            progress: 0.75,
            color: .blue,
            icon: "sunrise.fill"
        )
        
        FocusCard(
            title: "Work Project",
            description: "Finish the quarterly report",
            progress: 0.4,
            color: .green,
            icon: "briefcase.fill"
        )
        
        FocusCard(
            title: "Evening Reflection",
            description: "Journal about today's experiences",
            progress: 0.0,
            color: .purple,
            icon: "moon.stars.fill"
        )
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}

