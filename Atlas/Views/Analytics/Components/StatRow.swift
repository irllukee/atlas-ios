import SwiftUI

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 12) {
        StatRow(title: "Total Notes", value: "42")
        StatRow(title: "Notes This Week", value: "8")
        StatRow(title: "Average Note Length", value: "156 chars")
    }
    .padding()
}
