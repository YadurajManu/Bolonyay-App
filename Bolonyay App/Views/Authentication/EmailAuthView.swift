import SwiftUI

struct EmailAuthView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var animateContent = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsConditions = false
    @FocusState private var focusedField: Field?
    
    enum Field: CaseIterable {
        case fullName, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            // Back button
                            HStack {
                                Button(action: {
                                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToLogin"), object: nil)
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Text("Back")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.1))
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(x: animateContent ? 0 : -20)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.1), value: animateContent)
                            
                            // Title
                            VStack(spacing: 8) {
                                Text(isSignUp ? "Create Account" : "Welcome Back")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    .offset(y: animateContent ? 0 : 30)
                                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: animateContent)
                                
                                Text(isSignUp ? "Join BoloNyay to get started" : "Sign in to your account")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    .offset(y: animateContent ? 0 : 20)
                                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.3), value: animateContent)
                            }
                        }
                        
                        // Form
                        VStack(spacing: 20) {
                            // Full Name (Sign Up only)
                            if isSignUp {
                                CleanTextField(
                                    title: "Full Name",
                                    text: $fullName,
                                    placeholder: "Enter your full name",
                                    icon: "person",
                                    keyboardType: .default,
                                    isFocused: focusedField == .fullName,
                                    animationDelay: 0.4,
                                    isAnimated: animateContent
                                )
                                .focused($focusedField, equals: .fullName)
                                .scaleEffect(animateContent ? 1.0 : 0.95)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(x: animateContent ? 0 : -20)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.4), value: animateContent)
                            }
                            
                            // Email
                            CleanTextField(
                                title: "Email Address",
                                text: $email,
                                placeholder: "your.email@example.com",
                                icon: "envelope",
                                keyboardType: .emailAddress,
                                isFocused: focusedField == .email,
                                animationDelay: isSignUp ? 0.5 : 0.4,
                                isAnimated: animateContent
                            )
                            .focused($focusedField, equals: .email)
                            .scaleEffect(animateContent ? 1.0 : 0.95)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(x: animateContent ? 0 : 20)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(isSignUp ? 0.5 : 0.4), value: animateContent)
                            
                            // Password
                            CleanTextField(
                                title: "Password",
                                text: $password,
                                placeholder: "Enter your password",
                                icon: "lock",
                                keyboardType: .default,
                                isFocused: focusedField == .password,
                                animationDelay: isSignUp ? 0.6 : 0.5,
                                isAnimated: animateContent,
                                isSecure: true
                            )
                            .focused($focusedField, equals: .password)
                            .scaleEffect(animateContent ? 1.0 : 0.95)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(x: animateContent ? 0 : -20)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(isSignUp ? 0.6 : 0.5), value: animateContent)
                            
                            // Confirm Password (Sign Up only)
                            if isSignUp {
                                CleanTextField(
                                    title: "Confirm Password",
                                    text: $confirmPassword,
                                    placeholder: "Confirm your password",
                                    icon: "lock.rotation",
                                    keyboardType: .default,
                                    isFocused: focusedField == .confirmPassword,
                                    animationDelay: 0.7,
                                    isAnimated: animateContent,
                                    isSecure: true
                                )
                                .focused($focusedField, equals: .confirmPassword)
                                .scaleEffect(animateContent ? 1.0 : 0.95)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(x: animateContent ? 0 : 20)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.7), value: animateContent)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        // Action Button
                        Button(action: {
                            handleAuthentication()
                        }) {
                            HStack(spacing: 12) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(isFormValid ? 0.9 : 0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(!isFormValid || authManager.isLoading)
                        .padding(.horizontal, 24)
                        .scaleEffect(animateContent ? 1.0 : 0.95)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.8), value: animateContent)
                        
                        // Toggle Sign In/Sign Up
                        VStack(spacing: 16) {
                            HStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                                
                                Text("or")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 16)
                                
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                            }
                            
                            Button(action: {
                                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                                    isSignUp.toggle()
                                    clearForm()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text(isSignUp ? "Sign In" : "Sign Up")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .underline()
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        .scaleEffect(animateContent ? 1.0 : 0.95)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.9), value: animateContent)
                        
                        // Terms and Privacy - Enhanced with animations
                        if isSignUp {
                            VStack(spacing: 8) {
                                Text("By creating an account, you agree to")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 6) {
                                    Button(action: {
                                        withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                                            showPrivacyPolicy = true
                                        }
                                    }) {
                                        Text("Privacy Policy")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .underline()
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    
                                    Text("and")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                                            showTermsConditions = true
                                        }
                                    }) {
                                        Text("Terms & Conditions")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .underline()
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 32)
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
                            .scaleEffect(animateContent ? 1.0 : 0.95)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(1.0), value: animateContent)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .onTapGesture {
                focusedField = nil
            }
            .onAppear {
                animateContent = true
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsConditions) {
            TermsConditionsView()
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !fullName.isEmpty && 
                   !email.isEmpty && 
                   !password.isEmpty && 
                   !confirmPassword.isEmpty &&
                   password == confirmPassword &&
                   password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func handleAuthentication() {
        Task {
            if isSignUp {
                await authManager.signUpWithEmail(email: email, password: password, fullName: fullName)
            } else {
                await authManager.signInWithEmail(email: email, password: password)
            }
        }
    }
    
    private func clearForm() {
        fullName = ""
        email = ""
        password = ""
        confirmPassword = ""
        focusedField = nil
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EmailAuthView()
    }
} 