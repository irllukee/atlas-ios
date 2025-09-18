import SwiftUI

struct BookmarkView: View {
    @StateObject private var bookmarkService = BookmarkService.shared
    @ObservedObject var note: Note
    @State private var showingAddBookmark = false
    @State private var newBookmarkName = ""
    @State private var selectedPosition: Int32 = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.orange)
                Text("Bookmarks")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    showingAddBookmark = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            if bookmarkService.getBookmarks(for: note).isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No bookmarks yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Tap + to add bookmarks for quick navigation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(bookmarkService.getBookmarks(for: note), id: \.objectID) { bookmark in
                            BookmarkRowView(bookmark: bookmark)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            bookmarkService.loadBookmarks(for: note)
        }
        .sheet(isPresented: $showingAddBookmark) {
            AddBookmarkView(note: note, selectedPosition: $selectedPosition)
        }
    }
}

struct BookmarkRowView: View {
    @StateObject private var bookmarkService = BookmarkService.shared
    @ObservedObject var bookmark: NoteBookmark
    @State private var showingEditBookmark = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            Image(systemName: "bookmark.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.name ?? "Untitled Bookmark")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Position: \(bookmark.position)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                bookmarkService.jumpToBookmark(bookmark)
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            
            Menu {
                Button("Edit") {
                    showingEditBookmark = true
                }
                
                Button("Delete", role: .destructive) {
                    showingDeleteAlert = true
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .sheet(isPresented: $showingEditBookmark) {
            EditBookmarkView(bookmark: bookmark)
        }
        .alert("Delete Bookmark", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                bookmarkService.deleteBookmark(bookmark)
            }
        } message: {
            Text("Are you sure you want to delete this bookmark?")
        }
    }
}

struct AddBookmarkView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var bookmarkService = BookmarkService.shared
    @ObservedObject var note: Note
    @Binding var selectedPosition: Int32
    @State private var bookmarkName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bookmark Name")
                        .font(.headline)
                    TextField("Enter bookmark name", text: $bookmarkName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Position in Note")
                        .font(.headline)
                    HStack {
                        Text("Position:")
                        Spacer()
                        TextField("0", value: $selectedPosition, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !bookmarkName.isEmpty {
                            bookmarkService.createBookmark(
                                in: note,
                                name: bookmarkName,
                                position: selectedPosition
                            )
                            dismiss()
                        }
                    }
                    .disabled(bookmarkName.isEmpty)
                }
            }
        }
    }
}

struct EditBookmarkView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var bookmarkService = BookmarkService.shared
    @ObservedObject var bookmark: NoteBookmark
    @State private var bookmarkName: String
    @State private var position: Int32
    
    init(bookmark: NoteBookmark) {
        self.bookmark = bookmark
        self._bookmarkName = State(initialValue: bookmark.name ?? "")
        self._position = State(initialValue: bookmark.position)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bookmark Name")
                        .font(.headline)
                    TextField("Enter bookmark name", text: $bookmarkName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Position in Note")
                        .font(.headline)
                    HStack {
                        Text("Position:")
                        Spacer()
                        TextField("0", value: $position, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        bookmarkService.updateBookmark(
                            bookmark,
                            name: bookmarkName,
                            position: position
                        )
                        dismiss()
                    }
                    .disabled(bookmarkName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let note = Note(context: context)
    note.title = "Sample Note"
    note.content = "This is a sample note for preview"
    return BookmarkView(note: note)
}
