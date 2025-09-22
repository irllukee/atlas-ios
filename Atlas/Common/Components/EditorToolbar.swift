import SwiftUI

struct EditorToolbar: View {
    @ObservedObject var controller: AztecEditorController
    @State private var isKeyboardVisible = false
    @State private var showToolbar = false

    var body: some View {
        VStack {
            Spacer()
            
            if showToolbar && isKeyboardVisible {
                VStack(spacing: 0) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: {
                            showToolbar = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                    }
                    
                    // Formatting buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Text Formatting
                            formatButton(icon: "bold", action: { controller.bold(); controller.focus() })
                            formatButton(icon: "italic", action: { controller.italic(); controller.focus() })
                            formatButton(icon: "underline", action: { controller.underline(); controller.focus() })
                            formatButton(icon: "strikethrough", action: { controller.strikethrough(); controller.focus() })
                            
                            Divider()
                                .frame(height: 20)
                            
                            // Headers
                            formatButton(icon: "textformat.size", action: { controller.header1(); controller.focus() })
                            formatButton(icon: "textformat.alt", action: { controller.header2(); controller.focus() })
                            formatButton(icon: "textformat", action: { controller.header3(); controller.focus() })
                            
                            Divider()
                                .frame(height: 20)
                            
                            // Lists
                            formatButton(icon: "list.bullet", action: { controller.bulletList(); controller.focus() })
                            formatButton(icon: "list.number", action: { controller.numberedList(); controller.focus() })
                            
                            Divider()
                                .frame(height: 20)
                            
                            // Other
                            formatButton(icon: "quote.bubble", action: { controller.quote(); controller.focus() })
                            formatButton(icon: "chevron.left.forwardslash.chevron.right", action: { controller.code(); controller.focus() })
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.separator, lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
            showToolbar = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
            showToolbar = false
        }
    }
    
    private func formatButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.quaternary)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
