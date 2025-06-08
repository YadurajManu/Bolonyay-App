import SwiftUI

struct OnboardingView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @StateObject private var authManager = AuthenticationManager()
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    init(coordinator: OnboardingCoordinator? = nil) {
        self.coordinator = coordinator ?? OnboardingCoordinator()
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Header
                OnboardingProgressHeader(
                    currentStep: coordinator.currentStepNumber,
                    totalSteps: coordinator.totalSteps,
                    title: coordinator.currentStep.title(localizationManager: localizationManager)
                )
                
                // Content
                TabView(selection: $coordinator.currentStep) {
                    UserTypeSelectionView(coordinator: coordinator)
                        .environmentObject(localizationManager)
                        .tag(OnboardingStep.userType)
                    
                    BasicInfoView(coordinator: coordinator)
                        .environmentObject(localizationManager)
                        .tag(OnboardingStep.basicInfo)
                    
                    if coordinator.userType == .advocate {
                        AdvocateDetailsView(coordinator: coordinator)
                            .environmentObject(localizationManager)
                            .tag(OnboardingStep.advocateDetails)
                    }
                    
                    LocationInfoView(coordinator: coordinator)
                        .environmentObject(localizationManager)
                        .tag(OnboardingStep.locationInfo)
                    
                    CompletionView(coordinator: coordinator)
                        .environmentObject(localizationManager)
                        .tag(OnboardingStep.completion)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: coordinator.currentStep)
                
                // Navigation Footer
                OnboardingNavigationFooter(coordinator: coordinator)
                    .environmentObject(localizationManager)
            }
        }
        .onChange(of: coordinator.isOnboardingComplete) { isComplete in
            if isComplete {
                Task {
                    await authManager.completeOnboarding(coordinator: coordinator)
                }
            }
        }
    }
}

// MARK: - Progress Header
struct OnboardingProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let title: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Modern Progress Bar
            HStack(spacing: 4) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.white : Color.white.opacity(0.2))
                        .frame(height: 3)
                        .scaleEffect(y: step <= currentStep ? 1.0 : 0.7)
                        .animation(.spring(duration: 0.6, bounce: 0.3), value: currentStep)
                }
            }
            .padding(.horizontal, 32)
            
            // Title with fluid animation
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(1.0)
                .scaleEffect(1.0)
                .animation(.spring(duration: 0.5, bounce: 0.2), value: title)
            
            // Minimal step indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                
                Text("\(currentStep) of \(totalSteps)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - Navigation Footer
struct OnboardingNavigationFooter: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Continue Button - Clean black and white
            Button(action: {
                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                    coordinator.nextStep()
                }
            }) {
                HStack(spacing: 8) {
                    Text(coordinator.currentStep == .completion ? localizationManager.text("get_started") : localizationManager.text("continue"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    if coordinator.currentStep != .completion {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                            .scaleEffect(coordinator.canProceed() ? 1.0 : 0.8)
                            .animation(.spring(duration: 0.4, bounce: 0.5), value: coordinator.canProceed())
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(coordinator.canProceed() ? Color.white : Color.white.opacity(0.3))
                        .scaleEffect(coordinator.canProceed() ? 1.0 : 0.98)
                        .animation(.spring(duration: 0.4, bounce: 0.3), value: coordinator.canProceed())
                )
                .shadow(color: coordinator.canProceed() ? .white.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!coordinator.canProceed())
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 32)
            
            // Back Button - Minimal design
            if coordinator.currentStep != .userType {
                Button(action: {
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                        coordinator.previousStep()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(localizationManager.text("back"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.bottom, 32)
    }
}

#Preview {
    OnboardingView()
} 