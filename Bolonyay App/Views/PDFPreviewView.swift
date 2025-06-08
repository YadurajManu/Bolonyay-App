import SwiftUI
import PDFKit
import UIKit
import MessageUI

struct PDFPreviewView: View {
    let pdfURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showEmailComposer = false
    @State private var recipientEmail = ""
    @State private var showEmailInput = false
    @State private var emailSubject = "Legal Document - BoloNyay"
    @State private var emailMessage = "Please find attached the legal document generated through BoloNyay Legal Assistant."
    @State private var showEmailAlert = false
    @State private var emailAlertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                            Text("Close")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Text("Legal Document Preview")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Email Button
                    Button(action: {
                        showEmailInput = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                            Text("Email")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Share Button
                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            Text("Share")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(UIColor.separator)),
                    alignment: .bottom
                )
                
                // PDF Viewer
                PDFKitView(pdfURL: pdfURL)
                    .background(Color(UIColor.systemGray6))
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [pdfURL])
        }
        .sheet(isPresented: $showEmailInput) {
            EmailInputView(
                recipientEmail: $recipientEmail,
                emailSubject: $emailSubject,
                emailMessage: $emailMessage,
                onSend: {
                    showEmailInput = false
                    if MFMailComposeViewController.canSendMail() {
                        showEmailComposer = true
                    } else {
                        // Use Gmail Manager as fallback
                        let emailTemplate = GmailManager.shared.createLegalDocumentEmail(
                            caseNumber: "BN\(Calendar.current.component(.year, from: Date()))\(Int.random(in: 100000...999999))",
                            documentType: "Legal Document"
                        )
                        
                        GmailManager.shared.sendEmailViaGmail(
                            to: recipientEmail,
                            subject: emailSubject.isEmpty ? emailTemplate.subject : emailSubject,
                            body: emailMessage.isEmpty ? emailTemplate.body : emailMessage,
                            attachmentURL: pdfURL
                        ) { success, message in
                            DispatchQueue.main.async {
                                emailAlertMessage = message
                                showEmailAlert = true
                            }
                        }
                    }
                },
                onCancel: {
                    showEmailInput = false
                }
            )
        }
        .sheet(isPresented: $showEmailComposer) {
            MailComposeView(
                recipients: [recipientEmail],
                subject: emailSubject,
                messageBody: emailMessage,
                attachmentURL: pdfURL,
                onResult: { result in
                    showEmailComposer = false
                    switch result {
                    case .sent:
                        emailAlertMessage = "Email sent successfully!"
                        showEmailAlert = true
                    case .saved:
                        emailAlertMessage = "Email saved as draft."
                        showEmailAlert = true
                    case .cancelled:
                        break
                    case .failed:
                        emailAlertMessage = "Failed to send email. Please try again."
                        showEmailAlert = true
                    }
                }
            )
        }
        .alert("Email Status", isPresented: $showEmailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(emailAlertMessage)
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let pdfURL: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        pdfView.backgroundColor = UIColor.systemGray6
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true, withViewOptions: nil)
        
        // Load PDF document
        if let document = PDFDocument(url: pdfURL) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Update if needed
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Update if needed
    }
}


struct EmailInputView: View {
    @Binding var recipientEmail: String
    @Binding var emailSubject: String
    @Binding var emailMessage: String
    let onSend: () -> Void
    let onCancel: () -> Void
    
    @State private var isValidEmail = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Send PDF via Email")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Enter recipient details to send the legal document")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 16) {
                    // Recipient Email
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recipient Email *")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextField("Enter email address", text: $recipientEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .onChange(of: recipientEmail) { _ in
                                validateEmail()
                            }
                        
                        if !isValidEmail {
                            Text("Please enter a valid email address")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Email Subject
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Subject")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextField("Email subject", text: $emailSubject)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Email Message
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Message")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $emailMessage)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                            )
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            if validateEmail() {
                                onSend()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Send Email")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isValidEmail && !recipientEmail.isEmpty ? Color.green : Color.gray)
                            )
                        }
                        .disabled(!isValidEmail || recipientEmail.isEmpty)
                    }
                    
                    // Gmail Direct Button
                    Button(action: {
                        if validateEmail() {
                            // Use Gmail Manager directly
                            let emailTemplate = GmailManager.shared.createLegalDocumentEmail(
                                caseNumber: "BN\(Calendar.current.component(.year, from: Date()))\(Int.random(in: 100000...999999))",
                                documentType: "Legal Document"
                            )
                            
                            GmailManager.shared.sendEmailViaGmail(
                                to: recipientEmail,
                                subject: emailSubject.isEmpty ? emailTemplate.subject : emailSubject,
                                body: emailMessage.isEmpty ? emailTemplate.body : emailMessage
                            ) { success, message in
                                // Handle result if needed
                                print("Gmail send result: \(success ? "Success" : "Failed") - \(message)")
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("📧 Send via Gmail")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isValidEmail && !recipientEmail.isEmpty ? 
                                      LinearGradient(colors: [Color.red, Color.orange], startPoint: .leading, endPoint: .trailing) : 
                                      LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing))
                        )
                    }
                    .disabled(!isValidEmail || recipientEmail.isEmpty)
                }
            }
            .padding(20)
            .navigationBarHidden(true)
        }
    }
    
    private func validateEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        isValidEmail = emailPredicate.evaluate(with: recipientEmail)
        return isValidEmail
    }
}

// MARK: - Mail Compose View

enum MailResult {
    case sent, saved, cancelled, failed
}

struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let messageBody: String
    let attachmentURL: URL
    let onResult: (MailResult) -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        
        // Set recipients
        mailComposer.setToRecipients(recipients)
        
        // Set subject
        mailComposer.setSubject(subject)
        
        // Set message body
        mailComposer.setMessageBody(messageBody, isHTML: false)
        
        // Attach PDF
        do {
            let pdfData = try Data(contentsOf: attachmentURL)
            let fileName = attachmentURL.lastPathComponent
            mailComposer.addAttachmentData(pdfData, mimeType: "application/pdf", fileName: fileName)
        } catch {
            print("❌ Failed to attach PDF: \(error)")
        }
        
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onResult: (MailResult) -> Void
        
        init(onResult: @escaping (MailResult) -> Void) {
            self.onResult = onResult
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                print("❌ Mail compose error: \(error)")
                onResult(.failed)
                return
            }
            
            switch result {
            case .sent:
                print("✅ Email sent successfully")
                onResult(.sent)
            case .saved:
                print("📄 Email saved as draft")
                onResult(.saved)
            case .cancelled:
                print("❌ Email cancelled")
                onResult(.cancelled)
            case .failed:
                print("❌ Email failed to send")
                onResult(.failed)
            @unknown default:
                print("⚠️ Unknown email result")
                onResult(.failed)
            }
        }
    }
}

#Preview {
    // For preview, we'll need a sample PDF URL
    if let samplePDFURL = Bundle.main.url(forResource: "sample", withExtension: "pdf") {
        PDFPreviewView(pdfURL: samplePDFURL)
    } else {
        Text("PDF Preview")
            .font(.title)
            .foregroundColor(.gray)
    }
} 