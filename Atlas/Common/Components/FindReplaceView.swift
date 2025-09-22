import SwiftUI

struct FindReplaceView: View {
    @Binding var searchText: String
    @Binding var replaceText: String
    @Binding var foundRanges: [NSRange]
    @Binding var currentMatchIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    let onFind: () -> Void
    let onReplace: () -> Void
    let onReplaceAll: () -> Void
    let onSelectMatch: (Int) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Find")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Search text", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            onFind()
                        }
                }
                
                // Replace Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Replace")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Replacement text", text: $replaceText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Results
                if !foundRanges.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Found \(foundRanges.count) match\(foundRanges.count == 1 ? "" : "es")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Match navigation
                        HStack {
                            Button(action: {
                                if currentMatchIndex > 0 {
                                    currentMatchIndex -= 1
                                    onSelectMatch(currentMatchIndex)
                                }
                            }) {
                                Image(systemName: "chevron.up")
                            }
                            .disabled(currentMatchIndex <= 0)
                            
                            Text("\(currentMatchIndex + 1) of \(foundRanges.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                if currentMatchIndex < foundRanges.count - 1 {
                                    currentMatchIndex += 1
                                    onSelectMatch(currentMatchIndex)
                                }
                            }) {
                                Image(systemName: "chevron.down")
                            }
                            .disabled(currentMatchIndex >= foundRanges.count - 1)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button("Find") {
                            onFind()
                        }
                        .buttonStyle(.bordered)
                        .disabled(searchText.isEmpty)
                        
                        Button("Replace") {
                            onReplace()
                        }
                        .buttonStyle(.bordered)
                        .disabled(searchText.isEmpty || foundRanges.isEmpty)
                        
                        Button("Replace All") {
                            onReplaceAll()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(searchText.isEmpty)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Find & Replace")
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
