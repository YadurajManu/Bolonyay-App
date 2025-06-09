import SwiftUI

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Custom button style for smooth interactions
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct LoginView: View {
    @State private var showOtherOptions = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsConditions = false
    @StateObject private var authManager = AuthenticationManager()
    @EnvironmentObject var localizationManager: LocalizationManager
    

    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Top illustration
                VStack(spacing: 16) {
                    if let uiImage = UIImage(named: "loginphoto") ?? UIImage(contentsOfFile: Bundle.main.path(forResource: "loginphoto", ofType: "jpeg") ?? "") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .padding(.horizontal, 40)
                    } else {
                        // Fallback placeholder
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(maxHeight: 280)
                            .padding(.horizontal, 40)
                            .overlay(
                                Text("Login Image")
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // BoloNyay brand text beneath the photo
                    Text("BoloNyay")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#FF9933"))
                        .tracking(1.2)
                }
                
                Spacer()
                    .frame(height: 60)
                
                // Title
                Text(localizationManager.localizedString(for: "setup_account_title"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height: 24)
                
                // Description
                VStack(spacing: 4) {
                    Text(localizationManager.localizedString(for: "signin_description_1"))
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text(localizationManager.localizedString(for: "signin_description_2"))
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text(localizationManager.localizedString(for: "signin_description_3"))
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 40)
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                    .frame(height: 50)
                
                // Sign in buttons
                VStack(spacing: 16) {
                    // Sign in with Apple
                    Button(action: {
                        // Handle Apple sign in - for first time users, show onboarding
                        // TODO: Implement Apple Sign-In
                        NotificationCenter.default.post(name: NSNotification.Name("LoginCompleted"), object: nil)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                            
                            Text(localizationManager.localizedString(for: "sign_in_with_apple"))
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 40)
                    
                    // Sign in with Google
                    Button(action: {
                        Task {
                            await authManager.signInWithGoogle()
                        }
                    }) {
                        HStack(spacing: 12) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                // Google icon placeholder
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 24, height: 24)
                                    
                                    Text("G")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text(localizationManager.localizedString(for: "sign_in_with_google"))
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 40)
                    
                    // Other Sign-in Options with Enhanced Dropdown
                    VStack(spacing: 0) {
                        // Main dropdown button with improved styling
                        Button(action: {
                            withAnimation(.interpolatingSpring(stiffness: 280, damping: 22)) {
                                showOtherOptions.toggle()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Text(localizationManager.localizedString(for: "other_signin_options"))
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .rotationEffect(.degrees(showOtherOptions ? 180 : 0))
                                    .scaleEffect(showOtherOptions ? 1.1 : 1.0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(showOtherOptions ? 0.25 : 0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(showOtherOptions ? 0.4 : 0.3), lineWidth: 0.5)
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 40)
                        
                        // Enhanced dropdown content with better animations
                        if showOtherOptions {
                            VStack(spacing: 0) {
                                // Elegant separator
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.clear, Color.gray.opacity(0.3), Color.clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 60)
                                    .padding(.top, 8)
                                
                                VStack(spacing: 10) {
                                    // Phone Number Option with enhanced design
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            // Navigate to phone auth view (for future implementation)
                                            NotificationCenter.default.post(name: NSNotification.Name("NavigateToEmailAuth"), object: nil)
                                        }
                                    }) {
                                        HStack(spacing: 16) {
                                                                                         // Icon with background
                                             ZStack {
                                                 Circle()
                                                     .fill(Color.white.opacity(0.1))
                                                     .frame(width: 32, height: 32)
                                                 
                                                 Image(systemName: "phone.fill")
                                                     .font(.system(size: 14, weight: .medium))
                                                     .foregroundColor(.black)
                                             }
                                            
                                            Text(localizationManager.localizedString(for: "signin_with_phone"))
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.gray.opacity(0.6))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .padding(.horizontal, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.gray.opacity(0.08))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                                                )
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .padding(.horizontal, 40)
                                    
                                    // Email Option with enhanced design
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            // Navigate to email auth view
                                            NotificationCenter.default.post(name: NSNotification.Name("NavigateToEmailAuth"), object: nil)
                                        }
                                    }) {
                                        HStack(spacing: 16) {
                                                                                         // Icon with background
                                             ZStack {
                                                 Circle()
                                                     .fill(Color.white.opacity(0.1))
                                                     .frame(width: 32, height: 32)
                                                 
                                                 Image(systemName: "envelope.fill")
                                                     .font(.system(size: 14, weight: .medium))
                                                     .foregroundColor(.black)
                                             }
                                            
                                            Text(localizationManager.localizedString(for: "signin_with_email"))
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.gray.opacity(0.6))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .padding(.horizontal, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.gray.opacity(0.08))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                                                )
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .padding(.horizontal, 40)
                                }
                                .padding(.vertical, 16)
                            }
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95, anchor: .top)
                                    .combined(with: .opacity)
                                    .combined(with: .move(edge: .top)),
                                removal: .scale(scale: 0.95, anchor: .top)
                                    .combined(with: .opacity)
                                    .combined(with: .move(edge: .top))
                            ))
                        }
                    }
                    .clipped()
                }
                
                Spacer()
                    .frame(height: 40)
                
                // Terms and Privacy - Enhanced with animations
                VStack(spacing: 8) {
                    Text(localizationManager.localizedString(for: "by_continuing_agree"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 6) {
                        Button(action: {
                            withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                                showPrivacyPolicy = true
                            }
                        }) {
                            Text(localizationManager.localizedString(for: "privacy_policy"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .underline()
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Text(localizationManager.localizedString(for: "and"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                                showTermsConditions = true
                            }
                        }) {
                            Text(localizationManager.localizedString(for: "terms_conditions"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .underline()
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsConditions) {
            TermsConditionsView()
        }
    }
}

#Preview {
    LoginView()
} 
