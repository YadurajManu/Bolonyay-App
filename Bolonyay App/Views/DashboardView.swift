import SwiftUI

struct DashboardView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @StateObject private var authManager = AuthenticationManager()
    @State private var animateContent = false
    @State private var showLogoutAlert = false
    
    // Computed properties to simplify complex expressions
    private var displayName: String {
        if let profileName = authManager.userProfile?.fullName, !profileName.isEmpty {
            return profileName
        } else if !coordinator.fullName.isEmpty {
            return coordinator.fullName
        } else {
            return "User"
        }
    }
    
    private var profileImageURL: String? {
        authManager.userProfile?.profileImageURL
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome header
                        VStack(spacing: 12) {
                            Text("Welcome Back!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 30)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.1), value: animateContent)
                            
                            Text("Your BoloNyay Dashboard")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: animateContent)
                        }
                        .padding(.top, 20)
                        
                        // User profile card
                        VStack(spacing: 0) {
                            // Profile header
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 70, height: 70)
                                    
                                    if let imageURL = profileImageURL, !imageURL.isEmpty {
                                        AsyncImage(url: URL(string: imageURL)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 70, height: 70)
                                                .clipShape(Circle())
                                        } placeholder: {
                                            Image(systemName: coordinator.userType.icon)
                                                .font(.system(size: 28, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                    } else {
                                        Image(systemName: coordinator.userType.icon)
                                            .font(.system(size: 28, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                                .scaleEffect(animateContent ? 1.0 : 0.3)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.spring(duration: 0.8, bounce: 0.5).delay(0.3), value: animateContent)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(displayName)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    HStack(spacing: 8) {
                                        Text(coordinator.userType.rawValue)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.15))
                                            )
                                        
                                        Spacer()
                                    }
                                }
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(x: animateContent ? 0 : 20)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.4), value: animateContent)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            
                            // Divider
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.5), value: animateContent)
                            
                            // User details
                            VStack(spacing: 16) {
                                UserDetailRow(
                                    icon: "envelope.fill",
                                    title: "Email",
                                    value: coordinator.email,
                                    animationDelay: 0.6,
                                    isAnimated: animateContent
                                )
                                
                                UserDetailRow(
                                    icon: "phone.fill",
                                    title: "Mobile",
                                    value: coordinator.mobileNumber,
                                    animationDelay: 0.7,
                                    isAnimated: animateContent
                                )
                                
                                UserDetailRow(
                                    icon: "at",
                                    title: "User ID",
                                    value: coordinator.userId,
                                    animationDelay: 0.8,
                                    isAnimated: animateContent
                                )
                                
                                if !coordinator.enrolledState.isEmpty && !coordinator.enrolledDistrict.isEmpty {
                                    UserDetailRow(
                                        icon: "location.fill",
                                        title: "Location",
                                        value: "\(coordinator.enrolledDistrict), \(coordinator.enrolledState)",
                                        animationDelay: 0.9,
                                        isAnimated: animateContent
                                    )
                                }
                                
                                // Advocate specific details
                                if coordinator.userType == .advocate {
                                    if !coordinator.barRegistrationNumber.isEmpty {
                                        UserDetailRow(
                                            icon: "doc.text.fill",
                                            title: "Bar Registration",
                                            value: coordinator.barRegistrationNumber,
                                            animationDelay: 1.0,
                                            isAnimated: animateContent
                                        )
                                    }
                                    
                                    if !coordinator.specialization.isEmpty {
                                        UserDetailRow(
                                            icon: "scale.3d",
                                            title: "Specialization",
                                            value: coordinator.specialization,
                                            animationDelay: 1.1,
                                            isAnimated: animateContent
                                        )
                                    }
                                    
                                    if !coordinator.yearsOfExperience.isEmpty {
                                        UserDetailRow(
                                            icon: "calendar.badge.clock",
                                            title: "Experience",
                                            value: "\(coordinator.yearsOfExperience) years",
                                            animationDelay: 1.2,
                                            isAnimated: animateContent
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.05))
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .scaleEffect(animateContent ? 1.0 : 0.95)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.6), value: animateContent)
                        
                        // Coming soon section
                        VStack(spacing: 16) {
                            Text("Coming Soon")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(1.3), value: animateContent)
                            
                            Text("More features will be available here soon")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(1.4), value: animateContent)
                        }
                        .padding(.vertical, 40)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Logout")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .onAppear {
            animateContent = true
        }
    }
    
    private func logout() {
        // Sign out using authentication manager
        authManager.signOut()
        
        // Reset coordinator state
        coordinator.reset()
    }
}

struct UserDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let animationDelay: Double
    let isAnimated: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(x: isAnimated ? 0 : -20)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay), value: isAnimated)
    }
}

#Preview {
    let coordinator = OnboardingCoordinator()
    coordinator.userType = .advocate
    coordinator.fullName = "John Doe"
    coordinator.email = "john.doe@example.com"
    coordinator.mobileNumber = "+91 98765 43210"
    coordinator.userId = "johndoe123"
    coordinator.specialization = "Criminal Law"
    coordinator.barRegistrationNumber = "BAR123456"
    coordinator.yearsOfExperience = "5"
    
    return DashboardView(coordinator: coordinator)
} 
