import SwiftUI

/// Bubble View for mind mapping nodes - adapted to use Atlas theme
struct BubbleView: View {
    let title: String
    let hasNote: Bool
    let isCenter: Bool
    var iconName: String?
    var colorHex: String?

    private var tint: Color {
        (colorHex.flatMap { Color(hex: $0) } ?? AtlasTheme.Colors.primary).opacity(isCenter ? 0.9 : 0.75)
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

            VStack(spacing: 6) {
                if let name = iconName {
                    Image(systemName: name)
                        .font(isCenter ? .title3 : .headline)
                        .foregroundStyle(.white.opacity(0.95))
                }
                Text(title.isEmpty ? "Untitled" : title)
                    .font(isCenter ? .headline : .subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)

                if hasNote {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.95))
                        .accessibilityLabel("Has note")
                }
            }
            .padding(10)
        }
        .contentShape(Circle().inset(by: -10)) // generous hit area
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6,
              let r = UInt8(s.prefix(2), radix: 16),
              let g = UInt8(s.dropFirst(2).prefix(2), radix: 16),
              let b = UInt8(s.suffix(2), radix: 16) else {
            return nil
        }
        self = Color(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: 1)
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
                isCenter: true,
                iconName: "brain.head.profile",
                colorHex: "#6AAFF0"
            )
            
            BubbleView(
                title: "Child Node",
                hasNote: false,
                isCenter: false,
                iconName: "lightbulb.fill",
                colorHex: "#F7D98D"
            )
        }
    }
}
