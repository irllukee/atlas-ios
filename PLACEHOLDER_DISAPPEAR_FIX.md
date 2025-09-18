# Placeholder Text Disappear Fix

## Problem Fixed
The placeholder text "Start writing..." was staying visible even when the user tapped into the note and the cursor appeared, creating a confusing user experience.

## Root Cause
The placeholder text was only checking if `content.isEmpty` but not considering whether the TextEditor was focused. This meant the placeholder would remain visible even when the user was actively typing.

## Solution Implemented
Updated the placeholder text condition to also check if the TextEditor is focused:

```swift
// Before
if content.isEmpty {
    Text("Start writing...")
    // ... placeholder text
}

// After  
if content.isEmpty && !isContentFocused {
    Text("Start writing...")
    // ... placeholder text
}
```

## Result
- ✅ Placeholder text now disappears immediately when user taps into the note
- ✅ Clean, professional user experience that matches iOS design patterns
- ✅ No more confusing overlap between placeholder text and cursor
- ✅ Placeholder reappears when user taps away and note is empty

## Additional Fix
Also fixed a build error in `ExportService.swift` where there was corrupted code (`-0[l/[]`) that was causing compilation failures.

## Files Modified
- `Atlas/Views/Notes/CreateNoteView.swift` - Updated placeholder text condition
- `Atlas/Core/Services/ExportService.swift` - Fixed corrupted code line

## Testing
- ✅ Build successful with no errors
- ✅ App launched successfully in simulator
- ✅ Placeholder text behavior fixed and ready for testing
