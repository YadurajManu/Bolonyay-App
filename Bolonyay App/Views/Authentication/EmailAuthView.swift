import SwiftUI

struct EmailAuthView: View {
    @StateObject private var authManager = AuthenticationManager()
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var phone = ""
    @State private var animateContent = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsConditions = false

    @FocusState private var focusedField: Field?
    
    enum Field: CaseIterable {
        case fullName, phone, email, password, confirmPassword
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
                                        
                                        Text(localizationManager.text("back"))
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
                                Text(isSignUp ? localizationManager.text("create_account") : localizationManager.text("welcome_back"))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    .offset(y: animateContent ? 0 : 30)
                                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: animateContent)
                                
                                Text(isSignUp ? localizationManager.text("join_bolonyay_to_get_started") : localizationManager.text("sign_in_to_your_account"))
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
                                VoiceEnabledTextField(
                                    title: localizationManager.text("full_name"),
                                    text: $fullName,
                                    placeholder: localizationManager.text("enter_your_full_name"),
                                    icon: "person",
                                    keyboardType: .default,
                                    isFocused: focusedField == .fullName,
                                    animationDelay: 0.4,
                                    isAnimated: animateContent,
                                    voiceFieldType: .name
                                )
                                .focused($focusedField, equals: .fullName)
                                .scaleEffect(animateContent ? 1.0 : 0.95)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(x: animateContent ? 0 : -20)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.4), value: animateContent)
                            }
                            
                            // Phone Number (Sign Up only)
                            if isSignUp {
                                VoiceEnabledTextField(
                                    title: localizationManager.text("mobile_number"),
                                    text: $phone,
                                    placeholder: localizationManager.text("mobile_placeholder"),
                                    icon: "phone",
                                    keyboardType: .phonePad,
                                    isFocused: focusedField == .phone,
                                    animationDelay: 0.5,
                                    isAnimated: animateContent,
                                    voiceFieldType: .phone
                                )
                                .focused($focusedField, equals: .phone)
                                .scaleEffect(animateContent ? 1.0 : 0.95)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(x: animateContent ? 0 : 20)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.5), value: animateContent)
                            }
                            
                            // Email
                            VoiceEnabledTextField(
                                title: localizationManager.text("email_address"),
                                text: $email,
                                placeholder: localizationManager.text("your_email_example"),
                                icon: "envelope",
                                keyboardType: .emailAddress,
                                isFocused: focusedField == .email,
                                animationDelay: isSignUp ? 0.6 : 0.4,
                                isAnimated: animateContent,
                                voiceFieldType: isSignUp ? .email : nil
                            )
                            .focused($focusedField, equals: .email)
                            .scaleEffect(animateContent ? 1.0 : 0.95)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(x: animateContent ? 0 : 20)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(isSignUp ? 0.6 : 0.4), value: animateContent)
                            
                            // Password
                            VoiceEnabledTextField(
                                title: localizationManager.text("password"),
                                text: $password,
                                placeholder: localizationManager.text("enter_your_password"),
                                icon: "lock",
                                keyboardType: .default,
                                isFocused: focusedField == .password,
                                animationDelay: isSignUp ? 0.7 : 0.5,
                                isAnimated: animateContent,
                                isSecure: true,
                                voiceFieldType: .password
                            )
                            .focused($focusedField, equals: .password)
                            .scaleEffect(animateContent ? 1.0 : 0.95)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(x: animateContent ? 0 : -20)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(isSignUp ? 0.7 : 0.5), value: animateContent)
                            
                            // Confirm Password (Sign Up only)
                            if isSignUp {
                                VoiceEnabledTextField(
                                    title: localizationManager.text("confirm_password"),
                                    text: $confirmPassword,
                                    placeholder: localizationManager.text("confirm_your_password"),
                                    icon: "lock.rotation",
                                    keyboardType: .default,
                                    isFocused: focusedField == .confirmPassword,
                                    animationDelay: 0.8,
                                    isAnimated: animateContent,
                                    isSecure: true,
                                    voiceFieldType: .password
                                )
                                .focused($focusedField, equals: .confirmPassword)
                                .scaleEffect(animateContent ? 1.0 : 0.95)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(x: animateContent ? 0 : 20)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.8), value: animateContent)
                            }
                        }
                        .padding(.horizontal, 24)
                        

                        
                        // Remember Me Toggle (Sign In only)
                        if !isSignUp {
                            HStack(spacing: 12) {
                                Button(action: {
                                    withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                                        authManager.toggleRememberMe()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                                .frame(width: 18, height: 18)
                                            
                                            if authManager.rememberMe {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.green)
                                                    .scaleEffect(authManager.rememberMe ? 1.0 : 0.0)
                                                    .animation(.spring(duration: 0.3, bounce: 0.6), value: authManager.rememberMe)
                                            }
                                        }
                                        
                                        Text(localizationManager.text("remember_me"))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .buttonStyle(ScaleButtonStyle())
                                
                                Spacer()
                                
                                Button(action: {
                                    // TODO: Implement forgot password
                                    print("Forgot password tapped")
                                }) {
                                    Text(localizationManager.text("forgot_password"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .underline()
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .padding(.horizontal, 24)
                            .scaleEffect(animateContent ? 1.0 : 0.95)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.7), value: animateContent)
                        }
                        
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
                                    Text(isSignUp ? localizationManager.text("create_account_button") : localizationManager.text("sign_in"))
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
                                
                                Text(localizationManager.text("or"))
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
                                    Text(isSignUp ? localizationManager.text("already_have_account") : localizationManager.text("dont_have_account"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text(isSignUp ? localizationManager.text("sign_in") : localizationManager.text("sign_up"))
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
                                Text(localizationManager.text("by_creating_account_agree"))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 6) {
                                    Button(action: {
                                        withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                                            showPrivacyPolicy = true
                                        }
                                    }) {
                                        Text(localizationManager.text("privacy_policy"))
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .underline()
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    
                                    Text(localizationManager.text("and"))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                                            showTermsConditions = true
                                        }
                                    }) {
                                        Text(localizationManager.text("terms_conditions_short"))
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
                loadSavedCredentials()
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
    
    private func loadSavedCredentials() {
        if !isSignUp, let credentials = authManager.loadSavedCredentials() {
            email = credentials.email ?? ""
            password = credentials.password ?? ""
            print("🔑 Loaded saved credentials for: \(email)")
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EmailAuthView()
    }
} 