import Foundation
import SwiftUI
import EventKit
import Photos
@preconcurrency import UserNotifications
import UIKit

/// Centralized permission management for all app permissions
@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    // MARK: - Permission Types
    enum PermissionType: CaseIterable {
        case calendar
        case reminders
        case photos
        case notifications
        
        var title: String {
            switch self {
            case .calendar:
                return "Calendar Access"
            case .reminders:
                return "Reminders Access"
            case .photos:
                return "Photo Library Access"
            case .notifications:
                return "Notifications"
            }
        }
        
        var description: String {
            switch self {
            case .calendar:
                return "Access your calendar to create and manage events"
            case .reminders:
                return "Access reminders to sync your tasks and deadlines"
            case .photos:
                return "Access photos to attach images to your notes and tasks"
            case .notifications:
                return "Send you reminders and important updates"
            }
        }
        
        var icon: String {
            switch self {
            case .calendar:
                return "calendar"
            case .reminders:
                return "checklist"
            case .photos:
                return "photo"
            case .notifications:
                return "bell"
            }
        }
    }
    
    // MARK: - Permission Status
    enum PermissionStatus {
        case notDetermined
        case granted
        case denied
        case restricted
    }
    
    // MARK: - Permission Steps
    enum PermissionStep: CaseIterable {
        case calendar
        case reminders
        case photos
        case notifications
        case complete
        
        var title: String {
            switch self {
            case .calendar:
                return "Calendar Access"
            case .reminders:
                return "Reminders Access"
            case .photos:
                return "Photo Library Access"
            case .notifications:
                return "Notifications"
            case .complete:
                return "Setup Complete"
            }
        }
        
        var description: String {
            switch self {
            case .calendar:
                return "Access your calendar to create and manage events"
            case .reminders:
                return "Access reminders to sync your tasks and deadlines"
            case .photos:
                return "Access photos to attach images to your notes and tasks"
            case .notifications:
                return "Send you reminders and important updates"
            case .complete:
                return "All permissions have been configured"
            }
        }
        
        var icon: String {
            switch self {
            case .calendar:
                return "calendar"
            case .reminders:
                return "checklist"
            case .photos:
                return "photo"
            case .notifications:
                return "bell"
            case .complete:
                return "checkmark.circle.fill"
            }
        }
    }
    
    // MARK: - Published Properties
    @Published var currentPermissionStep: PermissionStep = .calendar
    @Published var permissionResults: [PermissionType: PermissionStatus] = [:]
    @Published var isOnboardingComplete = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let onboardingCompleteKey = "onboarding_complete"
    
    // MARK: - Initialization
    private init() {
        loadOnboardingState()
        checkAllPermissions()
    }
    
    // MARK: - Public Methods
    
    /// Request permission for a specific type
    func requestPermission(for type: PermissionType) async -> PermissionStatus {
        switch type {
        case .calendar:
            return await requestCalendarPermission()
        case .reminders:
            return await requestRemindersPermission()
        case .photos:
            return await requestPhotosPermission()
        case .notifications:
            return await requestNotificationsPermission()
        }
    }
    
    /// Move to the next permission step
    func nextStep() {
        let allSteps = PermissionStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentPermissionStep) else { return }
        
        if currentIndex < allSteps.count - 1 {
            currentPermissionStep = allSteps[currentIndex + 1]
        }
    }
    
    /// Complete the onboarding process
    func completeOnboarding() {
        isOnboardingComplete = true
        userDefaults.set(true, forKey: onboardingCompleteKey)
    }
    
    /// Reset onboarding (for testing)
    func resetOnboarding() {
        isOnboardingComplete = false
        currentPermissionStep = .calendar
        userDefaults.removeObject(forKey: onboardingCompleteKey)
    }
    
    // MARK: - Private Methods
    
    private func loadOnboardingState() {
        isOnboardingComplete = userDefaults.bool(forKey: onboardingCompleteKey)
    }
    
    private func checkAllPermissions() {
        _Concurrency.Task {
            for type in PermissionType.allCases {
                let status = await checkPermissionStatus(for: type)
                await MainActor.run {
                    permissionResults[type] = status
                }
            }
        }
    }
    
    private func checkPermissionStatus(for type: PermissionType) async -> PermissionStatus {
        switch type {
        case .calendar:
            return await checkCalendarPermission()
        case .reminders:
            return await checkRemindersPermission()
        case .photos:
            return await checkPhotosPermission()
        case .notifications:
            return await checkNotificationsPermission()
        }
    }
    
    // MARK: - Calendar Permission
    
    private func requestCalendarPermission() async -> PermissionStatus {
        do {
            let eventStore = EKEventStore()
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                return granted ? .granted : .denied
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                return granted ? .granted : .denied
            }
        } catch {
            print("❌ Calendar permission request failed: \(error)")
            return .denied
        }
    }
    
    private func checkCalendarPermission() async -> PermissionStatus {
        if #available(iOS 17.0, *) {
            switch EKEventStore.authorizationStatus(for: .event) {
            case .notDetermined:
                return .notDetermined
            case .denied:
                return .denied
            case .authorized, .fullAccess:
                return .granted
            case .restricted:
                return .restricted
            case .writeOnly:
                return .denied
            @unknown default:
                return .notDetermined
            }
        } else {
            switch EKEventStore.authorizationStatus(for: .event) {
            case .notDetermined:
                return .notDetermined
            case .denied:
                return .denied
            case .authorized:
                return .granted
            case .restricted:
                return .restricted
            case .fullAccess:
                return .granted
            case .writeOnly:
                return .denied
            @unknown default:
                return .notDetermined
            }
        }
    }
    
    // MARK: - Reminders Permission
    
    private func requestRemindersPermission() async -> PermissionStatus {
        do {
            let eventStore = EKEventStore()
            if #available(iOS 17.0, *) {
                let granted = try await eventStore.requestFullAccessToReminders()
                return granted ? .granted : .denied
            } else {
                let granted = try await eventStore.requestAccess(to: .reminder)
                return granted ? .granted : .denied
            }
        } catch {
            print("❌ Reminders permission request failed: \(error)")
            return .denied
        }
    }
    
    private func checkRemindersPermission() async -> PermissionStatus {
        if #available(iOS 17.0, *) {
            switch EKEventStore.authorizationStatus(for: .reminder) {
            case .notDetermined:
                return .notDetermined
            case .denied:
                return .denied
            case .authorized, .fullAccess:
                return .granted
            case .restricted:
                return .restricted
            case .writeOnly:
                return .denied
            @unknown default:
                return .notDetermined
            }
        } else {
            switch EKEventStore.authorizationStatus(for: .reminder) {
            case .notDetermined:
                return .notDetermined
            case .denied:
                return .denied
            case .authorized:
                return .granted
            case .restricted:
                return .restricted
            case .fullAccess:
                return .granted
            case .writeOnly:
                return .denied
            @unknown default:
                return .notDetermined
            }
        }
    }
    
    // MARK: - Photos Permission
    
    private func requestPhotosPermission() async -> PermissionStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return mapPhotosPermissionStatus(status)
    }
    
    private func checkPhotosPermission() async -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return mapPhotosPermissionStatus(status)
    }
    
    private func mapPhotosPermissionStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .limited:
            return .granted
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
    
    // MARK: - Notifications Permission
    
    private func requestNotificationsPermission() async -> PermissionStatus {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted ? .granted : .denied
        } catch {
            print("❌ Notifications permission request failed: \(error)")
            return .denied
        }
    }
    
    private func checkNotificationsPermission() async -> PermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .granted
        case .provisional:
            return .granted
        case .ephemeral:
            return .granted
        @unknown default:
            return .notDetermined
        }
    }
}
