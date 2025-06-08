import SwiftUI
import MessageUI

// MARK: - Help Detail View

struct HelpDetailView: View {
    let section: HelpSection
    let localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimated = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        HelpDetailHeader(section: section, isAnimated: isAnimated, localizationManager: localizationManager)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // Content Based on Section
                        Group {
                            switch section {
                            case .faq:
                                FAQContentView(isAnimated: isAnimated, localizationManager: localizationManager)
                            case .userGuide:
                                UserGuideContentView(isAnimated: isAnimated, localizationManager: localizationManager)
                            case .contactSupport:
                                ContactSupportContentView(isAnimated: isAnimated, localizationManager: localizationManager)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(0.2)) {
                isAnimated = true
            }
        }
    }
}

// MARK: - Help Detail Header

struct HelpDetailHeader: View {
    let section: HelpSection
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Navigation
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Section Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: section.gradient + [section.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                    
                    Image(systemName: section.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(isVisible ? 1.0 : 0.6)
                }
                
                VStack(spacing: 8) {
                    Text(section.title(localizationManager: localizationManager))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(section.subtitle(localizationManager: localizationManager))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(y: isVisible ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - FAQ Content View

struct FAQContentView: View {
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    @State private var expandedFAQ: Int? = nil
    @State private var searchText = ""
    
    private func getFAQData() -> [FAQ] {
        return [
            FAQ(
                question: localizationManager.text("faq_question_1"),
                answer: localizationManager.text("faq_answer_1")
            ),
            FAQ(
                question: localizationManager.text("faq_question_2"),
                answer: localizationManager.text("faq_answer_2")
            ),
            FAQ(
                question: localizationManager.text("faq_question_3"),
                answer: localizationManager.text("faq_answer_3")
            ),
            FAQ(
                question: localizationManager.text("faq_question_4"),
                answer: localizationManager.text("faq_answer_4")
            ),
            FAQ(
                question: localizationManager.text("faq_question_5"),
                answer: localizationManager.text("faq_answer_5")
            ),
            FAQ(
                question: localizationManager.text("faq_question_6"),
                answer: localizationManager.text("faq_answer_6")
            ),
            FAQ(
                question: localizationManager.text("faq_question_7"),
                answer: localizationManager.text("faq_answer_7")
            ),
            FAQ(
                question: localizationManager.text("faq_question_8"),
                answer: localizationManager.text("faq_answer_8")
            ),
            FAQ(
                question: localizationManager.text("faq_question_9"),
                answer: localizationManager.text("faq_answer_9")
            ),
            FAQ(
                question: localizationManager.text("faq_question_10"),
                answer: localizationManager.text("faq_answer_10")
            )
        ]
    }
    
    var filteredFAQs: [FAQ] {
        let faqData = getFAQData()
        if searchText.isEmpty {
            return faqData
        }
        return faqData.filter { faq in
            faq.question.localizedCaseInsensitiveContains(searchText) ||
            faq.answer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Search Bar
            SearchBar(searchText: $searchText, placeholder: localizationManager.text("search_faqs"), isAnimated: isAnimated)
            
            // FAQ List
            LazyVStack(spacing: 16) {
                ForEach(Array(filteredFAQs.enumerated()), id: \.element.id) { index, faq in
                    FAQCard(
                        faq: faq,
                        index: index,
                        isExpanded: expandedFAQ == index,
                        animationDelay: Double(index) * 0.1,
                        isAnimated: isAnimated
                    ) {
                        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                            expandedFAQ = expandedFAQ == index ? nil : index
                        }
                    }
                }
            }
            
            // Contact Support CTA
            ContactCTA(
                title: localizationManager.text("still_need_help"),
                subtitle: localizationManager.text("contact_support_cta"),
                buttonText: localizationManager.text("contact_support_button"),
                isAnimated: isAnimated
            )
        }
        .padding(.top, 30)
    }
}

// MARK: - User Guide Content View

struct UserGuideContentView: View {
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    @State private var selectedGuideSection: GuideSection? = nil
    
    private func getGuideSections() -> [GuideSection] {
        return [
            GuideSection(
                title: localizationManager.text("getting_started_title"),
                subtitle: localizationManager.text("getting_started_subtitle"),
                icon: "play.circle.fill",
                color: .white,
                steps: [
                    localizationManager.text("getting_started_step_1"),
                    localizationManager.text("getting_started_step_2"),
                    localizationManager.text("getting_started_step_3"),
                    localizationManager.text("getting_started_step_4")
                ]
            ),
            GuideSection(
                title: localizationManager.text("filing_first_case_title"),
                subtitle: localizationManager.text("filing_first_case_subtitle"),
                icon: "doc.text.fill",
                color: .white,
                steps: [
                    localizationManager.text("filing_first_case_step_1"),
                    localizationManager.text("filing_first_case_step_2"),
                    localizationManager.text("filing_first_case_step_3"),
                    localizationManager.text("filing_first_case_step_4"),
                    localizationManager.text("filing_first_case_step_5")
                ]
            ),
            GuideSection(
                title: localizationManager.text("voice_recognition_tips_title"),
                subtitle: localizationManager.text("voice_recognition_tips_subtitle"),
                icon: "mic.fill",
                color: .white,
                steps: [
                    localizationManager.text("voice_recognition_tips_step_1"),
                    localizationManager.text("voice_recognition_tips_step_2"),
                    localizationManager.text("voice_recognition_tips_step_3"),
                    localizationManager.text("voice_recognition_tips_step_4"),
                    localizationManager.text("voice_recognition_tips_step_5")
                ]
            ),
            GuideSection(
                title: localizationManager.text("managing_documents_title"),
                subtitle: localizationManager.text("managing_documents_subtitle"),
                icon: "folder.fill",
                color: .white,
                steps: [
                    localizationManager.text("managing_documents_step_1"),
                    localizationManager.text("managing_documents_step_2"),
                    localizationManager.text("managing_documents_step_3"),
                    localizationManager.text("managing_documents_step_4"),
                    localizationManager.text("managing_documents_step_5")
                ]
            ),
            GuideSection(
                title: localizationManager.text("account_settings_title"),
                subtitle: localizationManager.text("account_settings_subtitle"),
                icon: "gear.circle.fill",
                color: .white,
                steps: [
                    localizationManager.text("account_settings_step_1"),
                    localizationManager.text("account_settings_step_2"),
                    localizationManager.text("account_settings_step_3"),
                    localizationManager.text("account_settings_step_4"),
                    localizationManager.text("account_settings_step_5")
                ]
            )
        ]
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Introduction
            GuideIntroCard(isAnimated: isAnimated, localizationManager: localizationManager)
            
            // Guide Sections
            LazyVStack(spacing: 16) {
                ForEach(Array(getGuideSections().enumerated()), id: \.element.id) { index, section in
                    GuideSectionCard(
                        section: section,
                        animationDelay: Double(index) * 0.1,
                        isAnimated: isAnimated
                    ) {
                        selectedGuideSection = section
                    }
                }
            }
            
            // Video Tutorials CTA
            VideoTutorialsCTA(isAnimated: isAnimated, localizationManager: localizationManager)
        }
        .padding(.top, 30)
        .sheet(item: $selectedGuideSection) { section in
            GuideDetailView(section: section)
        }
    }
}

// MARK: - Contact Support Content View

struct ContactSupportContentView: View {
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    @State private var selectedContactMethod: ContactMethod? = nil
    @State private var showFeedbackForm = false
    
    private func getContactMethods() -> [ContactMethod] {
        return [
            ContactMethod(
                title: localizationManager.text("email_support_title"),
                subtitle: localizationManager.text("email_support_subtitle"),
                icon: "envelope.circle.fill",
                color: .white,
                type: .email,
                value: "support@bolonyay.com"
            ),
            ContactMethod(
                title: localizationManager.text("phone_support_title"),
                subtitle: localizationManager.text("phone_support_subtitle"),
                icon: "phone.circle.fill",
                color: .white,
                type: .phone,
                value: "+91-XXXXX-XXXXX"
            ),
            ContactMethod(
                title: localizationManager.text("live_chat_title"),
                subtitle: localizationManager.text("live_chat_subtitle"),
                icon: "message.circle.fill",
                color: .white,
                type: .chat,
                value: "Available 9 AM - 6 PM IST"
            ),
            ContactMethod(
                title: localizationManager.text("whatsapp_support_title"),
                subtitle: localizationManager.text("whatsapp_support_subtitle"),
                icon: "message.fill",
                color: .white,
                type: .whatsapp,
                value: "+91-XXXXX-XXXXX"
            )
        ]
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Support Hours
            SupportHoursCard(isAnimated: isAnimated, localizationManager: localizationManager)
            
            // Contact Methods
            LazyVStack(spacing: 16) {
                ForEach(Array(getContactMethods().enumerated()), id: \.element.id) { index, method in
                    ContactMethodCard(
                        method: method,
                        animationDelay: Double(index) * 0.1,
                        isAnimated: isAnimated
                    ) {
                        selectedContactMethod = method
                        handleContactMethod(method)
                    }
                }
            }
            
            // Feedback Section
            FeedbackCard(isAnimated: isAnimated, localizationManager: localizationManager) {
                showFeedbackForm = true
            }
            
            // Emergency Support
            EmergencySupportCard(isAnimated: isAnimated)
        }
        .padding(.top, 30)
        .sheet(isPresented: $showFeedbackForm) {
            FeedbackFormView(localizationManager: localizationManager)
        }
    }
    
    private func handleContactMethod(_ method: ContactMethod) {
        switch method.type {
        case .email:
            if let emailURL = URL(string: "mailto:\(method.value)") {
                UIApplication.shared.open(emailURL)
            }
        case .phone:
            if let phoneURL = URL(string: "tel:\(method.value.replacingOccurrences(of: "-", with: ""))") {
                UIApplication.shared.open(phoneURL)
            }
        case .whatsapp:
            if let whatsappURL = URL(string: "https://wa.me/\(method.value.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "-", with: ""))") {
                UIApplication.shared.open(whatsappURL)
            }
        case .chat:
            // Open chat interface
            break
        }
    }
}

// MARK: - Supporting Data Models

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct GuideSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let steps: [String]
}

