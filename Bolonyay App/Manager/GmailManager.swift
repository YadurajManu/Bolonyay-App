import Foundation
import UIKit
import MessageUI

class GmailManager {
    static let shared = GmailManager()
    
    private init() {}
    
    // MARK: - Gmail App Integration
    
    func sendEmailViaGmail(
        to recipient: String,
        subject: String,
        body: String,
        attachmentURL: URL? = nil,
        completion: @escaping (Bool, String) -> Void
    ) {
        if canOpenGmailApp() {
            openGmailApp(to: recipient, subject: subject, body: body, completion: completion)
        } else {
            showEmailOptions(to: recipient, subject: subject, body: body, attachmentURL: attachmentURL, completion: completion)
        }
    }
    
    private func canOpenGmailApp() -> Bool {
        guard let gmailURL = URL(string: "googlegmail://") else { return false }
        return UIApplication.shared.canOpenURL(gmailURL)
    }
    
    private func openGmailApp(
        to recipient: String,
        subject: String,
        body: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        let encodedRecipient = recipient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let gmailURLString = "googlegmail://co?to=\(encodedRecipient)&subject=\(encodedSubject)&body=\(encodedBody)"
        
        guard let gmailURL = URL(string: gmailURLString) else {
            completion(false, "Failed to create Gmail URL")
            return
        }
        
        UIApplication.shared.open(gmailURL) { success in
            DispatchQueue.main.async {
                if success {
                    completion(true, "Gmail app opened successfully")
                } else {
                    completion(false, "Failed to open Gmail app")
                }
            }
        }
    }
    
    private func showEmailOptions(
        to recipient: String,
        subject: String,
        body: String,
        attachmentURL: URL?,
        completion: @escaping (Bool, String) -> Void
    ) {
        let alert = UIAlertController(
            title: "📧 Choose Email Option",
            message: "Select how you'd like to send your email",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "🌐 Open Gmail Web", style: .default) { _ in
            self.openGmailWeb(to: recipient, subject: subject, body: body, completion: completion)
        })
        
        if canOpenYahooMail() {
            alert.addAction(UIAlertAction(title: "📧 Open Yahoo Mail", style: .default) { _ in
                self.openYahooMail(to: recipient, subject: subject, body: body, completion: completion)
            })
        }
        
        if canOpenOutlook() {
            alert.addAction(UIAlertAction(title: "📮 Open Outlook", style: .default) { _ in
                self.openOutlook(to: recipient, subject: subject, body: body, completion: completion)
            })
        }
        
        if MFMailComposeViewController.canSendMail() {
            alert.addAction(UIAlertAction(title: "✉️ Use Apple Mail", style: .default) { _ in
                self.openAppleMail(to: recipient, subject: subject, body: body, attachmentURL: attachmentURL, completion: completion)
            })
        }
        
        alert.addAction(UIAlertAction(title: "📤 Share via Other Apps", style: .default) { _ in
            self.shareViaOtherApps(content: "\(body)\n\nTo: \(recipient)\nSubject: \(subject)", attachmentURL: attachmentURL, completion: completion)
        })
        
