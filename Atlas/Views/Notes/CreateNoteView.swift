import SwiftUI
import CoreData
import PhotosUI
import AVFoundation
import AVKit

// MARK: - NoteImage Model
struct NoteImage: Identifiable, Equatable {
    let id = UUID()
    var imageData: Data
    var position: CGPoint
    var size: CGSize
    var textWrap: TextWrapMode
    var isSelected: Bool = false
    
    var image: UIImage? {
        return UIImage(data: imageData)
    }
    
    enum TextWrapMode: String, CaseIterable {
        case inline = "Inline"
        case square = "Square"
        case tight = "Tight"
        case through = "Through"
        case topAndBottom = "Top and Bottom"
        case behind = "Behind Text"
        case inFront = "In Front of Text"
    }
}

/// Modern iOS Notes-style view for creating and editing notes
struct CreateNoteView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    
    let noteToEdit: Note?
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var attributedContent: NSAttributedString = NSAttributedString()
    @State private var isEncrypted: Bool = false
    @State private var richTextEditor: RichTextEditor?
    @State private var isEditing = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var images: [NoteImage] = []
    @State private var selectedImageId: UUID?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingFormattingToolbar = false
    @State private var showingTagPicker = false
    @State private var selectedTags: Set<NoteTag> = []
    @State private var showingFolderPicker = false
    @State private var selectedFolder: NoteFolder?
    @State private var showingReminderPicker = false
    @State private var reminderDate: Date?
    @State private var showingShareSheet = false
    @State private var itemsToShare: [Any] = []
    
    // Rich text formatting states
           @State private var isBold = false
           @State private var isItalic = false
    @State private var isUnderline = false
           @State private var isStrikethrough = false
    @State private var selectedFontSize: CGFloat = 17
    @State private var selectedFontFamily = "System"
    @State private var selectedTextColor = Color.primary
    @State private var selectedBackgroundColor = Color.clear
           
           // Audio recording states
    @State private var isRecording = false
           @State private var audioRecorder: AVAudioRecorder?
           @State private var audioPlayer: AVAudioPlayer?
           @State private var recordingURL: URL?
    @State private var audioDuration: TimeInterval = 0
    @State private var showingAudioPlayer = false
    
    // Focus and keyboard states
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    // Animation states
    @State private var showSaveAnimation = false
    @State private var showDeleteAnimation = false
    
    init(viewModel: NotesViewModel, noteToEdit: Note? = nil) {
        self.viewModel = viewModel
        self.noteToEdit = noteToEdit
    }
    
    var body: some View {
        NavigationView {
                VStack(spacing: 0) {
                // Title Section
                titleSection
                
                // Content Section
                contentSection
                
                // Formatting Toolbar
                if showingFormattingToolbar {
                    formattingToolbar
                }
                
                Spacer()
            }
            .navigationTitle(noteToEdit != nil ? "Edit Note" : "New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(title.isEmpty && content.isEmpty)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                               Spacer()
                    Button("Done") {
                        isContentFocused = false
                    }
                }
            }
        }
               .onAppear {
            setupForEditing()
               }
               .onChange(of: selectedPhotoItem) { _, newItem in
                       loadPhoto(from: newItem)
                   }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedPhotoItem)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(selectedImage: $selectedPhotoItem)
        }
        .sheet(isPresented: $showingTagPicker) {
            NoteTagPickerView(selectedTags: $selectedTags, availableTags: viewModel.tags)
        }
        .sheet(isPresented: $showingFolderPicker) {
            FolderPickerView(selectedFolder: $selectedFolder, availableFolders: viewModel.folders)
        }
        .sheet(isPresented: $showingReminderPicker) {
            ReminderPickerView(reminderDate: $reminderDate)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: itemsToShare)
        }
        .confirmationDialog("Add Media", isPresented: $showingImagePicker) {
            Button("Photo Library") {
                showingImagePicker = true
            }
            Button("Camera") {
                showingCamera = true
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Title", text: $title)
                .font(.title2)
                .fontWeight(.semibold)
                .focused($isTitleFocused)
                .onSubmit {
                    isContentFocused = true
                }
            
            // Quick actions bar
            quickActionsBar
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Quick Actions Bar
    private var quickActionsBar: some View {
        HStack(spacing: 16) {
            // Formatting toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingFormattingToolbar.toggle()
                }
            }) {
                Image(systemName: "textformat")
                    .foregroundColor(showingFormattingToolbar ? .blue : .secondary)
            }
            
            // Add image
                        Button(action: {
                showingImagePicker = true
            }) {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }
            
            // Add audio
                   Button(action: {
                if isRecording {
                    stopRecording()
                       } else {
                    startRecording()
                }
            }) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle")
                    .foregroundColor(isRecording ? .red : .secondary)
            }
            
            // Tags
            Button(action: {
                showingTagPicker = true
            }) {
                Image(systemName: "tag")
                    .foregroundColor(selectedTags.isEmpty ? .secondary : .blue)
            }
            
            // Folder
                   Button(action: {
                showingFolderPicker = true
            }) {
                Image(systemName: "folder")
                    .foregroundColor(selectedFolder == nil ? .secondary : .blue)
            }
            
            // Reminder
                       Button(action: {
                showingReminderPicker = true
            }) {
                Image(systemName: reminderDate == nil ? "bell" : "bell.fill")
                    .foregroundColor(reminderDate == nil ? .secondary : .orange)
            }
                       
                       Spacer()
            
            // Share
                           Button(action: {
                prepareShareContent()
                showingShareSheet = true
                           }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.secondary)
                           }
                       }
        .font(.system(size: 18))
                       .padding(.vertical, 8)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(spacing: 0) {
            // Rich text editor
            NoteRichTextEditor(
                attributedText: $attributedContent,
                isBold: $isBold,
                isItalic: $isItalic,
                isUnderline: $isUnderline,
                isStrikethrough: $isStrikethrough,
                selectedFontSize: $selectedFontSize,
                selectedFontFamily: $selectedFontFamily,
                selectedTextColor: $selectedTextColor,
                selectedBackgroundColor: $selectedBackgroundColor
            )
            .focused($isContentFocused)
            .padding(.horizontal)
            
            // Images display
            if !images.isEmpty {
                imagesSection
            }
            
            // Audio player
            if let _ = recordingURL, audioDuration > 0 {
                audioPlayerSection
            }
        }
    }
    
    // MARK: - Images Section
    private var imagesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(images) { image in
                    imageView(for: image)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 120)
        .padding(.vertical, 8)
    }
    
    // MARK: - Image View
    private func imageView(for noteImage: NoteImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: noteImage.image ?? UIImage())
                               .resizable()
                               .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                               .overlay(
                                   RoundedRectangle(cornerRadius: 8)
                        .stroke(noteImage.isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
            
                           Button(action: {
                removeImage(noteImage.id)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: 8, y: -8)
        }
    }
    
    // MARK: - Audio Player Section
    private var audioPlayerSection: some View {
        VStack(spacing: 8) {
                   HStack {
                Button(action: {
                    if audioPlayer?.isPlaying == true {
                        audioPlayer?.pause()
                    } else {
                        playAudio()
                    }
                }) {
                    Image(systemName: audioPlayer?.isPlaying == true ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Text("Audio Recording")
                    .font(.caption)
                    .foregroundColor(.secondary)
                               
                               Spacer()
                               
                               Button(action: {
                    removeAudio()
                               }) {
                                   Image(systemName: "trash")
                                       .foregroundColor(.red)
                               }
                           }
            .padding(.horizontal)
                       .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Formatting Toolbar
    private var formattingToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            
            ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                    // Bold
                    Button(action: { isBold.toggle() }) {
                        Image(systemName: "bold")
                            .foregroundColor(isBold ? .blue : .secondary)
                    }
                    
                    // Italic
                    Button(action: { isItalic.toggle() }) {
                        Image(systemName: "italic")
                            .foregroundColor(isItalic ? .blue : .secondary)
                    }
                    
                    // Underline
                    Button(action: { isUnderline.toggle() }) {
                        Image(systemName: "underline")
                            .foregroundColor(isUnderline ? .blue : .secondary)
                    }
                    
                    // Strikethrough
                    Button(action: { isStrikethrough.toggle() }) {
                        Image(systemName: "strikethrough")
                            .foregroundColor(isStrikethrough ? .blue : .secondary)
                }
                
                Divider()
                        .frame(height: 20)
                    
                    // Font size
                Menu {
                        ForEach([12, 14, 16, 17, 18, 20, 24, 28, 32], id: \.self) { size in
                            Button("\(size)pt") {
                                selectedFontSize = CGFloat(size)
                            }
                    }
                } label: {
                        Text("\(Int(selectedFontSize))pt")
                            .foregroundColor(.secondary)
                    }
                    
                    // Text color
                    ColorPicker("Text Color", selection: $selectedTextColor)
                        .labelsHidden()
                        .frame(width: 30, height: 30)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Extensions
extension CreateNoteView {
    
    private func setupForEditing() {
        guard let note = noteToEdit else { return }
        
        title = note.title ?? ""
        content = note.content ?? ""
        isEncrypted = note.isEncrypted
        selectedFolder = note.folder
        // reminderDate = note.reminderDate // Note: reminderDate property not available in Note entity
        
        // Load tags
        if let tags = note.tags as? Set<NoteTag> {
            selectedTags = tags
        }
        
        // Load images
        // Note: imageData property not available in Note entity
        // if let imageDataArray = note.imageData {
        //     images = imageDataArray.compactMap { data in
        //         guard let imageData = data as? Data else { return nil }
        //         return NoteImage(
        //             imageData: imageData,
        //             position: .zero,
        //             size: CGSize(width: 100, height: 100),
        //             textWrap: .inline
        //         )
        //     }
        // }
        
        // Convert content to attributed string if needed
        if !content.isEmpty {
            attributedContent = NSAttributedString(string: content)
        }
    }
    
    private func saveNote() {
        let note = noteToEdit ?? Note(context: DataManager.shared.coreDataStack.viewContext)
        
        note.title = title.isEmpty ? nil : title
        note.content = content.isEmpty ? nil : content
        note.isEncrypted = isEncrypted
        note.folder = selectedFolder
        // note.reminderDate = reminderDate // Note: reminderDate property not available in Note entity
        // note.lastModified = Date() // Note: lastModified property not available in Note entity
        
        if noteToEdit == nil {
            note.createdAt = Date()
        }
        
        // Save tags
        note.tags = selectedTags as NSSet
        
        // Save images
        if !images.isEmpty {
            // note.imageData = images.map { $0.imageData } // Note: imageData property not available in Note entity
        }
        
        // Save audio
        if let recordingURL = recordingURL {
            // note.audioData = try? Data(contentsOf: recordingURL) // Note: audioData property not available in Note entity
        }
        
        do {
            try DataManager.shared.coreDataStack.viewContext.save()
            dismiss()
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Swift.Task { @MainActor in
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    let noteImage = NoteImage(
                        imageData: data,
                        position: .zero,
                        size: CGSize(width: 100, height: 100),
                        textWrap: .inline
                    )
                    images.append(noteImage)
                }
            }
        }
    }
    
    private func removeImage(_ imageId: UUID) {
        images.removeAll { $0.id == imageId }
    }
    
    private func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self as? AVAudioRecorderDelegate
            audioRecorder?.record()
            
            isRecording = true
            recordingURL = audioFilename
            
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        
        if let url = recordingURL {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioDuration = audioPlayer?.duration ?? 0
            } catch {
                print("Error creating audio player: \(error)")
            }
        }
    }
    
    private func playAudio() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            } else {
            player.play()
        }
    }
    
    private func removeAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        recordingURL = nil
        audioDuration = 0
    }
    
    private func prepareShareContent() {
        var shareItems: [Any] = []
        
        if !title.isEmpty {
            shareItems.append(title)
        }
        
        if !content.isEmpty {
            shareItems.append(content)
        }
        
        for image in images {
            if let uiImage = image.image {
                shareItems.append(uiImage)
            }
        }
        
        itemsToShare = shareItems
    }
}

