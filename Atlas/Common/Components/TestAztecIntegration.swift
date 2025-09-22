import SwiftUI

// MARK: - Test Aztec Integration
struct TestAztecIntegration: View {
    @State private var content = "<h1>Test Rich Text</h1><p>This is <strong>bold</strong> and <em>italic</em> text.</p>"
    @State private var title = "Aztec Test"
    
    var body: some View {
        VStack {
            Text("Aztec Integration Test")
                .font(.title)
                .padding()
            
            #if canImport(Aztec)
            Text("✅ Aztec is available!")
                .foregroundColor(.green)
                .padding()
            
            UnifiedRichTextEditor(
                content: $content,
                title: $title,
                placeholder: "Test the rich text editor..."
            )
            #else
            Text("❌ Aztec is not available")
                .foregroundColor(.red)
                .padding()
            
            Text("Please add the AztecEditor-iOS dependency")
                .foregroundColor(.orange)
                .padding()
            #endif
        }
        .padding()
    }
}

#Preview {
    TestAztecIntegration()
}
