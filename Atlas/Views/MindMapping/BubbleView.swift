import SwiftUI

/// Bubble View for mind mapping nodes - adapted to use Atlas theme
struct BubbleView: View {
    let title: String
    let hasNote: Bool
    let isCenter: Bool

    private var tint: Color {
        AtlasTheme.Colors.primary.opacity(isCenter ? 0.9 : 0.75)
    }

    var body: some View {
        ZStack {
            // Layered glass using Atlas theme
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle().stroke(.white.opacity(0.16), lineWidth: isCenter ? 2 : 1)
                )
                .background(
                    Circle()
                        .fill(tint.opacity(0.12))
                        .blur(radius: isCenter ? 16 : 10)
                )
                .shadow(color: .black.opacity(0.6), radius: isCenter ? 14 : 8, x: 0, y: 6)

            VStack(spacing: 4) {
                Text(title.isEmpty ? "Untitled" : title)
                    .font(isCenter ? .headline : .subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)

                if hasNote {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.95))
                        .accessibilityLabel("Has note")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
        }
        .contentShape(Circle().inset(by: -10)) // generous hit area
        .accessibilityAddTraits(.isButton)
    }
}


// MARK: - Preview
#Preview {
    ZStack {
        AtlasTheme.Colors.background.ignoresSafeArea()
        
        VStack(spacing: 20) {
            BubbleView(
                title: "Center Node",
                hasNote: true,
                isCenter: true
            )
            
            BubbleView(
                title: "Child Node",
                hasNote: false,
                isCenter: false
            )
        }
    }
}
