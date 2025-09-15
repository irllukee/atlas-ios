import SwiftUI

struct JournalTemplatesView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                ForEach(JournalTemplate.templates) { template in
                    Button(action: {
                        viewModel.createJournalEntryFromTemplate(template)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: template.type.icon)
                                    .foregroundColor(iconColor(for: template.type))
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(template.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(template.type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if template.isEncrypted {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            
                            Text(template.content.prefix(150) + "...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            
                            if let prompt = template.prompt {
                                Text("Prompt: \(prompt)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .italic()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Journal Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func iconColor(for type: JournalEntryType) -> Color {
        switch type {
        case .daily:
            return .blue
        case .dream:
            return .purple
        case .gratitude:
            return .pink
        case .reflection:
            return .orange
        }
    }
}

// MARK: - Preview
struct JournalTemplatesView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        let viewModel = JournalViewModel(dataManager: dataManager, encryptionService: encryptionService)
        
        JournalTemplatesView(viewModel: viewModel)
    }
}
