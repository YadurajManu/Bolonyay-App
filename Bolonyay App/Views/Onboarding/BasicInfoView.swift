import SwiftUI

struct BasicInfoView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var localizationManager: LocalizationManager
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
                        Text(coordinator.userType == .petitioner ? localizationManager.text("basic_information") : localizationManager.text("your_details"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(animateFields ? 1.0 : 0.0)
                            .offset(y: animateFields ? 0 : 30)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.3), value: animateFields)
                        
                        Text(coordinator.userType == .petitioner ? 
                             localizationManager.text("just_essentials") :
                             localizationManager.text("complete_professional"))
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
                    VoiceEnabledTextField(
                        title: localizationManager.text("mobile_number"),
                        text: $coordinator.mobileNumber,
                        placeholder: localizationManager.text("mobile_placeholder"),
                        icon: "phone",
                        keyboardType: .phonePad,
                        isFocused: focusedField == .mobile,
                        animationDelay: 0.6,
                        isAnimated: animateFields,
                        voiceFieldType: .phone
                    )
                    .focused($focusedField, equals: .mobile)
                    .scaleEffect(animateFields ? 1.0 : 0.95)
                    .opacity(animateFields ? 1.0 : 0.0)
                    .offset(x: animateFields ? 0 : -20)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.6), value: animateFields)
                    
                    // Email (Required for both)
                    VoiceEnabledTextField(
                        title: localizationManager.text("email_id"),
                        text: $coordinator.email,
                        placeholder: localizationManager.text("email_placeholder"),
                        icon: "envelope",
                        keyboardType: .emailAddress,
                        isFocused: focusedField == .email,
                        animationDelay: 0.7,
                        isAnimated: animateFields,
                        voiceFieldType: .email
                    )
                    .focused($focusedField, equals: .email)
                    .scaleEffect(animateFields ? 1.0 : 0.95)
                    .opacity(animateFields ? 1.0 : 0.0)
                    .offset(x: animateFields ? 0 : 20)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.7), value: animateFields)
                    
                    // User ID (Required for both)
                    CleanTextField(
                        title: localizationManager.text("user_id"),
                        text: $coordinator.userId,
                        placeholder: localizationManager.text("user_id_placeholder"),
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
                        VoiceEnabledTextField(
                            title: localizationManager.text("full_name"),
                            text: $coordinator.fullName,
                            placeholder: localizationManager.text("full_name_placeholder"),
                            icon: "person",
                            keyboardType: .default,
                            isFocused: focusedField == .fullName,
                            animationDelay: 0.9,
                            isAnimated: animateFields,
                            voiceFieldType: .name
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
                    
                    Text(localizationManager.text("secure_encrypted"))
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