import SwiftUI

enum AppState {
    case splash
    case languageDetection
    case login
    case emailAuth
    case onboarding
    case dashboard
}

class AppCoordinator: ObservableObject {
    @Published var currentState: AppState = .splash
    @Published var onboardingCoordinator = OnboardingCoordinator()
    @StateObject private var authManager = AuthenticationManager()
    
    init() {
        // Listen for navigation notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserLoggedOut"),
            object: nil,
            queue: .main
        ) { _ in
            self.logout()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToLogin"),
            object: nil,
            queue: .main
        ) { _ in
            self.currentState = .login
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToEmailAuth"),
            object: nil,
            queue: .main
        ) { _ in
            self.currentState = .emailAuth
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToOnboarding"),
            object: nil,
            queue: .main
        ) { _ in
            self.currentState = .onboarding
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToDashboard"),
            object: nil,
            queue: .main
        ) { _ in
            self.currentState = .dashboard
        }
    }
    
    func startLanguageDetection() {
        currentState = .languageDetection
    }
    
    func startLogin() {
        currentState = .login
    }
    
    func startOnboarding() {
        currentState = .onboarding
    }
    
    func completeOnboarding() {
        currentState = .dashboard
    }
    
    func logout() {
        // Clear language preference so user gets language detection on next login
        UserDefaults.standard.removeObject(forKey: "user_preferred_language")
        onboardingCoordinator.reset()
        currentState = .splash
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct AppCoordinatorView: View {
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch appCoordinator.currentState {
            case .splash:
                SplashView()
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SplashCompleted"))) { _ in
                        // Check if user has language preference stored
                        if UserDefaults.standard.string(forKey: "user_preferred_language") != nil {
                            // Try auto-login if credentials are saved
                            Task {
                                let authManager = AuthenticationManager()
                                await authManager.attemptAutoLogin()
                                
                                // If auto-login didn't work, go to login screen
                                if !authManager.isSignedIn {
                                    await MainActor.run {
                        appCoordinator.startLogin()
                                    }
                                }
                            }
                        } else {
                            appCoordinator.startLanguageDetection()
                        }
                    }
                
            case .languageDetection:
                LanguageDetectionView()
                    .environmentObject(appCoordinator)
                
            case .login:
                LoginView()
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LoginCompleted"))) { _ in
                        appCoordinator.startOnboarding()
                    }
                
            case .emailAuth:
                EmailAuthView()
                
            case .onboarding:
                OnboardingView(coordinator: appCoordinator.onboardingCoordinator)
                    .onReceive(appCoordinator.onboardingCoordinator.$isOnboardingComplete) { completed in
                        if completed {
                            appCoordinator.completeOnboarding()
                        }
                    }
                
            case .dashboard:
                PractitionerDashboardView(coordinator: appCoordinator.onboardingCoordinator)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appCoordinator.currentState)
    }
}

#Preview {
    AppCoordinatorView()
} 