// MARK: - Supporting Views
struct NoteRichTextEditor: View {
    @Binding var attributedText: NSAttributedString
    @Binding var isBold: Bool
    @Binding var isItalic: Bool
    @Binding var isUnderline: Bool
    @Binding var isStrikethrough: Bool
    @Binding var selectedFontSize: CGFloat
    @Binding var selectedFontFamily: String
    @Binding var selectedTextColor: Color
    @Binding var selectedBackgroundColor: Color
    
    var body: some View {
        TextEditor(text: .constant(attributedText.string))
            .font(.system(size: selectedFontSize))
    }
}

struct NoteImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: NoteImagePicker
        
        init(_ parent: NoteImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    // Handle image selection
                }
            }
        }
        
        private func dismiss() {
            parent.dismiss()
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Handle camera capture
            dismiss()
        }
        
        private func dismiss() {
            parent.dismiss()
        }
    }
}

struct NoteTagPickerView: View {
    @Binding var selectedTags: Set<NoteTag>
    let availableTags: [NoteTag]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableTags, id: \.self) { tag in
                    Button(action: {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                            } else {
                            selectedTags.insert(tag)
                        }
                    }) {
                        HStack {
                            Text(tag.name ?? "")
                            Spacer()
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Tags")
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

struct FolderPickerView: View {
    @Binding var selectedFolder: NoteFolder?
    let availableFolders: [NoteFolder]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    selectedFolder = nil
                    dismiss()
                }) {
                    HStack {
                        Text("No Folder")
                Spacer()
                        if selectedFolder == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
                
                ForEach(availableFolders, id: \.self) { folder in
                    Button(action: {
                        selectedFolder = folder
                    dismiss()
                    }) {
                        HStack {
                            Text(folder.name ?? "")
                            Spacer()
                            if selectedFolder == folder {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Folder")
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

struct ReminderPickerView: View {
    @Binding var reminderDate: Date?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Set Reminder", selection: Binding(
                    get: { reminderDate ?? Date() },
                    set: { reminderDate = $0 }
                ), in: Date()...)
                .datePickerStyle(.wheel)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        reminderDate = nil
                    dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NoteShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    CreateNoteView(viewModel: NotesViewModel(dataManager: DataManager.shared, encryptionService: EncryptionService.shared))
}
