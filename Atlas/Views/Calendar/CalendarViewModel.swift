import Foundation
import Combine
@preconcurrency import EventKit

@MainActor
class CalendarViewModel: ObservableObject {
    // MARK: - Properties
    private let calendarService: CalendarService
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var events: [EKEvent] = []
    @Published var calendars: [EKCalendar] = []
    @Published var selectedDate: Date = Date()
    @Published var selectedCalendar: EKCalendar?
    @Published var permissionStatus: CalendarPermissionStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingCreateEvent: Bool = false
    @Published var showingTimeBlocking: Bool = false
    @Published var calendarStatistics: CalendarStatistics = CalendarStatistics(
        totalEvents: 0,
        allDayEvents: 0,
        timedEvents: 0,
        totalDuration: 0,
        averageDuration: 0
    )
    
    // MARK: - Initialization
    init() {
        self.calendarService = CalendarService()
        
        setupBindings()
    }
    
    private func setupBindings() {
        calendarService.$events
            .assign(to: &$events)
        
        calendarService.$calendars
            .assign(to: &$calendars)
        
        calendarService.$permissionStatus
            .assign(to: &$permissionStatus)
        
        calendarService.$isLoading
            .assign(to: &$isLoading)
        
        calendarService.$errorMessage
            .assign(to: &$errorMessage)
        
        // Update statistics when events change
        calendarService.$events
            .sink { [weak self] _ in
                self?.updateStatistics()
            }
            .store(in: &cancellables)
        
        // Load events when selected date changes
        $selectedDate
            .sink { [weak self] date in
                self?.loadEventsForDate(date)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Request calendar permissions
    func requestCalendarAccess() async {
        let granted = await calendarService.requestCalendarAccess()
        if granted {
            selectedCalendar = calendarService.getDefaultCalendar()
        }
    }
    
    /// Load events for the selected date
    func loadEventsForDate(_ date: Date) {
        calendarService.loadEventsForDate(date)
    }
    
    /// Load events for the current week
    func loadEventsForWeek() {
        calendarService.loadEventsForWeek(containing: selectedDate)
    }
    
    /// Load events for the current month
    func loadEventsForMonth() {
        calendarService.loadEventsForMonth(containing: selectedDate)
    }
    
    /// Create a new event
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        notes: String? = nil,
        location: String? = nil,
        eventType: EventType = .personal,
        isAllDay: Bool = false,
        reminderMinutes: [Int] = [15]
    ) {
        isLoading = true
        errorMessage = nil
        
        let event = calendarService.createEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            location: location,
            eventType: eventType,
            calendar: selectedCalendar,
            isAllDay: isAllDay,
            reminderMinutes: reminderMinutes
        )
        
        if let event = event {
            // Schedule notification for the event
            notificationService.scheduleEventReminder(
                eventId: event.eventIdentifier,
                title: event.title ?? "Event",
                startDate: event.startDate
            )
            showingCreateEvent = false
            loadEventsForDate(selectedDate)
        }
        
        isLoading = false
    }
    
    /// Update an existing event
    func updateEvent(
        _ event: EKEvent,
        title: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        notes: String? = nil,
        location: String? = nil,
        isAllDay: Bool? = nil
    ) {
        isLoading = true
        errorMessage = nil
        
        let success = calendarService.updateEvent(
            event,
            title: title,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            location: location,
            isAllDay: isAllDay
        )
        
        if success {
            // Update notifications for the event
            notificationService.removeEventReminders(eventId: event.eventIdentifier)
            notificationService.scheduleEventReminder(
                eventId: event.eventIdentifier,
                title: title ?? event.title ?? "Event",
                startDate: startDate ?? event.startDate
            )
            loadEventsForDate(selectedDate)
        }
        
        isLoading = false
    }
    
    /// Delete an event
    func deleteEvent(_ event: EKEvent) {
        isLoading = true
        errorMessage = nil
        
        // Remove notifications before deleting event
        notificationService.removeEventReminders(eventId: event.eventIdentifier)
        
        let success = calendarService.deleteEvent(event)
        
        if success {
            loadEventsForDate(selectedDate)
        }
        
        isLoading = false
    }
    
    /// Create a time block
    func createTimeBlock(
        title: String,
        startDate: Date,
        duration: TimeInterval,
        notes: String? = nil
    ) {
        isLoading = true
        errorMessage = nil
        
        let event = calendarService.createTimeBlock(
            title: title,
            startDate: startDate,
            duration: duration,
            notes: notes
        )
        
        if event != nil {
            showingTimeBlocking = false
            loadEventsForDate(selectedDate)
        }
        
        isLoading = false
    }
    
    /// Find available time slots for a given duration
    func findAvailableTimeSlots(
        duration: TimeInterval,
        workingHours: (start: Int, end: Int) = (9, 17)
    ) -> [DateInterval] {
        return calendarService.findAvailableTimeSlots(
            for: selectedDate,
            duration: duration,
            workingHours: workingHours
        )
    }
    
    /// Sync a task with calendar
    func syncTaskWithCalendar(_ task: Task) {
        isLoading = true
        errorMessage = nil
        
        let event = calendarService.syncTaskWithCalendar(task)
        
        if event != nil {
            loadEventsForDate(selectedDate)
        }
        
        isLoading = false
    }
    
    /// Get events for a specific date
    func getEventsForDate(_ date: Date) -> [EKEvent] {
        return calendarService.getEventsForDate(date)
    }
    
    /// Get upcoming events
    func getUpcomingEvents(limit: Int = 10) -> [EKEvent] {
        return calendarService.getUpcomingEvents(limit: limit)
    }
    
    /// Get events by type
    func getEventsByType(_ type: EventType) -> [EKEvent] {
        return calendarService.getEventsByType(type)
    }
    
    /// Navigate to previous day
    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    /// Navigate to next day
    func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
    
    /// Navigate to today
    func goToToday() {
        selectedDate = Date()
    }
    
    /// Navigate to previous week
    func goToPreviousWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
    }
    
    /// Navigate to next week
    func goToNextWeek() {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
    }
    
    /// Navigate to previous month
    func goToPreviousMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    /// Navigate to next month
    func goToNextMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
    
    /// Check if a date has events
    func hasEventsOnDate(_ date: Date) -> Bool {
        return !getEventsForDate(date).isEmpty
    }
    
    /// Get the number of events on a specific date
    func getEventCountForDate(_ date: Date) -> Int {
        return getEventsForDate(date).count
    }
    
    // MARK: - Private Methods
    
    private func updateStatistics() {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate
        let monthInterval = DateInterval(start: startOfMonth, end: endOfMonth)
        
        calendarStatistics = calendarService.getEventStatistics(for: monthInterval)
    }
}