        alert.addAction(UIAlertAction(title: "❌ Cancel", style: .cancel) { _ in
            completion(false, "Email cancelled")
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            if let popover = alert.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    // MARK: - Email App Checks
    
    private func canOpenYahooMail() -> Bool {
        guard let yahooURL = URL(string: "ymail://") else { return false }
        return UIApplication.shared.canOpenURL(yahooURL)
    }
    
    private func canOpenOutlook() -> Bool {
        guard let outlookURL = URL(string: "ms-outlook://") else { return false }
        return UIApplication.shared.canOpenURL(outlookURL)
    }
    
    // MARK: - Open Different Email Clients
    
    private func openGmailWeb(
        to recipient: String,
        subject: String,
        body: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        let encodedRecipient = recipient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let gmailWebURLString = "https://mail.google.com/mail/?view=cm&fs=1&to=\(encodedRecipient)&su=\(encodedSubject)&body=\(encodedBody)"
        
        guard let gmailWebURL = URL(string: gmailWebURLString) else {
            completion(false, "Failed to create Gmail web URL")
            return
        }
        
        UIApplication.shared.open(gmailWebURL) { success in
            DispatchQueue.main.async {
                if success {
                    completion(true, "Gmail web opened successfully")
                } else {
                    completion(false, "Failed to open Gmail web")
                }
            }
        }
    }
    
    private func openYahooMail(
        to recipient: String,
        subject: String,
        body: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        let encodedRecipient = recipient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let yahooURLString = "ymail://mail/compose?to=\(encodedRecipient)&subject=\(encodedSubject)&body=\(encodedBody)"
        
        guard let yahooURL = URL(string: yahooURLString) else {
            completion(false, "Failed to create Yahoo Mail URL")
            return
        }
        
        UIApplication.shared.open(yahooURL) { success in
            DispatchQueue.main.async {
                if success {
                    completion(true, "Yahoo Mail opened successfully")
                } else {
                    completion(false, "Failed to open Yahoo Mail")
                }
            }
        }
    }
    
    private func openOutlook(
        to recipient: String,
        subject: String,
        body: String,
        completion: @escaping (Bool, String) -> Void
    ) {
        let encodedRecipient = recipient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let outlookURLString = "ms-outlook://compose?to=\(encodedRecipient)&subject=\(encodedSubject)&body=\(encodedBody)"
        
        guard let outlookURL = URL(string: outlookURLString) else {
            completion(false, "Failed to create Outlook URL")
            return
        }
        
        UIApplication.shared.open(outlookURL) { success in
            DispatchQueue.main.async {
                if success {
                    completion(true, "Outlook opened successfully")
                } else {
                    completion(false, "Failed to open Outlook")
                }
            }
        }
    }
    
    private func openAppleMail(
        to recipient: String,
        subject: String,
        body: String,
        attachmentURL: URL?,
        completion: @escaping (Bool, String) -> Void
    ) {
        guard MFMailComposeViewController.canSendMail() else {
            completion(false, "Apple Mail is not configured")
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = MailCoordinator.shared
        mailComposer.setToRecipients([recipient])
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(body, isHTML: false)
        
        if let attachmentURL = attachmentURL {
            do {
                let attachmentData = try Data(contentsOf: attachmentURL)
                let fileName = attachmentURL.lastPathComponent
                let mimeType = getMimeType(for: attachmentURL)
                mailComposer.addAttachmentData(attachmentData, mimeType: mimeType, fileName: fileName)
            } catch {
                print("❌ Failed to attach file: \(error)")
            }
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(mailComposer, animated: true)
            completion(true, "Apple Mail composer opened")
        } else {
            completion(false, "Failed to present Apple Mail composer")
        }
    }
    
    private func shareViaOtherApps(
        content: String,
        attachmentURL: URL?,
        completion: @escaping (Bool, String) -> Void
    ) {
        var activityItems: [Any] = [content]
        
        if let attachmentURL = attachmentURL {
            activityItems.append(attachmentURL)
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        activityViewController.excludedActivityTypes = [
            .postToFacebook,
            .postToTwitter,
            .postToVimeo,
            .postToWeibo,
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .postToFlickr,
            .postToTencentWeibo
        ]
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            window.rootViewController?.present(activityViewController, animated: true)
            completion(true, "Share sheet opened")
        } else {
            completion(false, "Failed to present share sheet")
        }
    }
    
    // MARK: - Utility Methods
    
    private func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "txt":
            return "text/plain"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        default:
            return "application/octet-stream"
        }
    }
    
    // MARK: - Legal Document Email Templates
    
    func createLegalDocumentEmail(caseNumber: String, documentType: String) -> (subject: String, body: String) {
        let currentDate = DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short)
        
        let subject = "🏛️ Legal Document - \(documentType) - Case #\(caseNumber)"
        
        let body = """
        📧 Legal Document from BoloNyay Legal Assistant
        
        Dear Recipient,
        
        I hope this email finds you well. Please find attached the legal document generated through BoloNyay Legal Assistant platform.
        
        📋 Document Details:
        ───────────────────────
        • Case Reference: \(caseNumber)
        • Document Type: \(documentType)
        • Generated Date: \(currentDate)
        • Platform: BoloNyay Legal Assistant
        • Format: PDF Document
        
        📝 Important Information:
        ───────────────────────
        This document contains important case filing information and legal details that should be reviewed carefully by qualified legal professionals.
        
        The document has been generated using AI-assisted legal guidance and should be verified for accuracy and completeness before any official submission.
        
        📞 Need Help?
        ──────────────
        If you have any questions about this document or need further assistance, please don't hesitate to contact our support team.
        
        • Email: support@bolonyay.com
        • Website: www.bolonyay.com
        • Legal Helpline: +91-XXXXX-XXXXX
        
        🔒 Confidentiality Notice:
        ─────────────────────────
        This email and its attachments contain confidential legal information. If you are not the intended recipient, please delete this email immediately and notify the sender.
        
        Best regards,
        BoloNyay Legal Assistant Team
        
        ───────────────────────
        🌟 Powered by BoloNyay
        Making Legal Assistance Accessible to Everyone
        """
        
        return (subject: subject, body: body)
    }
}

// MARK: - Mail Coordinator Extension for Gmail Integration
extension MailCoordinator {
    static func sendViaGmail(to recipient: String, subject: String, body: String, attachmentURL: URL? = nil) {
        GmailManager.shared.sendEmailViaGmail(
            to: recipient,
            subject: subject,
            body: body,
            attachmentURL: attachmentURL
        ) { success, message in
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: success ? "✅ Success" : "❌ Error",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(alert, animated: true)
                }
            }
        }
    }
} 