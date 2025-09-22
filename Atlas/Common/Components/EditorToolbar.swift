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
                    // Top control bar
                    HStack {
                        // Keyboard dismiss button
                        Button(action: {
                            dismissKeyboard()
                        }) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(.quaternary)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        // Close toolbar button
                        Button(action: {
                            showToolbar = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(.quaternary)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    // Formatting buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Text Formatting
                            modernFormatButton(icon: "bold", action: { controller.bold(); controller.focus() })
                            modernFormatButton(icon: "italic", action: { controller.italic(); controller.focus() })
                            modernFormatButton(icon: "underline", action: { controller.underline(); controller.focus() })
                            modernFormatButton(icon: "strikethrough", action: { controller.strikethrough(); controller.focus() })
                            
                            modernDivider()
                            
                            // Headers
                            modernFormatButton(icon: "textformat.size", action: { controller.header1(); controller.focus() })
                            modernFormatButton(icon: "textformat.alt", action: { controller.header2(); controller.focus() })
                            modernFormatButton(icon: "textformat", action: { controller.header3(); controller.focus() })
                            
                            modernDivider()
                            
                            // Lists
                            modernFormatButton(icon: "list.bullet", action: { controller.bulletList(); controller.focus() })
                            modernFormatButton(icon: "list.number", action: { controller.numberedList(); controller.focus() })
                            
                            modernDivider()
                            
                            // Other
                            modernFormatButton(icon: "quote.bubble", action: { controller.quote(); controller.focus() })
                            modernFormatButton(icon: "chevron.left.forwardslash.chevron.right", action: { controller.code(); controller.focus() })
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -8)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity).animation(.spring(response: 0.6, dampingFraction: 0.8)),
                    removal: .move(edge: .bottom).combined(with: .opacity).animation(.easeInOut(duration: 0.3))
                ))
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
    
    private func modernFormatButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.quaternary)
                        .overlay(
                            Circle()
                                .stroke(.quaternary, lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: UUID())
    }
    
    private func modernDivider() -> some View {
        Rectangle()
            .fill(.quaternary)
            .frame(width: 1, height: 24)
            .padding(.horizontal, 4)
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
