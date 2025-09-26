import SwiftUI

struct SyncStatusIndicator: View {
    var body: some View {
        // Simplified sync indicator for basic mind mapping
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            
            Text("Ready")
                .font(.caption2)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SyncStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        SyncStatusIndicator()
            .preferredColorScheme(.dark)
    }
}