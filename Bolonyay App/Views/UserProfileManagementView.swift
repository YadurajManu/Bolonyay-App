import SwiftUI
import FirebaseAuth

struct UserProfileManagementView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedEmail = ""
    @State private var editedMobile = ""
    @State private var selectedUserType: UserType = .petitioner
    @State private var showingSignUpSheet = false
    @State private var animateContent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Text("Profile Management")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Manage your account information")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : -20)
                        .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.1), value: animateContent)
                        
                        // Profile Content
                        if authManager.isSignedIn, let userProfile = authManager.userProfile {
                            authenticatedUserProfile(userProfile)
                        } else if let boloUser = firebaseManager.getCurrentUser() {
                            basicUserProfile(boloUser)
                        } else {
                            guestUserProfile()
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                if authManager.isSignedIn || firebaseManager.getCurrentUser() != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditing ? "Save" : "Edit") {
                            if isEditing {
                                saveChanges()
                            } else {
                                startEditing()
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
            loadCurrentData()
        }
        .sheet(isPresented: $showingSignUpSheet) {
            EmailAuthView()
        }
    }
    
    // MARK: - Profile Views
    
    @ViewBuilder
    private func authenticatedUserProfile(_ profile: UserProfile) -> some View {
        VStack(spacing: 24) {
            // Profile Avatar
            profileAvatar(
                name: profile.fullName,
                imageURL: profile.profileImageURL,
                userType: profile.userType
            )
            
            // Profile Information
            VStack(spacing: 16) {
                profileField(
                    icon: "person.fill",
                    title: "Full Name",
                    value: isEditing ? $editedName : .constant(profile.fullName),
                    isEditable: isEditing
                )
                
                profileField(
                    icon: "envelope.fill",
                    title: "Email",
                    value: isEditing ? $editedEmail : .constant(profile.email),
                    isEditable: isEditing
                )
                
                profileField(
                    icon: "phone.fill",
                    title: "Mobile",
                    value: isEditing ? $editedMobile : .constant(profile.mobileNumber ?? "Not provided"),
                    isEditable: isEditing
                )
                
                // User Type
                HStack {
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    Text("Account Type")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(profile.userType?.rawValue ?? "Petitioner")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            
            // Account Status
            accountStatusView(
                provider: profile.authProvider,
                isComplete: profile.isOnboardingComplete
            )
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: animateContent)
    }
    
    @ViewBuilder
    private func basicUserProfile(_ user: FirebaseManager.BoloNyayUser) -> some View {
        VStack(spacing: 24) {
            // Profile Avatar
            profileAvatar(
                name: user.name,
                imageURL: nil,
                userType: user.userType == .advocate ? .advocate : .petitioner
            )
            
            // Upgrade Notice
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Basic Account")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                Text("You're using a basic account created for case filing. Create a full account for better features and security.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    showingSignUpSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                        Text("Create Full Account")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            
            // Basic Information
            VStack(spacing: 16) {
                profileField(
                    icon: "person.fill",
                    title: "Name",
                    value: .constant(user.name),
                    isEditable: false
                )
                
                profileField(
                    icon: "envelope.fill",
                    title: "Email",
                    value: .constant(user.email ?? "Not provided"),
                    isEditable: false
                )
                
                profileField(
                    icon: "globe",
                    title: "Language",
                    value: .constant(user.language.capitalized),
                    isEditable: false
                )
            }
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: animateContent)
    }
    
    @ViewBuilder
    private func guestUserProfile() -> some View {
        VStack(spacing: 32) {
            // Guest Icon
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.6))
                )
            
            VStack(spacing: 16) {
                Text("No Account")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Create an account to save your cases, access your legal documents, and get personalized assistance.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    Button(action: {
                        showingSignUpSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Create Account")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    
                    Button(action: {
                        // Create basic account for now
                        createBasicAccount()
                    }) {
                        Text("Continue as Guest")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                }
            }
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: animateContent)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func profileAvatar(name: String, imageURL: String?, userType: UserType?) -> some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 100, height: 100)
                .overlay(
                    Group {
                        if let imageURL = imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: userType?.icon ?? "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                            .clipShape(Circle())
                        } else {
                            Image(systemName: userType?.icon ?? "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }
                )
            
            VStack(spacing: 4) {
                Text(name.isEmpty ? "User" : name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                if let userType = userType {
                    Text(userType.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.2))
                        )
                }
            }
        }
    }
    
    @ViewBuilder
    private func profileField(icon: String, title: String, value: Binding<String>, isEditable: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            if isEditable {
                TextField("Enter \(title.lowercased())", text: value)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
            } else {
                Text(value.wrappedValue.isEmpty ? "Not provided" : value.wrappedValue)
                    .font(.system(size: 16))
                    .foregroundColor(value.wrappedValue.isEmpty ? .white.opacity(0.5) : .white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func accountStatusView(provider: String, isComplete: Bool) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "clock.circle.fill")
                    .foregroundColor(isComplete ? .green : .orange)
                
                Text("Account Status")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(isComplete ? "Complete" : "Incomplete")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isComplete ? .green : .orange)
            }
            
            HStack {
                Text("Sign-in method:")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text(provider.capitalized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Functions
    
    private func loadCurrentData() {
        if let profile = authManager.userProfile {
            editedName = profile.fullName
            editedEmail = profile.email
            editedMobile = profile.mobileNumber ?? ""
            selectedUserType = profile.userType ?? .petitioner
        }
    }
    
    private func startEditing() {
        loadCurrentData()
        isEditing = true
    }
    
    private func saveChanges() {
        // Implementation would go here to update the user profile
        // This would involve updating both AuthenticationManager and FirebaseManager
        isEditing = false
        print("💾 Saving changes: Name=\(editedName), Email=\(editedEmail), Mobile=\(editedMobile)")
    }
    
    private func createBasicAccount() {
        Task {
            do {
                let user = try await firebaseManager.createUser(
                    email: nil,
                    name: "BoloNyay User",
                    userType: .petitioner,
                    language: LocalizationManager.shared.currentLanguage
                )
                print("✅ Created basic account: \(user.name)")
                dismiss()
            } catch {
                print("❌ Failed to create basic account: \(error)")
            }
        }
    }
} 