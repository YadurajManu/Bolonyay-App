import SwiftUI

struct TermsConditionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var animateContent = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            Text("Terms & Conditions")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 30)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: animateContent)
                            
                            Text("Last updated: December 2024")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.3), value: animateContent)
                        }
                        .padding(.top, 40)
                        .padding(.horizontal, 24)
                        
                        // Content sections
                        VStack(spacing: 32) {
                            TermsSection(
                                title: "Acceptance of Terms",
                                content: """
                                By accessing and using BoloNyay, you accept and agree to be bound by these Terms and Conditions. If you do not agree to abide by these terms, please do not use this service.
                                
                                These terms apply to all visitors, users, and others who access or use the service.
                                """,
                                icon: "checkmark.seal.fill",
                                animationDelay: 0.4,
                                isVisible: animateContent
                            )
                            
                            TermsSection(
                                title: "Service Description",
                                content: """
                                BoloNyay is a legal services platform that connects:
                                • Petitioners seeking legal assistance
                                • Licensed advocates providing legal services
                                
                                We facilitate connections but are not responsible for the quality or outcome of legal services provided by advocates. All legal advice and representation is provided by independent legal professionals.
                                """,
                                icon: "scale.3d",
                                animationDelay: 0.5,
                                isVisible: animateContent
                            )
                            
                            TermsSection(
                                title: "User Responsibilities",
                                content: """
                                As a user, you agree to:
                                • Provide accurate and complete information
                                • Maintain the security of your account credentials
                                • Use the service in compliance with all applicable laws
                                • Respect the rights and privacy of other users
                                • Not engage in fraudulent or malicious activities
                                • Report any suspicious or inappropriate behavior
                                
                                Advocates must maintain valid professional licensing and credentials.
                                """,
                                icon: "person.badge.shield.checkmark.fill",
                                animationDelay: 0.6,
                                isVisible: animateContent
                            )
                            
                            TermsSection(
                                title: "Professional Standards",
                                content: """
                                For Advocates:
                                • Must maintain valid bar registration and professional licensing
                                • Responsible for providing competent legal representation
                                • Must comply with professional ethics and conduct rules
                                • Required to maintain client confidentiality
                                
                                For Petitioners:
                                • Must provide truthful information about legal matters
                                • Responsible for timely payment of agreed fees
                                • Must cooperate in good faith with chosen advocate
                                """,
                                icon: "briefcase.fill",
                                animationDelay: 0.7,
                                isVisible: animateContent
                            )
                            
                            TermsSection(
                                title: "Platform Limitations",
                                content: """
                                BoloNyay serves as a platform facilitator and:
                                • Does not provide legal advice or representation
                                • Is not responsible for the outcome of legal matters
                                • Cannot guarantee the availability of advocates
                                • Is not liable for disputes between users
                                • Reserves the right to suspend accounts for violations
                                
                                Users engage with advocates at their own discretion and risk.
                                """,
                                icon: "exclamationmark.triangle.fill",
                                animationDelay: 0.8,
                                isVisible: animateContent
                            )
                            
                            TermsSection(
                                title: "Payment Terms",
                                content: """
                                • All fees and payment terms are agreed between users directly
                                • BoloNyay may charge platform fees for certain services
                                • Refund policies are determined by individual advocates
                                • Users are responsible for all taxes on transactions
                                • Payment disputes should be resolved between parties
                                
                                We use secure payment processing but are not responsible for payment issues between users.
                                """,
                                icon: "creditcard.fill",
                                animationDelay: 0.9,
                                isVisible: animateContent
                            )
                            
                            TermsSection(
                                title: "Intellectual Property",
                                content: """
                                • BoloNyay retains all rights to the platform and its content
                                • Users retain rights to their own content and information
                                • You may not copy, distribute, or modify our platform
                                • All trademarks and logos are owned by their respective owners
                                • User-generated content may be used to improve our services
                                """,
                                icon: "doc.text.fill",
                                animationDelay: 1.0,
                                isVisible: animateContent
                            )
                            
                            TermsSection(
                                title: "Limitation of Liability",
                                content: """
                                BoloNyay shall not be liable for:
                                • Any indirect, incidental, or consequential damages
                                • Loss of profits, data, or business opportunities
                                • Legal outcomes or professional malpractice by advocates
                                • System downtime or technical issues
                                • Third-party actions or omissions
                                
                                Our total liability is limited to the amount paid for platform services.
                                """,
                                icon: "shield.fill",
                                animationDelay: 1.1,
                                isVisible: animateContent
                            )
                            
                            TermsSection(
                                title: "Termination",
                                content: """
                                We may terminate or suspend access immediately for:
                                • Violation of these terms
                                • Fraudulent or illegal activity
                                • Breach of professional standards
                                • Failure to maintain required credentials
                                
                                Users may terminate their account at any time. Upon termination, access to the service will cease but these terms remain in effect for prior use.
                                """,
                                icon: "xmark.circle.fill",
                                animationDelay: 1.2,
                                isVisible: animateContent
                            )
                            
                            TermsSection(
                                title: "Contact & Updates",
                                content: """
                                Questions about these terms? Contact us at:
                                Email: legal@bolonyay.com
                                
                                We may update these terms from time to time. Continued use of the service constitutes acceptance of updated terms.
                                
                                These terms are governed by Indian law and subject to Indian jurisdiction.
                                """,
                                icon: "envelope.circle.fill",
                                animationDelay: 1.3,
                                isVisible: animateContent
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                        .padding(.bottom, 100)
                    }
                }
                .coordinateSpace(name: "scroll")
                
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        .scaleEffect(animateContent ? 1.0 : 0.0)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(duration: 0.8, bounce: 0.5).delay(0.1), value: animateContent)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            animateContent = true
        }
    }
}

struct TermsSection: View {
    let title: String
    let content: String
    let icon: String
    let animationDelay: Double
    let isVisible: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Section header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.orange)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay), value: isVisible)
            
            // Section content
            Text(content)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay + 0.1), value: isVisible)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay), value: isVisible)
    }
}

#Preview {
    TermsConditionsView()
} 