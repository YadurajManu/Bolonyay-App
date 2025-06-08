import SwiftUI
import MessageUI

// MARK: - Main Help System View

struct HelpSystemView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var authManager = AuthenticationManager()
    @State private var selectedHelpSection: HelpSection? = nil
    @State private var isAnimated = false
    @State private var showUserProfile = false
    @State private var showLanguagePicker = false
    @State private var showLogoutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let animationDelay: Double
    
    init(animationDelay: Double = 0.0) {
        self.animationDelay = animationDelay
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Enhanced User Profile Section
            EnhancedUserProfileCard(
                user: firebaseManager.getCurrentUser(),
                localizationManager: localizationManager,
                animationDelay: animationDelay + 0.3,
                isAnimated: isAnimated,
                onProfileTap: { showUserProfile = true }
            )
            
            // Modern Language Settings
            ModernLanguageSettings(
                currentLanguage: localizationManager.currentLanguage,
                localizationManager: localizationManager,
                animationDelay: animationDelay + 0.5,
                isAnimated: isAnimated,
                onLanguageChange: { showLanguagePicker = true }
            )
            
            // Help Sections with Beautiful Design
            VStack(spacing: 20) {
                            HelpSectionHeader(
                title: localizationManager.text("help_support_title"),
                subtitle: localizationManager.text("help_support_subtitle"),
                animationDelay: animationDelay + 0.7,
                isAnimated: isAnimated
            )
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    HelpSectionCard(
                        section: .faq,
                        localizationManager: localizationManager,
                        animationDelay: animationDelay + 0.8,
                        isAnimated: isAnimated
                    ) {
                        selectedHelpSection = .faq
                    }
                    
                    HelpSectionCard(
                        section: .userGuide,
                        localizationManager: localizationManager,
                        animationDelay: animationDelay + 0.9,
                        isAnimated: isAnimated
                    ) {
                        selectedHelpSection = .userGuide
                    }
                }
                
                // Full Width Contact Support
                HelpSectionCard(
                    section: .contactSupport,
                    localizationManager: localizationManager,
                    animationDelay: animationDelay + 1.0,
                    isAnimated: isAnimated,
                    isFullWidth: true
                ) {
                    selectedHelpSection = .contactSupport
                }
            }
            
            // Quick Actions Section
            QuickActionsSection(
                localizationManager: localizationManager,
                animationDelay: animationDelay + 1.2,
                isAnimated: isAnimated,
                onDeleteAccount: { showDeleteConfirmation = true },
                onLogout: { showLogoutConfirmation = true }
            )
            
            Spacer(minLength: 100)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay)) {
                isAnimated = true
            }
        }
        .sheet(item: $selectedHelpSection) { section in
            HelpDetailView(section: section, localizationManager: localizationManager)
        }
        .sheet(isPresented: $showLanguagePicker) {
            AdvancedLanguagePicker(
                localizationManager: localizationManager,
                onLanguageSelected: { language in
                    localizationManager.setLanguage(language)
                    showLanguagePicker = false
                }
            )
        }
        .sheet(isPresented: $showUserProfile) {
            UserProfileManagementView()
        }
        .alert("Logout", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("This action cannot be undone. Your account and all data will be permanently deleted.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .overlay {
            if isLoading {
                ModernLoadingOverlay()
            }
        }
    }
    
    private func logout() {
        authManager.signOut()
    }
    
    private func deleteAccount() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        DispatchQueue.main.async {
            isLoading = false
            errorMessage = "Account deletion will be implemented soon"
        }
    }
}

// MARK: - Help Sections

enum HelpSection: String, CaseIterable, Identifiable {
    case faq = "faq"
    case userGuide = "user_guide"
    case contactSupport = "contact_support"
    
    var id: String { rawValue }
    
    func title(localizationManager: LocalizationManager) -> String {
        switch self {
        case .faq: return localizationManager.text("faq_title")
        case .userGuide: return localizationManager.text("user_guide_title")
        case .contactSupport: return localizationManager.text("contact_support_title")
        }
    }
    
    func subtitle(localizationManager: LocalizationManager) -> String {
        switch self {
        case .faq: return localizationManager.text("faq_subtitle")
        case .userGuide: return localizationManager.text("user_guide_subtitle")
        case .contactSupport: return localizationManager.text("contact_support_subtitle")
        }
    }
    
    var icon: String {
        switch self {
        case .faq: return "questionmark.bubble.fill"
        case .userGuide: return "book.circle.fill"
        case .contactSupport: return "headphones.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .faq: return .white
        case .userGuide: return .white
        case .contactSupport: return .white
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .faq: return [.white, .gray]
        case .userGuide: return [.white, .gray]
        case .contactSupport: return [.white, .gray]
        }
    }
}

