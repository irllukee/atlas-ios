import SwiftUI

struct LinkCreationView: View {
    @Binding var url: String
    @Binding var linkText: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Link Details") {
                    TextField("URL", text: $url)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Link Text (optional)", text: $linkText)
                        .textContentType(.none)
                }
                
                Section {
                    if !url.isEmpty {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            Text("Preview: \(linkText.isEmpty ? url : linkText)")
                                .foregroundColor(.blue)
                                .underline()
                        }
                    }
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle("Add Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        dismiss()
                    }
                    .disabled(url.isEmpty)
                }
            }
        }
    }
}
