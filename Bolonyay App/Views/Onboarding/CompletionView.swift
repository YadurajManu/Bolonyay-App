import SwiftUI

struct CompletionView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showCelebration = false
    @State private var animateElements = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)
                
                // Success Animation
                VStack(spacing: 24) {
                    ZStack {
                        // Background circles
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 200, height: 200)
                            .scaleEffect(showCelebration ? 1.2 : 0.8)
                            .opacity(showCelebration ? 0.3 : 0)
                        
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 150, height: 150)
                            .scaleEffect(showCelebration ? 1.1 : 0.9)
                            .opacity(showCelebration ? 0.5 : 0)
                        
                        // Main success icon
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundColor(.green)
                                .scaleEffect(showCelebration ? 1.0 : 0.5)
                        }
                    }
                    .animation(.spring(duration: 0.8, bounce: 0.4), value: showCelebration)
                    
                    // Welcome message
                    VStack(spacing: 12) {
                        Text(localizationManager.text("welcome_bolonyay"))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                        
                        Text(localizationManager.text("account_created_successfully"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                    }
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateElements)
                }
                
                // User summary card
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(coordinator.userType.color.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: coordinator.userType.icon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(coordinator.userType.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(coordinator.fullName.isEmpty ? localizationManager.text("user") : coordinator.fullName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(coordinator.userType.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(coordinator.userType.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // Details
                    VStack(spacing: 16) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        
                        VStack(spacing: 12) {
                            InfoRow(icon: "envelope.fill", title: localizationManager.text("email"), value: coordinator.email)
                            InfoRow(icon: "phone.fill", title: localizationManager.text("mobile"), value: coordinator.mobileNumber)
                            InfoRow(icon: "location.fill", title: localizationManager.text("location"), value: "\(coordinator.enrolledDistrict), \(coordinator.enrolledState)")
                            
                            if coordinator.userType == .advocate && !coordinator.specialization.isEmpty {
                                InfoRow(icon: "scale.3d", title: "Specialization", value: coordinator.specialization)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .opacity(animateElements ? 1 : 0)
                .offset(y: animateElements ? 0 : 30)
                .animation(.easeOut(duration: 0.6).delay(0.6), value: animateElements)
                
                // Features preview
                VStack(spacing: 16) {
                    Text(localizationManager.text("whats_next"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.9), value: animateElements)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        FeatureCard(
                            icon: "doc.text.fill",
                            title: coordinator.userType == .advocate ? "Manage Cases" : localizationManager.text("file_complaints"),
                            color: .blue
                        )
                        
                        FeatureCard(
                            icon: "person.2.fill",
                            title: coordinator.userType == .advocate ? "Connect with Clients" : localizationManager.text("find_advocates"),
                            color: .purple
                        )
                        
                        FeatureCard(
                            icon: "globe.asia.australia.fill",
                            title: localizationManager.text("multi_language_support"),
                            color: .green
                        )
                        
                        FeatureCard(
                            icon: "shield.checkered",
                            title: localizationManager.text("secure_encrypted"),
                            color: .orange
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 40)
                    .animation(.easeOut(duration: 0.8).delay(1.2), value: animateElements)
                }
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showCelebration = true
                animateElements = true
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CompletionView(coordinator: OnboardingCoordinator())
    }
} 