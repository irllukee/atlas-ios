import SwiftUI

struct EditorToolbar: View {
    @ObservedObject var controller: AztecEditorController

    var body: some View {
        HStack(spacing: 14) {
            Button("B") { controller.bold(); controller.focus() }
                .font(.system(size: 16, weight: .bold))

            Button("I") { controller.italic(); controller.focus() }
                .italic()

            Button("U") { controller.underline(); controller.focus() }
                .underline()
        }
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(radius: 2)
    }
}
