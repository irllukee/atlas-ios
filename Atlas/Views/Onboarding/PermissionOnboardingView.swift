import SwiftUI
import EventKit
import Photos
import UIKit

/// Permission onboarding splash screen that shows only once
struct PermissionOnboardingView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var isAnimating = false
    @State private var showPermissionAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // Atlas app background
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header with Atlas glassmorphism
                    VStack(spacing: AtlasTheme.Spacing.xl) {
                        ZStack {
                            // Glassmorphism background for icon
                            Circle()
                                .fill(AtlasTheme.Colors.glassBackground)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle()
                                        .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                                )
                                .shadow(color: AtlasTheme.Colors.glassShadow, radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(AtlasTheme.Colors.text)
                                .scaleEffect(isAnimating ? 1.05 : 1.0)
                                .animation(AtlasTheme.Animations.spring.repeatForever(autoreverses: true), value: isAnimating)
                        }
                        
                        VStack(spacing: AtlasTheme.Spacing.md) {
                            Text("Welcome to Atlas")
                                .font(AtlasTheme.Typography.display)
                                .foregroundColor(AtlasTheme.Colors.text)
                            
                            Text("Let's set up your permissions")
                                .font(AtlasTheme.Typography.title3)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, AtlasTheme.Spacing.xxxl)
                    
                    // Permission Cards with Atlas spacing
                    LazyVStack(spacing: AtlasTheme.Spacing.md) {
                        ForEach(PermissionManager.PermissionStep.allCases.filter { $0 != .complete }, id: \.self) { step in
                            PermissionCard(
                                step: step,
                                isActive: permissionManager.currentPermissionStep == step,
                                status: getPermissionStatus(for: step),
                                onTap: {
                                    requestPermissionForStep(step)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    
                    // Complete Button with Atlas glassmorphism
                    if permissionManager.currentPermissionStep == .complete {
                        Button(action: {
                            permissionManager.completeOnboarding()
                        }) {
                            HStack(spacing: AtlasTheme.Spacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Get Started")
                                    .font(AtlasTheme.Typography.button)
                            }
                            .foregroundColor(AtlasTheme.Colors.textOnPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AtlasTheme.Spacing.lg)
                            .glassmorphism(style: .floating, cornerRadius: AtlasTheme.CornerRadius.large)
                            .overlay(
                                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.large)
                                    .fill(AtlasTheme.Colors.success.opacity(0.2))
                            )
                        }
                        .padding(.horizontal, AtlasTheme.Spacing.lg)
                        .padding(.bottom, AtlasTheme.Spacing.xxxl)
                    }
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("OK") {
                showPermissionAlert = false
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getPermissionStatus(for step: PermissionManager.PermissionStep) -> PermissionManager.PermissionStatus? {
        switch step {
        case .calendar:
            return permissionManager.permissionResults[.calendar]
        case .reminders:
            return permissionManager.permissionResults[.reminders]
        case .photos:
            return permissionManager.permissionResults[.photos]
        case .notifications:
            return permissionManager.permissionResults[.notifications]
        case .complete:
            return nil
        }
    }
    
    private func requestPermissionForStep(_ step: PermissionManager.PermissionStep) {
        guard let permissionType = getPermissionType(for: step) else { return }
        
        _Concurrency.Task {
            let status = await permissionManager.requestPermission(for: permissionType)
            
            await MainActor.run {
                if status == .granted {
                    permissionManager.nextStep()
                } else if status == .denied {
                    alertMessage = "Permission was denied. You can change this later in Settings > Privacy & Security."
                    showPermissionAlert = true
                    permissionManager.nextStep()
                }
            }
        }
    }
    
    private func getPermissionType(for step: PermissionManager.PermissionStep) -> PermissionManager.PermissionType? {
        switch step {
        case .calendar:
            return .calendar
        case .reminders:
            return .reminders
        case .photos:
            return .photos
        case .notifications:
            return .notifications
        case .complete:
            return nil
        }
    }
    
}

// MARK: - Permission Card Component
struct PermissionCard: View {
    let step: PermissionManager.PermissionStep
    let isActive: Bool
    let status: PermissionManager.PermissionStatus?
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AtlasTheme.Spacing.md) {
                // Icon with Atlas glassmorphism
                ZStack {
                    Circle()
                        .fill(AtlasTheme.Colors.glassBackground)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                        )
                        .shadow(color: AtlasTheme.Colors.glassShadow, radius: 8, x: 0, y: 4)
                    
                    Image(systemName: step.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(statusColor)
                }
                
                // Content with Atlas typography
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Text(step.title)
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    Text(step.description)
                        .font(AtlasTheme.Typography.callout)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                
                Spacer()
                
                // Arrow or status
                if let status = status {
                    Image(systemName: statusIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(statusColor)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AtlasTheme.Colors.tertiaryText)
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.lg)
            .padding(.vertical, AtlasTheme.Spacing.md)
            .glassmorphism(style: isActive ? .floating : .card, cornerRadius: AtlasTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.large)
                    .stroke(
                        isActive ? statusColor.opacity(0.3) : Color.clear,
                        lineWidth: isActive ? 2 : 0
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AtlasTheme.Animations.quick, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var statusColor: Color {
        guard let status = status else { return AtlasTheme.Colors.primary }
        
        switch status {
        case .notDetermined:
            return AtlasTheme.Colors.primary
        case .granted:
            return AtlasTheme.Colors.success
        case .denied:
            return AtlasTheme.Colors.error
        case .restricted:
            return AtlasTheme.Colors.warning
        }
    }
    
    private var statusIcon: String {
        guard let status = status else { return "questionmark.circle" }
        
        switch status {
        case .notDetermined:
            return "questionmark.circle"
        case .granted:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .restricted:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Preview
struct PermissionOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionOnboardingView()
    }
}
