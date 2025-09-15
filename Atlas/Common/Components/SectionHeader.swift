import SwiftUI

// MARK: - Section Header Component
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    
    init(title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: AtlasTheme.Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(AtlasTheme.Colors.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AtlasTheme.Typography.title3)
                    .foregroundColor(AtlasTheme.Colors.text)
                    .fontWeight(.semibold)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, AtlasTheme.Spacing.md)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SectionHeader(title: "Today's Highlights", subtitle: "Updated 9:14 AM", icon: "sparkles")
        
        SectionHeader(title: "Trends", subtitle: "Your progress at a glance", icon: "chart.line.uptrend.rectangle.fill")
        
        SectionHeader(title: "Other Modules", subtitle: "Explore more features", icon: "app.grid.fill")
        
        SectionHeader(title: "Simple Header")
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}