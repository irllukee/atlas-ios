# AztecEditor-iOS Setup Guide

This guide will help you integrate the AztecEditor-iOS library into your Atlas project for better rich text editing capabilities.

## Option 1: Using Xcode Package Manager (Recommended)

1. **Open your Atlas.xcodeproj in Xcode**

2. **Add Package Dependency:**
   - In Xcode, go to `File` → `Add Package Dependencies...`
   - Enter the URL: `https://github.com/wordpress-mobile/AztecEditor-iOS`
   - Click `Add Package`
   - Select version `1.20.0` or later
   - Click `Add Package` again

3. **Add to Target:**
   - In the package selection screen, select both:
     - `Aztec` (for basic rich text editing)
     - `WordPressEditor` (for WordPress-specific features)
   - Make sure they're added to your `Atlas` target
   - Click `Add Package`

4. **Build Settings:**
   - Go to your target's `Build Settings`
   - Add `$(SDKROOT)/usr/include/libxml2/` to `Header Search Paths`
   - This is required for Aztec's HTML parsing capabilities

## Option 2: Using Swift Package Manager (Alternative)

If you prefer using the Package.swift file I created:

1. **Open Terminal in your project directory**
2. **Run:** `swift package resolve`
3. **Open Atlas.xcodeproj**
4. **Add the resolved packages to your target**

## Verification

After adding the dependency:

1. **Build your project** (Cmd+B)
2. **Check that the import works** - the `#if canImport(Aztec)` condition should now be true
3. **Test the editor** - use `UnifiedRichTextEditor` in your views

## Usage

Replace your existing text editor usage with:

```swift
UnifiedRichTextEditor(
    content: $content,
    title: $title,
    placeholder: "Start writing..."
)
```

This will automatically use Aztec if available, or fall back to the simple implementation.

## Features Available with Aztec

- **Rich Text Formatting:** Bold, italic, underline, strikethrough
- **Headers:** H1, H2, H3 support
- **Lists:** Bulleted and numbered lists
- **Blockquotes:** Quote formatting
- **Code Blocks:** Pre-formatted code
- **Links:** URL insertion
- **Horizontal Rules:** Divider lines
- **HTML Export/Import:** Full HTML support

## Troubleshooting

### Build Errors
- Make sure `libxml2` is in your header search paths
- Ensure both `Aztec` and `WordPressEditor` are added to your target
- Clean build folder (Cmd+Shift+K) and rebuild

### Import Issues
- Verify the package was added correctly in Xcode
- Check that the target membership is correct
- Try removing and re-adding the package

### Runtime Issues
- The `UnifiedRichTextEditor` will automatically fall back to the simple editor if Aztec isn't available
- Check console for any delegate method errors

## Next Steps

1. **Test the basic functionality** with the new editor
2. **Customize the toolbar** if needed
3. **Add link dialog** for better link insertion
4. **Implement image support** if required
5. **Add custom formatting options** as needed

The AztecEditor-iOS library provides a much more robust foundation for rich text editing compared to the basic UITextView implementation.
