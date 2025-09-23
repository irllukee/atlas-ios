# Atlas - Journal, Calendar & Todo Code

This folder contains a copy of all the journal, calendar, and todo/task related code from the Atlas iOS app.

## 📁 Folder Structure

### Views
- **Journal/** - All journal-related SwiftUI views
  - `CreateJournalEntryView.swift` - Create new journal entries
  - `EditJournalEntryView.swift` - Edit existing journal entries
  - `JournalView.swift` - Main journal view
  - `JournalViewModel.swift` - Journal view model
  - `JournalTemplatesView.swift` - Journal entry templates
  - `MoodTrackerView.swift` - Mood tracking functionality

- **Calendar/** - All calendar-related SwiftUI views
  - `CalendarView.swift` - Main calendar view
  - `CalendarViewModel.swift` - Calendar view model
  - `CreateEventView.swift` - Create calendar events
  - `EventDetailView.swift` - Event details view
  - `MonthGridView.swift` - Month calendar grid
  - `TimeBlockingView.swift` - Time blocking functionality
  - `WeekGridView.swift` - Week calendar grid

- **Tasks/** - All todo/task-related SwiftUI views
  - `CreateTaskView.swift` - Create new tasks
  - `EditTaskView.swift` - Edit existing tasks
  - `TabbedTasksView.swift` - Main tasks tab view
  - `TabbedTasksViewModel.swift` - Tasks tab view model
  - `TasksView.swift` - Main tasks view
  - `TasksViewModel.swift` - Tasks view model
  - `TasksFilterView.swift` - Task filtering
  - `TaskTemplatesView.swift` - Task templates
  - `TaskViewModelProtocol.swift` - Task view model protocol

### Services
- **Core/Services/** - Business logic services
  - `JournalService.swift` - Journal data management
  - `CalendarService.swift` - Calendar integration (EventKit)
  - `TasksService.swift` - Task data management

### Data Layer
- **Core/Data/Repositories/** - Data access layer
  - `TaskRepository.swift` - Task data repository

- **Core/Data/Atlas.xcdatamodeld/** - Core Data model
  - `contents` - Core Data model definition (contains Task, JournalEntry, MoodEntry entities)

## 🔧 Key Features

### Journal
- Create and edit journal entries
- Mood tracking with ratings and emojis
- Journal entry templates
- Search and filtering capabilities
- Encryption support for sensitive entries

### Calendar
- EventKit integration for system calendar access
- Month, week, and day views
- Event creation and management
- Time blocking functionality
- Calendar permission handling

### Tasks/Todos
- Task creation and management
- Priority levels and due dates
- Task categories and tabs
- Recurring tasks support
- Task templates
- Filtering and organization

## 📱 Technologies Used
- SwiftUI for UI
- Core Data for persistence
- EventKit for calendar integration
- Combine for reactive programming
- Encryption for data security

## ⚠️ Note
This is a copy of the code from the Atlas app. The original files remain in the app and are not affected by this copy.
