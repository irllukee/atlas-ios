import SwiftUI

// MARK: - Toolbar Sections
enum ToolbarSection: CaseIterable {
    case formatting, structure, media, colors, lists, history
    
    var title: String {
        switch self {
        case .formatting: return "Text"
        case .structure: return "Style"
        case .media: return "Media"
        case .colors: return "Colors"
        case .lists: return "Lists"
        case .history: return "History"
        }
    }
    
    var icon: String {
        switch self {
        case .formatting: return "textformat"
        case .structure: return "textformat.size"
        case .media: return "photo"
        case .colors: return "paintpalette"
        case .lists: return "list.bullet"
        case .history: return "arrow.uturn.backward"
        }
    }
}

struct EditorToolbar: View {
    @ObservedObject var controller: AztecEditorController
    @State private var isKeyboardVisible = false
    @State private var showToolbar = false
    @State private var selectedSection: ToolbarSection = .formatting

    var body: some View {
        VStack {
            Spacer()
            
            if showToolbar && isKeyboardVisible {
                toolbarContent
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
    
    private var toolbarContent: some View {
        VStack(spacing: 0) {
            topControlBar
            sectionTabs
            sectionContent
        }
        .background(toolbarBackground)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity).animation(.spring(response: 0.6, dampingFraction: 0.8)),
            removal: .move(edge: .bottom).combined(with: .opacity).animation(.easeInOut(duration: 0.3))
        ))
    }
    
    private var topControlBar: some View {
        HStack {
            Button(action: dismissKeyboard) {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.quaternary))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Button(action: { showToolbar = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.quaternary))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    private var sectionTabs: some View {
        HStack(spacing: 0) {
            sectionTab(.formatting)
            sectionTab(.structure)
            sectionTab(.media)
            sectionTab(.colors)
            sectionTab(.lists)
            sectionTab(.history)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    private func sectionTab(_ section: ToolbarSection) -> some View {
        Button(action: { selectedSection = section }) {
            VStack(spacing: 4) {
                Image(systemName: section.icon)
                    .font(.system(size: 14, weight: .medium))
                Text(section.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedSection == section ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedSection == section ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var sectionContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                switch selectedSection {
                case .formatting:
                    formattingSection
                case .structure:
                    structureSection
                case .media:
                    mediaSection
                case .colors:
                    colorsSection
                case .lists:
                    listsSection
                case .history:
                    historySection
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }
    
    private var toolbarBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.quaternary, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -8)
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
    
    // MARK: - Section Content
    private var formattingSection: some View {
        HStack(spacing: 8) {
            modernFormatButton(icon: "bold", action: { controller.bold(); controller.focus() })
            modernFormatButton(icon: "italic", action: { controller.italic(); controller.focus() })
            modernFormatButton(icon: "underline", action: { controller.underline(); controller.focus() })
            modernFormatButton(icon: "strikethrough", action: { controller.strikethrough(); controller.focus() })
        }
    }
    
    private var structureSection: some View {
        HStack(spacing: 8) {
            modernFormatButton(icon: "textformat.size", action: { controller.header1(); controller.focus() })
            modernFormatButton(icon: "textformat.alt", action: { controller.header2(); controller.focus() })
            modernFormatButton(icon: "textformat", action: { controller.header3(); controller.focus() })
            modernFormatButton(icon: "quote.bubble", action: { controller.quote(); controller.focus() })
            modernFormatButton(icon: "chevron.left.forwardslash.chevron.right", action: { controller.code(); controller.focus() })
        }
    }
    
    private var mediaSection: some View {
        HStack(spacing: 8) {
            modernFormatButton(icon: "photo", action: { controller.insertImage(); controller.focus() })
            modernFormatButton(icon: "link", action: { controller.insertLink(); controller.focus() })
            modernFormatButton(icon: "minus", action: { controller.insertHorizontalRule(); controller.focus() })
        }
    }
    
    private var colorsSection: some View {
        HStack(spacing: 8) {
            modernFormatButton(icon: "textformat.abc", action: { controller.textColor(); controller.focus() })
            modernFormatButton(icon: "paintbrush", action: { controller.backgroundColor(); controller.focus() })
        }
    }
    
    private var listsSection: some View {
        HStack(spacing: 8) {
            modernFormatButton(icon: "list.bullet", action: { controller.bulletList(); controller.focus() })
            modernFormatButton(icon: "list.number", action: { controller.numberedList(); controller.focus() })
            modernFormatButton(icon: "indent", action: { controller.indentList(); controller.focus() })
            modernFormatButton(icon: "outdent", action: { controller.outdentList(); controller.focus() })
        }
    }
    
    private var historySection: some View {
        HStack(spacing: 8) {
            modernFormatButton(icon: "arrow.uturn.backward", action: { controller.undo(); controller.focus() })
            modernFormatButton(icon: "arrow.uturn.forward", action: { controller.redo(); controller.focus() })
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
