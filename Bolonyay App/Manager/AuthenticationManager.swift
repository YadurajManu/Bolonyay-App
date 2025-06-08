import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userProfile: UserProfile?
    @Published var rememberMe = false
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    private let keychainManager = KeychainManager.shared
    
    init() {
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("Error: Could not find GoogleService-Info.plist or CLIENT_ID")
            return
        }
        
        // Only configure GIDSignIn if Firebase is already configured
        if FirebaseApp.app() != nil {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        }
        
        // Initialize Remember Me preference
        rememberMe = keychainManager.isRememberMeEnabled()
        
        // Listen for auth state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isSignedIn = user != nil
                
                if let user = user {
                    await self?.loadUserProfile(userId: user.uid)
                }
            }
        }
    }
    
    // MARK: - Auto Login
    func attemptAutoLogin() async {
        guard let credentials = keychainManager.getCredentials(),
              let email = credentials.email,
              let password = credentials.password else {
            print("🔑 No saved credentials found for auto-login")
            return
        }
        
        print("🔑 Attempting auto-login for: \(email)")
        await signInWithEmail(email: email, password: password, shouldSaveCredentials: false)
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle() async {
        // Ensure we're on the main thread
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Get the top-most view controller safely
        guard let presentingViewController = await getTopViewController() else {
            await MainActor.run {
                errorMessage = "Could not find a valid view controller to present authentication"
                isLoading = false
            }
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get ID token"
                isLoading = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: result.user.accessToken.tokenString)
            
            let authResult = try await auth.signIn(with: credential)
            let user = authResult.user
            
            // Check if user profile exists
            let userExists = await checkUserExists(userId: user.uid)
            
            if !userExists {
                // Create user profile from Google data
                let profile = UserProfile(
                    id: user.uid,
                    email: user.email ?? "",
                    fullName: user.displayName ?? "",
                    profileImageURL: user.photoURL?.absoluteString,
                    authProvider: "google",
                    isOnboardingComplete: false
                )
                
                await saveUserProfile(profile)
                
                // Navigate to onboarding
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToOnboarding"), object: nil)
            } else {
                // Navigate to dashboard
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToDashboard"), object: nil)
            }
            
        } catch {
            errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Email Authentication
    func signUpWithEmail(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await auth.createUser(withEmail: email, password: password)
            let user = authResult.user
            
            // Update display name
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()
            
            // Create user profile
            let profile = UserProfile(
                id: user.uid,
                email: email,
                fullName: fullName,
                profileImageURL: nil,
                authProvider: "email",
                isOnboardingComplete: false
            )
            
            await saveUserProfile(profile)
            
            // Navigate to onboarding
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToOnboarding"), object: nil)
            
        } catch {
            errorMessage = "Sign up failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signInWithEmail(email: String, password: String, shouldSaveCredentials: Bool = true) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)
            let user = authResult.user
            
            // Save credentials if remember me is enabled and this is a manual login
            if shouldSaveCredentials && rememberMe {
                let saved = keychainManager.saveCredentials(email: email, password: password)
                if !saved {
                    print("⚠️ Failed to save credentials to Keychain")
                }
            }
            
            // Load user profile and check onboarding status
            await loadUserProfile(userId: user.uid)
            
            if let profile = userProfile, profile.isOnboardingComplete {
                // Navigate to dashboard
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToDashboard"), object: nil)
            } else {
                // Navigate to onboarding
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToOnboarding"), object: nil)
            }
            
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Remember Me Management
    func toggleRememberMe() {
        rememberMe.toggle()
        keychainManager.saveRememberMePreference(rememberMe)
        
        if !rememberMe {
            // If user disabled remember me, clear any saved credentials
            keychainManager.clearCredentials()
        }
    }
    
    func loadSavedCredentials() -> (email: String?, password: String?)? {
        return keychainManager.getCredentials()
    }
    
    func getSavedEmail() -> String? {
        return keychainManager.getSavedEmail()
    }
    
    // MARK: - Helper Methods
    @MainActor
    private func getTopViewController() async -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        return findTopViewController(from: rootViewController)
    }
    
    @MainActor
    private func findTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            return findTopViewController(from: presentedViewController)
        } else if let navigationController = viewController as? UINavigationController,
                  let topViewController = navigationController.topViewController {
            return findTopViewController(from: topViewController)
        } else if let tabBarController = viewController as? UITabBarController,
                  let selectedViewController = tabBarController.selectedViewController {
            return findTopViewController(from: selectedViewController)
        } else {
            return viewController
        }
    }
    
    // MARK: - User Profile Management
    private func checkUserExists(userId: String) async -> Bool {
        do {
            let document = try await firestore.collection("users").document(userId).getDocument()
            return document.exists
        } catch {
            print("Error checking user exists: \(error)")
            return false
        }
    }
    
    private func loadUserProfile(userId: String) async {
        do {
            let document = try await firestore.collection("users").document(userId).getDocument()
            
            if document.exists, let data = document.data() {
                userProfile = UserProfile(
                    id: userId,
                    email: data["email"] as? String ?? "",
                    fullName: data["fullName"] as? String ?? "",
                    profileImageURL: data["profileImageURL"] as? String,
                    authProvider: data["authProvider"] as? String ?? "email",
                    isOnboardingComplete: data["isOnboardingComplete"] as? Bool ?? false,
                    userType: UserType(rawValue: data["userType"] as? String ?? "Petitioner") ?? .petitioner,
                    mobileNumber: data["mobileNumber"] as? String,
                    userId: data["userId"] as? String,
                    barRegistrationNumber: data["barRegistrationNumber"] as? String,
                    specialization: data["specialization"] as? String,
                    yearsOfExperience: data["yearsOfExperience"] as? String,
                    enrolledState: data["enrolledState"] as? String,
                    enrolledDistrict: data["enrolledDistrict"] as? String,
                    enrolledEstablishment: data["enrolledEstablishment"] as? String
                )
            }
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
    
    private func saveUserProfile(_ profile: UserProfile) async {
        do {
            let data: [String: Any] = [
                "email": profile.email,
                "fullName": profile.fullName,
                "profileImageURL": profile.profileImageURL ?? "",
                "authProvider": profile.authProvider,
                "isOnboardingComplete": profile.isOnboardingComplete,
                "userType": profile.userType?.rawValue ?? "",
                "mobileNumber": profile.mobileNumber ?? "",
                "userId": profile.userId ?? "",
                "barRegistrationNumber": profile.barRegistrationNumber ?? "",
                "specialization": profile.specialization ?? "",
                "yearsOfExperience": profile.yearsOfExperience ?? "",
                "enrolledState": profile.enrolledState ?? "",
                "enrolledDistrict": profile.enrolledDistrict ?? "",
                "enrolledEstablishment": profile.enrolledEstablishment ?? "",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            try await firestore.collection("users").document(profile.id).setData(data, merge: true)
            userProfile = profile
        } catch {
            print("Error saving user profile: \(error)")
            errorMessage = "Failed to save user profile"
        }
    }
    
    // MARK: - Onboarding Completion
    func completeOnboarding(coordinator: OnboardingCoordinator) async {
        guard let user = currentUser else { return }
        
        isLoading = true
        
        let updatedProfile = UserProfile(
            id: user.uid,
            email: userProfile?.email ?? user.email ?? "",
            fullName: coordinator.fullName.isEmpty ? (userProfile?.fullName ?? user.displayName ?? "") : coordinator.fullName,
            profileImageURL: userProfile?.profileImageURL ?? user.photoURL?.absoluteString,
            authProvider: userProfile?.authProvider ?? "email",
            isOnboardingComplete: true,
            userType: coordinator.userType,
            mobileNumber: coordinator.mobileNumber,
            userId: coordinator.userId,
            barRegistrationNumber: coordinator.barRegistrationNumber,
            specialization: coordinator.specialization,
            yearsOfExperience: coordinator.yearsOfExperience,
            enrolledState: coordinator.enrolledState,
            enrolledDistrict: coordinator.enrolledDistrict,
            enrolledEstablishment: coordinator.enrolledEstablishment
        )
        
        await saveUserProfile(updatedProfile)
        
        // Navigate to dashboard
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToDashboard"), object: nil)
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut(clearSavedCredentials: Bool = false) {
        do {
            try auth.signOut()
            GIDSignIn.sharedInstance.signOut()
            
            // Clear local data
            userProfile = nil
            currentUser = nil
            isSignedIn = false
            
            // Clear saved credentials if requested
            if clearSavedCredentials {
                keychainManager.clearCredentials()
                rememberMe = false
            }
            
            // Navigate back to login
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToLogin"), object: nil)
            
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - UserProfile Model
struct UserProfile: Codable {
    let id: String
    let email: String
    let fullName: String
    let profileImageURL: String?
    let authProvider: String
    let isOnboardingComplete: Bool
    let userType: UserType?
    let mobileNumber: String?
    let userId: String?
    let barRegistrationNumber: String?
    let specialization: String?
    let yearsOfExperience: String?
    let enrolledState: String?
    let enrolledDistrict: String?
    let enrolledEstablishment: String?
    
    init(id: String, email: String, fullName: String, profileImageURL: String? = nil, 
         authProvider: String, isOnboardingComplete: Bool, userType: UserType? = nil,
         mobileNumber: String? = nil, userId: String? = nil, barRegistrationNumber: String? = nil,
         specialization: String? = nil, yearsOfExperience: String? = nil, enrolledState: String? = nil,
         enrolledDistrict: String? = nil, enrolledEstablishment: String? = nil) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.profileImageURL = profileImageURL
        self.authProvider = authProvider
        self.isOnboardingComplete = isOnboardingComplete
        self.userType = userType
        self.mobileNumber = mobileNumber
        self.userId = userId
        self.barRegistrationNumber = barRegistrationNumber
        self.specialization = specialization
        self.yearsOfExperience = yearsOfExperience
        self.enrolledState = enrolledState
        self.enrolledDistrict = enrolledDistrict
        self.enrolledEstablishment = enrolledEstablishment
    }
}

// MARK: - UserType Extension
enum UserType: String, CaseIterable, Codable {
    case petitioner = "Petitioner"
    case advocate = "Advocate"
    
    var icon: String {
        switch self {
        case .petitioner: return "person.fill"
        case .advocate: return "briefcase.fill"
        }
    }
    
    func localizedTitle(localizationManager: LocalizationManager) -> String {
        switch self {
        case .petitioner: return localizationManager.text("petitioner")
        case .advocate: return localizationManager.text("advocate")
        }
    }
    
    func localizedDescription(localizationManager: LocalizationManager) -> String {
        switch self {
        case .petitioner: return localizationManager.text("petitioner_description")
        case .advocate: return localizationManager.text("advocate_description")
        }
    }
    
    var description: String {
        switch self {
        case .petitioner: return "File complaints and seek legal assistance"
        case .advocate: return "Provide legal services and represent clients"
        }
    }
    
    var color: Color {
        switch self {
        case .petitioner: return .blue
        case .advocate: return .purple
        }
    }
}
