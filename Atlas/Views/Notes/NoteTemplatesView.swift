import SwiftUI

/// View for selecting note templates
struct NoteTemplatesView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.getNoteTemplates(), id: \.title) { template in
                    TemplateRowView(template: template) {
                        viewModel.createNoteFromTemplate(template)
                    }
                }
            }
            .navigationTitle("Note Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Template Row View
struct TemplateRowView: View {
    let template: NoteTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(template.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if template.isEncrypted {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                Text(template.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                if let category = template.category {
                    Text(category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct NoteTemplatesView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        let viewModel = NotesViewModel(dataManager: dataManager, encryptionService: encryptionService)
        
        NoteTemplatesView(viewModel: viewModel)
    }
}
