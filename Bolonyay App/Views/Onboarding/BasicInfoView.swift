import SwiftUI

struct BasicInfoView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @FocusState private var focusedField: Field?
    @State private var animateFields = false
    
    enum Field: CaseIterable {
        case fullName, mobile, email, userId
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Enhanced header with icon
                VStack(spacing: 16) {
                    // Animated icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 60, height: 60)
                            .scaleEffect(animateFields ? 1.0 : 0.3)
                            .opacity(animateFields ? 1.0 : 0.0)
                            .animation(.spring(duration: 0.8, bounce: 0.4).delay(0.1), value: animateFields)
                        
                        Image(systemName: coordinator.userType == .petitioner ? "person.fill" : "briefcase.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .scaleEffect(animateFields ? 1.0 : 0.3)
                            .opacity(animateFields ? 1.0 : 0.0)
                            .animation(.spring(duration: 0.8, bounce: 0.5).delay(0.2), value: animateFields)
                    }
                    
                    VStack(spacing: 8) {
                        Text(coordinator.userType == .petitioner ? "Basic Information" : "Your Details")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(animateFields ? 1.0 : 0.0)
                            .offset(y: animateFields ? 0 : 30)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.3), value: animateFields)
                        
                        Text(coordinator.userType == .petitioner ? 
                             "Just the essentials to get you started" :
                             "Complete your professional profile")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .opacity(animateFields ? 1.0 : 0.0)
                            .offset(y: animateFields ? 0 : 20)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.4), value: animateFields)
                    }
                }
                .padding(.top, 20)
                
                // Form Fields - Dynamic based on user type
                VStack(spacing: 20) {
                    // Mobile Number (Required for both)
                    CleanTextField(
                        title: "Mobile Number",
                        text: $coordinator.mobileNumber,
                        placeholder: "+91 98765 43210",
                        icon: "phone",
                        keyboardType: .phonePad,
                        isFocused: focusedField == .mobile,
                        animationDelay: 0.6,
                        isAnimated: animateFields
                    )
                    .focused($focusedField, equals: .mobile)
                    .scaleEffect(animateFields ? 1.0 : 0.95)
                    .opacity(animateFields ? 1.0 : 0.0)
                    .offset(x: animateFields ? 0 : -20)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.6), value: animateFields)
                    
                    // Email (Required for both)
                    CleanTextField(
                        title: "Email ID",
                        text: $coordinator.email,
                        placeholder: "your.email@example.com",
                        icon: "envelope",
                        keyboardType: .emailAddress,
                        isFocused: focusedField == .email,
                        animationDelay: 0.7,
                        isAnimated: animateFields
                    )
                    .focused($focusedField, equals: .email)
                    .scaleEffect(animateFields ? 1.0 : 0.95)
                    .opacity(animateFields ? 1.0 : 0.0)
                    .offset(x: animateFields ? 0 : 20)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.7), value: animateFields)
                    
                    // User ID (Required for both)
                    CleanTextField(
                        title: "User ID",
                        text: $coordinator.userId,
                        placeholder: "Choose a unique username",
                        icon: "at",
                        keyboardType: .default,
                        isFocused: focusedField == .userId,
                        animationDelay: 0.8,
                        isAnimated: animateFields
                    )
                    .focused($focusedField, equals: .userId)
                    .scaleEffect(animateFields ? 1.0 : 0.95)
                    .opacity(animateFields ? 1.0 : 0.0)
                    .offset(x: animateFields ? 0 : -20)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.8), value: animateFields)
                    
                    // Full Name (Only for Advocates)
                    if coordinator.userType == .advocate {
                        CleanTextField(
                            title: "Full Name",
                            text: $coordinator.fullName,
                            placeholder: "Enter your full legal name",
                            icon: "person",
                            keyboardType: .default,
                            isFocused: focusedField == .fullName,
                            animationDelay: 0.9,
                            isAnimated: animateFields
                        )
                        .focused($focusedField, equals: .fullName)
                        .scaleEffect(animateFields ? 1.0 : 0.95)
                        .opacity(animateFields ? 1.0 : 0.0)
                        .offset(x: animateFields ? 0 : 20)
                        .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.9), value: animateFields)
                    }
                }
                .padding(.horizontal, 24)
                
                // Enhanced security note
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "lock.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text("Secure & encrypted")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .scaleEffect(animateFields ? 1.0 : 0.8)
                .opacity(animateFields ? 1.0 : 0.0)
                .animation(.spring(duration: 0.8, bounce: 0.4).delay(1.0), value: animateFields)
                
                Spacer()
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .onAppear {
            animateFields = true
        }
    }
}



#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BasicInfoView(coordinator: OnboardingCoordinator())
    }
} 