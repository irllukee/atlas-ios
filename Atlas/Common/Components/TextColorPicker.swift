import SwiftUI

struct TextColorPicker: View {
    @Binding var selectedColor: UIColor?
    @Environment(\.dismiss) private var dismiss
    
    // Predefined color palette
    private let colors: [UIColor] = [
        .label,           // Default text color
        .systemRed,       // Red
        .systemOrange,    // Orange
        .systemYellow,    // Yellow
        .systemGreen,     // Green
        .systemMint,      // Mint
        .systemTeal,      // Teal
        .systemCyan,      // Cyan
        .systemBlue,      // Blue
        .systemIndigo,    // Indigo
        .systemPurple,    // Purple
        .systemPink,      // Pink
        .systemBrown,     // Brown
        .systemGray,      // Gray
        .systemGray2,     // Light Gray
        .systemGray3,     // Lighter Gray
        .systemGray4,     // Very Light Gray
        .systemGray5,     // Almost White Gray
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose Text Color")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select a color for your text")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Color Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            dismiss()
                        }) {
                            Circle()
                                .fill(Color(color))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 1)
                                        .opacity(selectedColor == color ? 1 : 0.3)
                                )
                                .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                // Reset Button
                Button(action: {
                    selectedColor = .label // Default text color
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset to Default")
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
