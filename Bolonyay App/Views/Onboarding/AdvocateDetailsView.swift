import SwiftUI

struct AdvocateDetailsView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @FocusState private var focusedField: Field?
    @State private var animateFields = false
    
    enum Field: CaseIterable {
        case barRegistration, yearsOfExperience
    }
    
    private let specializationOptions = [
        "Criminal Law", "Civil Law", "Corporate Law", "Family Law",
        "Property Law", "Constitutional Law", "Tax Law", "Labour Law",
        "Intellectual Property", "Environmental Law", "Consumer Law", "Other"
    ]
    
    @State private var showSpecializationPicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Enhanced animated header
                VStack(spacing: 20) {
                    // Animated title
                    VStack(spacing: 8) {
                        Text("Professional Credentials")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .opacity(animateFields ? 1.0 : 0.0)
                            .offset(y: animateFields ? 0 : 30)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.1), value: animateFields)
                        
                        Text("Please provide your legal practice details")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .opacity(animateFields ? 1.0 : 0.0)
                            .offset(y: animateFields ? 0 : 20)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: animateFields)
                    }
                    
                    // Enhanced Professional Badge with animations
                    VStack(spacing: 16) {
                        ZStack {
                            // Outer glow effect
                            Circle()
                                .fill(Color.white.opacity(0.03))
                                .frame(width: 100, height: 100)
                                .scaleEffect(animateFields ? 1.0 : 0.5)
                                .opacity(animateFields ? 1.0 : 0.0)
                                .animation(.spring(duration: 1.0, bounce: 0.4).delay(0.3), value: animateFields)
                            
                            // Main circle
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 80, height: 80)
                                .scaleEffect(animateFields ? 1.0 : 0.3)
                                .opacity(animateFields ? 1.0 : 0.0)
                                .animation(.spring(duration: 0.9, bounce: 0.5).delay(0.4), value: animateFields)
                            
                            // Icon with enhanced animation
                            Image(systemName: "briefcase.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                                .scaleEffect(animateFields ? 1.0 : 0.2)
                                .opacity(animateFields ? 1.0 : 0.0)
                                .rotationEffect(.degrees(animateFields ? 0 : 180))
                                .animation(.spring(duration: 1.0, bounce: 0.6).delay(0.5), value: animateFields)
                        }
                        
                        Text("Legal Professional")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(animateFields ? 1.0 : 0.0)
                            .offset(y: animateFields ? 0 : 15)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.6), value: animateFields)
                    }
                }
                .padding(.top, 16)
                
                // Enhanced Form Fields with staggered animations
                VStack(spacing: 24) {
                    // Bar Registration Number
                    CleanTextField(
                        title: "Bar Registration Number",
                        text: $coordinator.barRegistrationNumber,
                        placeholder: "Enter your bar council registration number",
                        icon: "doc.text.fill",
                        keyboardType: .default,
                        isFocused: focusedField == .barRegistration,
                        animationDelay: 0.7,
                        isAnimated: animateFields
                    )
                    .focused($focusedField, equals: .barRegistration)
                    .scaleEffect(animateFields ? 1.0 : 0.95)
                    .opacity(animateFields ? 1.0 : 0.0)
                    .offset(x: animateFields ? 0 : -30)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.7), value: animateFields)
                    
                    // Years of Experience
                    CleanTextField(
                        title: "Years of Experience",
                        text: $coordinator.yearsOfExperience,
                        placeholder: "e.g., 5 years",
                        icon: "calendar.badge.clock",
                        keyboardType: .numberPad,
                        isFocused: focusedField == .yearsOfExperience,
                        animationDelay: 0.8,
                        isAnimated: animateFields
                    )
                    .focused($focusedField, equals: .yearsOfExperience)
                    .scaleEffect(animateFields ? 1.0 : 0.95)
                    .opacity(animateFields ? 1.0 : 0.0)
                    .offset(x: animateFields ? 0 : 30)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.8), value: animateFields)
                    
                    // Enhanced Specialization Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Area of Specialization")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Button(action: {
                            withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                showSpecializationPicker.toggle()
                                focusedField = nil
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "scale.3d")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(showSpecializationPicker ? .white : .gray)
                                    .frame(width: 20)
                                
                                Text(coordinator.specialization.isEmpty ? "Select your specialization" : coordinator.specialization)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(coordinator.specialization.isEmpty ? .gray : .white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                    .rotationEffect(.degrees(showSpecializationPicker ? 180 : 0))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(showSpecializationPicker ? 0.08 : 0.04))
                                    .stroke(
                                        showSpecializationPicker ? Color.white.opacity(0.5) : Color.gray.opacity(0.2),
                                        lineWidth: showSpecializationPicker ? 2 : 1
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Enhanced Specialization Options with animations
                        if showSpecializationPicker {
                            VStack(spacing: 10) {
                                ForEach(Array(specializationOptions.enumerated()), id: \.element) { index, option in
                                    Button(action: {
                                        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                            coordinator.specialization = option
                                            showSpecializationPicker = false
                                        }
                                    }) {
                                        HStack {
                                            Text(option)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            if coordinator.specialization == option {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(coordinator.specialization == option ? Color.white.opacity(0.1) : Color.white.opacity(0.02))
                                                .stroke(coordinator.specialization == option ? Color.white.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .opacity(showSpecializationPicker ? 1.0 : 0.0)
                                    .offset(y: showSpecializationPicker ? 0 : -10)
                                    .animation(.spring(duration: 0.5, bounce: 0.3).delay(Double(index) * 0.05), value: showSpecializationPicker)
                                }
                            }
                            .padding(.top, 12)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .top)),
                                removal: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .top))
                            ))
                        }
                    }
                    .scaleEffect(animateFields ? 1.0 : 0.95)
                    .opacity(animateFields ? 1.0 : 0.0)
                    .offset(y: animateFields ? 0 : 20)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.9), value: animateFields)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 32)
                
                // Enhanced Professional Note with animation
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Professional Verification")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Your credentials will be verified by our team")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.04))
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .scaleEffect(animateFields ? 1.0 : 0.9)
                .opacity(animateFields ? 1.0 : 0.0)
                .offset(y: animateFields ? 0 : 30)
                .animation(.spring(duration: 0.8, bounce: 0.3).delay(1.1), value: animateFields)
                
                Spacer()
            }
        }
        .onTapGesture {
            focusedField = nil
            if showSpecializationPicker {
                withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                    showSpecializationPicker = false
                }
            }
        }
        .onAppear {
            animateFields = true
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AdvocateDetailsView(coordinator: OnboardingCoordinator())
    }
} 