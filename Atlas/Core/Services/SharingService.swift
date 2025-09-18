import Foundation
import UIKit
import SwiftUI
import MessageUI

/// Service for sharing notes and content to other apps
@MainActor
class SharingService: NSObject, ObservableObject {
    
    static let shared = SharingService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Sharing Types
    
    enum SharingDestination: String, CaseIterable {
        case messages = "Messages"
        case mail = "Mail"
        case copy = "Copy to Clipboard"
        case activityView = "Share..."
        case linkedin = "LinkedIn"
        case slack = "Slack"
        case whatsapp = "WhatsApp"
        case telegram = "Telegram"
        
        var icon: String {
            switch self {
            case .messages: return "message.fill"
            case .mail: return "envelope.fill"
            case .copy: return "doc.on.clipboard.fill"
            case .activityView: return "square.and.arrow.up"
            case .linkedin: return "person.crop.circle"
            case .slack: return "bubble.left.and.bubble.right"
            case .whatsapp: return "phone.fill"
            case .telegram: return "paperplane.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .messages: return .green
            case .mail: return .blue
            case .copy: return .gray
            case .activityView: return .blue
            case .linkedin: return .blue
            case .slack: return .purple
            case .whatsapp: return .green
            case .telegram: return .blue
            }
        }
        
        @MainActor var isAvailable: Bool {
            switch self {
            case .messages:
                return MFMessageComposeViewController.canSendText()
            case .mail:
                return MFMailComposeViewController.canSendMail()
            case .copy, .activityView:
                return true
            case .linkedin, .slack, .whatsapp, .telegram:
                return true // These will use URL schemes
            }
        }
    }
    
    struct ShareContent {
        let title: String
        let content: String
        let url: URL?
        let image: UIImage?
        let attachments: [URL]
        
        init(title: String, content: String, url: URL? = nil, image: UIImage? = nil, attachments: [URL] = []) {
            self.title = title
            self.content = content
            self.url = url
            self.image = image
            self.attachments = attachments
        }
    }
    
    // MARK: - Share Methods
    
    /// Share a single note
    func shareNote(_ note: Note, destination: SharingDestination? = nil) {
        let shareContent = ShareContent(
            title: note.title ?? "Untitled Note",
            content: note.content ?? "",
            url: nil,
            image: nil,
            attachments: []
        )
        
        share(content: shareContent, destination: destination)
    }
    
    /// Share multiple notes
    func shareNotes(_ notes: [Note], destination: SharingDestination? = nil) {
        let title = notes.count == 1 ? (notes.first?.title ?? "Note") : "\(notes.count) Notes from Atlas"
        let content = notes.map { note in
            let noteTitle = note.title ?? "Untitled"
            let noteContent = note.content ?? ""
            return "# \(noteTitle)\n\n\(noteContent)\n\n---\n"
        }.joined(separator: "\n")
        
        let shareContent = ShareContent(
            title: title,
            content: content,
            url: nil,
            image: nil,
            attachments: []
        )
        
        share(content: shareContent, destination: destination)
    }
    
    /// Share content with specific destination
    func share(content: ShareContent, destination: SharingDestination? = nil) {
        if let destination = destination {
            shareToSpecificDestination(content: content, destination: destination)
        } else {
            showActivityView(content: content)
        }
    }
    
    // MARK: - Private Methods
    
    private func shareToSpecificDestination(content: ShareContent, destination: SharingDestination) {
        DispatchQueue.main.async {
            switch destination {
            case .copy:
                self.copyToClipboard(content: content)
            case .messages:
                self.shareToMessages(content: content)
            case .mail:
                self.shareToMail(content: content)
            case .linkedin:
                self.shareToLinkedIn(content: content)
            case .slack:
                self.shareToSlack(content: content)
            case .whatsapp:
                self.shareToWhatsApp(content: content)
            case .telegram:
                self.shareToTelegram(content: content)
            case .activityView:
                self.showActivityView(content: content)
            }
        }
    }
    
    private func copyToClipboard(content: ShareContent) {
        let textToCopy = formatContentForSharing(content: content)
        UIPasteboard.general.string = textToCopy
        
        // Show success feedback
        AtlasTheme.Haptics.success()
        
        // Show notification (would need to implement a notification system)
        print("📋 Content copied to clipboard")
    }
    
