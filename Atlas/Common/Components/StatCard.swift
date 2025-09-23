import SwiftUI

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        FrostedCard(style: .metric) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                // Header with icon and title
                HStack {
                    Image(systemName: icon)
                        .font(AtlasTheme.Typography.title3)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                // Value
                Text(value)
                    .font(AtlasTheme.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                    Text(title)
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.text)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(AtlasTheme.Typography.caption2)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            StatCard(
                title: "Average Mood",
                value: "7.2",
                subtitle: "This month",
                icon: "heart.fill",
                color: .pink
            )
            
            StatCard(
                title: "Total Entries",
                value: "24",
                subtitle: "Logged",
                icon: "chart.bar.fill",
                color: .blue
            )
        }
        
        HStack(spacing: 16) {
            StatCard(
                title: "Best Mood",
                value: "9",
                subtitle: "Peak",
                icon: "star.fill",
                color: .yellow
            )
            
            StatCard(
                title: "Consistency",
                value: "85%",
                subtitle: "Score",
                icon: "target",
                color: .green
            )
        }
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}
