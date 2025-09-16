import SwiftUI

// MARK: - Activity Item Component
struct ActivityItem: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    @State private var isPressed = false
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .scaleEffect(iconScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: iconScale)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(time)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.vertical, 8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
                iconScale = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                    iconScale = 1.0
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ActivityItem(
            icon: "checkmark.circle.fill",
            title: "Completed task: Review quarterly report",
            time: "2 hours ago",
            color: .green
        )
        
        ActivityItem(
            icon: "note.text",
            title: "Created note: Meeting ideas",
            time: "4 hours ago",
            color: .blue
        )
        
        ActivityItem(
            icon: "book.fill",
            title: "Journal entry: Morning reflection",
            time: "6 hours ago",
            color: .purple
        )
        
        ActivityItem(
            icon: "calendar",
            title: "Added event: Team meeting",
            time: "Yesterday",
            color: .orange
        )
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}

