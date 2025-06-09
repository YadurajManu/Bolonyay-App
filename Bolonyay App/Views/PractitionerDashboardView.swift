import SwiftUI

struct PractitionerDashboardView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var authManager = AuthenticationManager()
    @State private var selectedTab: DashboardTab = .home
    @State private var animateContent = false
    @State private var showLogoutAlert = false
    
    // Computed properties for user info
    private var displayName: String {
        if let profileName = authManager.userProfile?.fullName, !profileName.isEmpty {
            return profileName
        } else if !coordinator.fullName.isEmpty {
            return coordinator.fullName
        } else {
            return "Practitioner"
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeTabView(
                coordinator: coordinator,
                authManager: authManager,
                displayName: displayName,
                isAnimated: animateContent,
                onLogout: { showLogoutAlert = true }
            )
            .tabItem {
                Image(systemName: DashboardTab.home.icon)
                Text(localizationManager.text("home"))
            }
            .tag(DashboardTab.home)
            
            // New Case Tab
            NewCaseTabView(isAnimated: animateContent)
                .tabItem {
                    Image(systemName: DashboardTab.newCase.icon)
                    Text(localizationManager.text("new_case"))
                }
                .tag(DashboardTab.newCase)
            
            // Voice Chatbot Tab
            VoiceChatbotTabView(isAnimated: animateContent)
                .tabItem {
                    Image(systemName: DashboardTab.voiceChatbot.icon)
                    Text(localizationManager.text("voice_chatbot"))
                }
                .tag(DashboardTab.voiceChatbot)
            
            // Reports Tab
            ReportsTabView(isAnimated: animateContent)
                .tabItem {
                    Image(systemName: DashboardTab.reports.icon)
                    Text(localizationManager.text("reports"))
                }
                .tag(DashboardTab.reports)
            
            // Help Tab
            HelpTabView(isAnimated: animateContent)
                .tabItem {
                    Image(systemName: DashboardTab.help.icon)
                    Text(localizationManager.text("help"))
                }
                .tag(DashboardTab.help)
        }
        .accentColor(.white)
        .onAppear {
            // Configure tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor.black
            tabBarAppearance.selectionIndicatorTintColor = UIColor.white
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            
            // Configure navigation bar appearance
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = UIColor.black
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = navBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
            UINavigationBar.appearance().compactAppearance = navBarAppearance
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            
            // Regular logout (keeps credentials if Remember Me is enabled)
            Button("Logout", role: .destructive) {
                logout(clearCredentials: false)
            }
            
            // Logout and clear saved credentials
            if authManager.rememberMe {
                Button("Logout & Clear Saved Login", role: .destructive) {
                    logout(clearCredentials: true)
                }
            }
        } message: {
            if authManager.rememberMe {
                Text("Choose logout option. 'Logout & Clear Saved Login' will remove your saved credentials.")
            } else {
            Text("Are you sure you want to logout?")
            }
        }
        .onAppear {
            animateContent = true
        }
    }
    
    private func logout(clearCredentials: Bool = false) {
        authManager.signOut(clearSavedCredentials: clearCredentials)
        coordinator.reset()
    }
}

// MARK: - Dashboard Tab Enum
enum DashboardTab: String, CaseIterable {
    case home = "Home"
    case newCase = "New Case"
    case voiceChatbot = "Voice Chatbot"
    case reports = "Reports"
    case help = "Help"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .newCase: return "plus.rectangle.fill"
        case .voiceChatbot: return "mic.circle.fill"
        case .reports: return "chart.bar.fill"
        case .help: return "questionmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .home: return "Dashboard overview"
        case .newCase: return "File a new case"
        case .voiceChatbot: return "Talk to Nyay Assistant"
        case .reports: return "View reports"
        case .help: return "Get help"
        }
    }
}

// MARK: - Home Tab View
struct HomeTabView: View {
    let coordinator: OnboardingCoordinator
    let authManager: AuthenticationManager
    let displayName: String
    let isAnimated: Bool
    let onLogout: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Compact Header with profile info
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 45, height: 45)
                                
                                Image(systemName: coordinator.userType.icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text(coordinator.userType.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.1))
                                    )
                            }
                            
                            Spacer()
                            
                            // Bolo logo image
                            Image("bolo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 65, height: 65)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .white.opacity(0.2), radius: 6, x: 0, y: 3)
                                .scaleEffect(isAnimated ? 1.0 : 0.8)
                                .opacity(isAnimated ? 1.0 : 0.0)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.3), value: isAnimated)
                            
                            // Compact logout button
                            Button(action: onLogout) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Dashboard content
                        DashboardHomeContent(isAnimated: isAnimated)
                            .padding(.horizontal, 20)
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - New Case Tab View
struct NewCaseTabView: View {
    let isAnimated: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Text(localizationManager.text("new_case"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                ScrollView {
                    NewCaseContent(isAnimated: isAnimated)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Voice Chatbot Tab View
struct VoiceChatbotTabView: View {
    let isAnimated: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VoiceChatbotView()
            .environmentObject(localizationManager)
    }
}



// MARK: - Reports Tab View
struct ReportsTabView: View {
    let isAnimated: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Text(localizationManager.text("reports"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                ScrollView {
                    ReportsContent(isAnimated: isAnimated)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Help Tab View
struct HelpTabView: View {
    let isAnimated: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Text(localizationManager.text("help"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                ScrollView {
                    HelpContent(isAnimated: isAnimated)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}



#Preview {
    let coordinator = OnboardingCoordinator()
    coordinator.userType = .advocate
    coordinator.fullName = "John Doe"
    coordinator.email = "john.doe@example.com"
    
    return PractitionerDashboardView(coordinator: coordinator)
} 