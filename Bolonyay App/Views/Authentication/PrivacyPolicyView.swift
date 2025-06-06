import SwiftUI

struct PrivacyPolicyView: View {
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
                            Text("Privacy Policy")
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
                            PolicySection(
                                title: "Information We Collect",
                                content: """
                                We collect information you provide directly to us, such as:
                                • Personal information (name, email, phone number)
                                • Professional credentials (for advocates)
                                • Location information for jurisdiction matching
                                • Profile photos and documents you choose to share
                                
                                We also collect information automatically through your use of our services, including device information, usage patterns, and interaction data to improve our platform.
                                """,
                                icon: "person.circle.fill",
                                animationDelay: 0.4,
                                isVisible: animateContent
                            )
                            
                            PolicySection(
                                title: "How We Use Your Information",
                                content: """
                                We use your information to:
                                • Provide and improve our legal services platform
                                • Match petitioners with qualified advocates
                                • Verify professional credentials and licensing
                                • Communicate important updates and notifications
                                • Ensure platform security and prevent fraud
                                • Comply with legal obligations and regulations
                                
                                We will never sell your personal information to third parties.
                                """,
                                icon: "gear.circle.fill",
                                animationDelay: 0.5,
                                isVisible: animateContent
                            )
                            
                            PolicySection(
                                title: "Information Sharing",
                                content: """
                                We may share your information in limited circumstances:
                                • With advocates when you request legal assistance
                                • With service providers who assist our operations
                                • When required by law or legal process
                                • To protect rights, property, or safety
                                
                                All sharing is conducted with appropriate safeguards and in compliance with applicable privacy laws.
                                """,
                                icon: "shareplay",
                                animationDelay: 0.6,
                                isVisible: animateContent
                            )
                            
                            PolicySection(
                                title: "Data Security",
                                content: """
                                We implement industry-standard security measures to protect your information:
                                • End-to-end encryption for sensitive communications
                                • Secure data storage with regular backups
                                • Multi-factor authentication options
                                • Regular security audits and updates
                                • Compliance with legal data protection standards
                                
                                While we strive to protect your information, no method of transmission over the internet is 100% secure.
                                """,
                                icon: "lock.shield.fill",
                                animationDelay: 0.7,
                                isVisible: animateContent
                            )
                            
                            PolicySection(
                                title: "Your Rights",
                                content: """
                                You have the right to:
                                • Access, update, or delete your personal information
                                • Control how your information is used and shared
                                • Opt out of certain communications
                                • Request a copy of your data
                                • Withdraw consent where applicable
                                
                                To exercise these rights, please contact us at privacy@bolonyay.com
                                """,
                                icon: "hand.raised.fill",
                                animationDelay: 0.8,
                                isVisible: animateContent
                            )
                            
                            PolicySection(
                                title: "Contact Information",
                                content: """
                                If you have questions about this Privacy Policy, please contact us:
                                
                                Email: privacy@bolonyay.com
                                Address: BoloNyay Legal Services
                                Legal Department
                                India
                                
                                We will respond to your inquiries within 30 days.
                                """,
                                icon: "envelope.circle.fill",
                                animationDelay: 0.9,
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

struct PolicySection: View {
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
                    .foregroundColor(.blue)
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
    PrivacyPolicyView()
} 