struct ContactMethod: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let type: ContactType
    let value: String
}

enum ContactType {
    case email, phone, chat, whatsapp
}

// MARK: - Search Bar Component

struct SearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let isAnimated: Bool
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            TextField(placeholder, text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.2)) {
                isVisible = true
            }
        }
    }
}

// MARK: - FAQ Card Component

struct FAQCard: View {
    let faq: FAQ
    let index: Int
    let isExpanded: Bool
    let animationDelay: Double
    let isAnimated: Bool
    let onTap: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Question
            Button(action: onTap) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(faq.question)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Answer
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                    
                    Text(faq.answer)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .padding(16)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Contact CTA Component

struct ContactCTA: View {
    let title: String
    let subtitle: String
    let buttonText: String
    let isAnimated: Bool
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {}) {
                Text(buttonText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(1.0)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Guide Supporting Components

struct GuideIntroCard: View {
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: "book.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                
                Text(localizationManager.text("user_guide_title"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(localizationManager.text("user_guide_subtitle"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(0.2)) {
                isVisible = true
            }
        }
    }
}

struct GuideSectionCard: View {
    let section: GuideSection
    let animationDelay: Double
    let isAnimated: Bool
    let onTap: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(section.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: section.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(section.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(section.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(section.steps.count) steps")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(section.color)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

struct VideoTutorialsCTA: View {
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                
                Text(localizationManager.text("video_tutorials_title"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(localizationManager.text("video_tutorials_subtitle"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {}) {
                Text(localizationManager.text("watch_tutorials"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(1.2)) {
                isVisible = true
            }
        }
    }
}

struct GuideDetailView: View {
    let section: GuideSection
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(section.color.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: section.icon)
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(section.color)
                            }
                            
                            Text(section.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(section.subtitle)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Steps
                        VStack(spacing: 16) {
                            ForEach(Array(section.steps.enumerated()), id: \.offset) { index, step in
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(section.color)
                                            .frame(width: 32, height: 32)
                                        
                                        Text("\(index + 1)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(step)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Contact Support Components

struct SupportHoursCard: View {
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "clock.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.text("support_hours_title"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(localizationManager.text("support_hours_weekdays"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.text("emergency_support_title"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(localizationManager.text("support_hours_note"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
        }
        .padding(20)
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
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(0.2)) {
                isVisible = true
            }
        }
    }
}

struct ContactMethodCard: View {
    let method: ContactMethod
    let animationDelay: Double
    let isAnimated: Bool
    let onTap: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(method.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: method.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(method.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(method.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(method.value)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(method.color)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

struct FeedbackCard: View {
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    let onTap: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(systemName: "star.bubble.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                    
                    Text(localizationManager.text("feedback_title"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(localizationManager.text("feedback_description"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                Text(localizationManager.text("send_feedback"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                    )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(1.0)) {
                isVisible = true
            }
        }
    }
}

struct EmergencySupportCard: View {
    let isAnimated: Bool
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                
                Text("Emergency Legal Support")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("For urgent legal matters requiring immediate attention")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {}) {
                Text("Emergency Contact")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(1.2)) {
                isVisible = true
            }
        }
    }
}

struct FeedbackFormView: View {
    let localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""
    @State private var selectedCategory = "General"
    @State private var rating = 5
    
    private let categories = ["General", "Bug Report", "Feature Request", "UI/UX", "Performance"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("We'd love your feedback!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Rating
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: { rating = star }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(categories, id: \.self) { category in
                                    Button(action: { selectedCategory = category }) {
                                        Text(category)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedCategory == category ? .black : .white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(selectedCategory == category ? Color.white : Color.white.opacity(0.2))
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Feedback Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Feedback")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextEditor(text: $feedbackText)
                            .frame(height: 120)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Submit Button
                    Button(action: {
                        // Submit feedback
                        dismiss()
                    }) {
                        Text("Submit Feedback")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Advanced Language Picker

struct AdvancedLanguagePicker: View {
    let localizationManager: LocalizationManager
    let onLanguageSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimated = false
    
    private let supportedLanguages = [
        ("en", "English", "🇺🇸", "English"),
        ("hi", "हिंदी", "🇮🇳", "Hindi"),
        ("gu", "ગુજરાતી", "🇮🇳", "Gujarati"),
        ("ur", "اردو", "🇵🇰", "Urdu"),
        ("mr", "मराठी", "🇮🇳", "Marathi")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Select Language")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Choose your preferred language for the app")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .opacity(isAnimated ? 1.0 : 0.0)
                    .offset(y: isAnimated ? 0 : -20)
                    
                    // Language Options
                    VStack(spacing: 16) {
                        ForEach(Array(supportedLanguages.enumerated()), id: \.element.0) { index, language in
                            LanguageOptionCard(
                                code: language.0,
                                name: language.1,
                                flag: language.2,
                                englishName: language.3,
                                isSelected: localizationManager.currentLanguage == language.0,
                                animationDelay: Double(index) * 0.1,
                                isAnimated: isAnimated
                            ) {
                                onLanguageSelected(language.0)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(0.2)) {
                isAnimated = true
            }
        }
    }
}

struct LanguageOptionCard: View {
    let code: String
    let name: String
    let flag: String
    let englishName: String
    let isSelected: Bool
    let animationDelay: Double
    let isAnimated: Bool
    let onTap: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Flag
                Text(flag)
                    .font(.system(size: 32))
                
                // Language Names
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(englishName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}



#Preview {
    HelpDetailView(section: .faq, localizationManager: LocalizationManager())
} 