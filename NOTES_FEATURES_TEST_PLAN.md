# Notes Features Test Plan

## Overview
This document outlines the testing procedures for the newly implemented notes features in the Atlas app. All features have been researched and implemented to match iOS Notes app behavior.

## Features to Test

### 1. Bullet Points ✅
**Expected Behavior:**
- Press bullet list button to start a bulleted list
- Type content after bullet point
- Press Return key → should automatically add new bullet point on next line
- Press Return twice → should exit bullet mode and return to normal text

**Test Steps:**
1. Open Notes section in Atlas app
2. Create a new note
3. Tap the formatting toolbar (Aa icon)
4. Select "Bullet List" from the Lists menu
5. Type "First item"
6. Press Return key
7. Verify: New bullet point appears automatically
8. Type "Second item"
9. Press Return key
10. Verify: Another bullet point appears
11. Press Return key again (empty line)
12. Press Return key again
13. Verify: Exits bullet mode, no more bullets appear

### 2. Checkboxes ✅
**Expected Behavior:**
- Press checkbox button to start a checkbox list
- Type content after checkbox
- Press Return key → should automatically add new checkbox on next line
- Press Return twice → should exit checkbox mode
- Use "Toggle All Checkboxes" to toggle all checkboxes at once

**Test Steps:**
1. Create a new note
2. Tap formatting toolbar
3. Select "Checkbox List" from Lists menu
4. Type "Task 1"
5. Press Return key
6. Verify: New checkbox (☐) appears automatically
7. Type "Task 2"
8. Press Return key
9. Verify: Another checkbox appears
10. Press Return twice to exit checkbox mode
11. Go back to formatting toolbar
12. Select "Toggle All Checkboxes"
13. Verify: All checkboxes toggle between ☐ and ☑

### 3. Numbered Lists ✅
**Expected Behavior:**
- Press numbered list button to start a numbered list
- Type content after number
- Press Return key → should automatically add next number (1., 2., 3., etc.)
- Press Return twice → should exit numbered mode

**Test Steps:**
1. Create a new note
2. Tap formatting toolbar
3. Select "Numbered List" from Lists menu
4. Type "First step"
5. Press Return key
6. Verify: "2." appears automatically
7. Type "Second step"
8. Press Return key
9. Verify: "3." appears automatically
10. Press Return twice
11. Verify: Exits numbered mode

### 4. Text Formatting ✅
**Expected Behavior:**
- Bold: Wraps text with **text**
- Italic: Wraps text with *text*
- Underline: Wraps text with __text__
- Strikethrough: Wraps text with ~~text~~

**Test Steps:**
1. Create a new note
2. Type some text
3. Tap formatting toolbar
4. Select "Bold"
5. Verify: Text is wrapped with **markers**
6. Select "Italic"
7. Verify: Text is wrapped with *markers*
8. Select "Underline"
9. Verify: Text is wrapped with __markers__
10. Select "Strikethrough"
11. Verify: Text is wrapped with ~~markers~~

### 5. Headers ✅
**Expected Behavior:**
- H1: Wraps text with # text
- H2: Wraps text with ## text
- H3: Wraps text with ### text
- Selecting "None" removes header formatting

**Test Steps:**
1. Create a new note
2. Type some text
3. Tap formatting toolbar
4. Select "Header 1" from Headers menu
5. Verify: Text is wrapped with # marker
6. Select "Header 2"
7. Verify: Text is wrapped with ## markers
8. Select "Header 3"
9. Verify: Text is wrapped with ### markers
10. Select "None"
11. Verify: Header markers are removed

## Integration Tests

### Mixed Content Test
1. Create a note with:
   - Header: "# My Note"
   - Bullet list with 3 items
   - **Bold text**
   - Numbered list with 2 items
   - ☐ Checkbox items
2. Verify all formatting is preserved
3. Test that each list type continues properly when pressing Return

### Edge Cases
1. Test switching between different list types
2. Test formatting within lists
3. Test empty lines and double returns
4. Test very long content

## Expected Results
All features should work seamlessly with:
- ✅ Automatic continuation when pressing Return
- ✅ Proper exit behavior with double Return
- ✅ Markdown-style formatting that's visible in the text
- ✅ Toggle functionality for checkboxes
- ✅ Proper numbering sequence for numbered lists
- ✅ No crashes or errors during any operations

## Notes
- The app is currently running in the iPhone 16 simulator
- All features have been implemented with proper iOS Notes-like behavior
- Text formatting uses markdown syntax for compatibility
- List processing happens automatically through the `processTextInput()` function