    private func shareToMessages(content: ShareContent) {
        guard MFMessageComposeViewController.canSendText() else {
            openURLFallback(content: content, appName: "Messages")
            return
        }
        
        let messageViewController = MFMessageComposeViewController()
        messageViewController.messageComposeDelegate = self
        messageViewController.body = formatContentForSharing(content: content)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(messageViewController, animated: true)
        }
    }
    
    private func shareToMail(content: ShareContent) {
        guard MFMailComposeViewController.canSendMail() else {
            openURLFallback(content: content, appName: "Mail")
            return
        }
        
        let mailViewController = MFMailComposeViewController()
        mailViewController.mailComposeDelegate = self
        mailViewController.setSubject(content.title)
        mailViewController.setMessageBody(formatContentForSharing(content: content), isHTML: false)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(mailViewController, animated: true)
        }
    }
    
    
    private func shareToLinkedIn(content: ShareContent) {
        let linkedInText = formatContentForSocial(content: content)
        let linkedInURL = "https://www.linkedin.com/sharing/share-offsite/?url=\(linkedInText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: linkedInURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareToSlack(content: ShareContent) {
        // Slack deep link
        let slackText = formatContentForSharing(content: content)
        let slackURL = "slack://open?team=&id=&message=\(slackText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: slackURL) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback to web version
                    let webURL = "https://slack.com"
                    if let webURL = URL(string: webURL) {
                        UIApplication.shared.open(webURL)
                    }
                }
            }
        }
    }
    
    private func shareToWhatsApp(content: ShareContent) {
        let whatsAppText = formatContentForSharing(content: content)
        let whatsAppURL = "whatsapp://send?text=\(whatsAppText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: whatsAppURL) {
            UIApplication.shared.open(url) { success in
                if !success {
                    self.openURLFallback(content: content, appName: "WhatsApp")
                }
            }
        }
    }
    
    private func shareToTelegram(content: ShareContent) {
        let telegramText = formatContentForSharing(content: content)
        let telegramURL = "tg://msg?text=\(telegramText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: telegramURL) {
            UIApplication.shared.open(url) { success in
                if !success {
                    self.openURLFallback(content: content, appName: "Telegram")
                }
            }
        }
    }
    
    private func showActivityView(content: ShareContent) {
        var itemsToShare: [Any] = []
        
        // Add title and content
        let textToShare = formatContentForSharing(content: content)
        itemsToShare.append(textToShare)
        
        // Add URL if available
        if let url = content.url {
            itemsToShare.append(url)
        }
        
        // Add image if available
        if let image = content.image {
            itemsToShare.append(image)
        }
        
        // Add attachments if available
        itemsToShare.append(contentsOf: content.attachments)
        
        let activityViewController = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityViewController, animated: true)
        }
    }
    
    // MARK: - Content Formatting
    
    private func formatContentForSharing(content: ShareContent) -> String {
        return """
        \(content.title)
        \(String(repeating: "=", count: content.title.count))
        
        \(content.content)
        
        ---
        Shared from Atlas Notes
        """
    }
    
    
    private func formatContentForSocial(content: ShareContent) -> String {
        return """
        \(content.title)
        
        \(content.content)
        
        #AtlasNotes #Productivity
        """
    }
    
    private func openURLFallback(content: ShareContent, appName: String) {
        // Copy content to clipboard as fallback
        copyToClipboard(content: content)
        
        // Show alert that content was copied
        print("📱 \(appName) is not available. Content copied to clipboard instead.")
    }
}

// MARK: - Message Compose Delegate

extension SharingService: MFMessageComposeViewControllerDelegate {
    nonisolated func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        _Concurrency.Task { @MainActor in
            controller.dismiss(animated: true) {
                _Concurrency.Task { @MainActor in
                    switch result {
                    case .sent:
                        AtlasTheme.Haptics.success()
                        print("✅ Message sent successfully")
                    case .cancelled:
                        AtlasTheme.Haptics.light()
                        print("❌ Message cancelled")
                    case .failed:
                        AtlasTheme.Haptics.error()
                        print("⚠️ Message failed to send")
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}

// MARK: - Mail Compose Delegate

extension SharingService: MFMailComposeViewControllerDelegate {
    nonisolated func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        _Concurrency.Task { @MainActor in
            controller.dismiss(animated: true) {
                _Concurrency.Task { @MainActor in
                    switch result {
                    case .sent:
                        AtlasTheme.Haptics.success()
                        print("✅ Email sent successfully")
                    case .saved:
                        AtlasTheme.Haptics.light()
                        print("💾 Email saved as draft")
                    case .cancelled:
                        AtlasTheme.Haptics.light()
                        print("❌ Email cancelled")
                    case .failed:
                        AtlasTheme.Haptics.error()
                        print("⚠️ Email failed to send: \(error?.localizedDescription ?? "Unknown error")")
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}