// MARK: - Enhanced User Profile Card

struct EnhancedUserProfileCard: View {
    let user: FirebaseManager.BoloNyayUser?
    let localizationManager: LocalizationManager
    let animationDelay: Double
    let isAnimated: Bool
    let onProfileTap: () -> Void
    @State private var isVisible = false
    
    private var displayName: String {
        guard let user = user,
              !user.name.isEmpty,
              user.name != "iPhone" else {
            return "User"
        }
        return user.name
    }
    
    private var displayEmail: String {
        guard let user = user,
              let email = user.email,
              !email.isEmpty,
              email != "no_email" else {
            return "No email provided"
        }
        return email
    }
    
    private var userInitial: String {
        guard let user = user,
              !user.name.isEmpty,
              user.name != "iPhone" else {
            return ""
        }
        return String(user.name.prefix(1).uppercased())
    }
    
    var body: some View {
        Button(action: onProfileTap) {
            HStack(spacing: 16) {
                // Avatar with gradient background
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                    
                    if !userInitial.isEmpty {
                        Text(userInitial)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(displayEmail)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        
                        Text("Account Active")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Edit")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Modern Language Settings

struct ModernLanguageSettings: View {
    let currentLanguage: String
    let localizationManager: LocalizationManager
    let animationDelay: Double
    let isAnimated: Bool
    let onLanguageChange: () -> Void
    @State private var isVisible = false
    
    private let languageInfo: [String: (name: String, flag: String)] = [
        "en": ("English", "🇺🇸"),
        "hi": ("हिंदी", "🇮🇳"),
        "gu": ("ગુજરાતી", "🇮🇳"),
        "ur": ("اردو", "🇵🇰"),
        "mr": ("मराठी", "🇮🇳")
    ]
    
    var body: some View {
        Button(action: onLanguageChange) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(languageInfo[currentLanguage]?.flag ?? "🌐")
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Language")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(languageInfo[currentLanguage]?.name ?? "Unknown")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Help Section Header

struct HelpSectionHeader: View {
    let title: String
    let subtitle: String
    let animationDelay: Double
    let isAnimated: Bool
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(x: isVisible ? 0 : -30)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Help Section Card

struct HelpSectionCard: View {
    let section: HelpSection
    let localizationManager: LocalizationManager
    let animationDelay: Double
    let isAnimated: Bool
    let isFullWidth: Bool
    let action: () -> Void
    @State private var isVisible = false
    @State private var isPressed = false
    
    init(section: HelpSection, localizationManager: LocalizationManager, animationDelay: Double, isAnimated: Bool, isFullWidth: Bool = false, action: @escaping () -> Void) {
        self.section = section
        self.localizationManager = localizationManager
        self.animationDelay = animationDelay
        self.isAnimated = isAnimated
        self.isFullWidth = isFullWidth
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: section.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isFullWidth ? 56 : 48, height: isFullWidth ? 56 : 48)
                    
                    Image(systemName: section.icon)
                        .font(.system(size: isFullWidth ? 24 : 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 6) {
                    Text(section.title(localizationManager: localizationManager))
                        .font(.system(size: isFullWidth ? 18 : 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(section.subtitle(localizationManager: localizationManager))
                        .font(.system(size: isFullWidth ? 14 : 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(isFullWidth ? 3 : 2)
                }
                
                if isFullWidth {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(section.color)
                        
                        Text("Get Support")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(section.color)
                    }
                }
            }
            .padding(isFullWidth ? 24 : 20)
            .frame(maxWidth: .infinity)
            .frame(height: isFullWidth ? 160 : 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                section.color.opacity(0.1),
                                section.color.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        section.color.opacity(0.3),
                                        section.color.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? (isPressed ? 0.95 : 1.0) : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    let localizationManager: LocalizationManager
    let animationDelay: Double
    let isAnimated: Bool
    let onDeleteAccount: () -> Void
    let onLogout: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Account Actions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Logout Button
                Button(action: onLogout) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        
                        Text("Logout")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                    )
                }
                
                // Delete Account Button
                Button(action: onDeleteAccount) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                        
                        Text("Delete Account")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.5), lineWidth: 1)
                    )
                }
            }
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Modern Loading Overlay

struct ModernLoadingOverlay: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                }
                
                Text("Loading...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ScrollView {
            HelpSystemView(animationDelay: 0.0)
                .padding(.horizontal, 20)
        }
    }
    .environmentObject(LocalizationManager())
} 