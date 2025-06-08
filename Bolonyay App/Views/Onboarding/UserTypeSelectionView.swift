import SwiftUI

struct UserTypeSelectionView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var animateCards = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Clean description
                VStack(spacing: 12) {
                    Text(localizationManager.text("choose_your_role"))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .offset(y: animateCards ? 0 : 20)
                        .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.2), value: animateCards)
                    
                    Text(localizationManager.text("select_how_use"))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(animateCards ? 1.0 : 0.0)
                        .offset(y: animateCards ? 0 : 20)
                        .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.3), value: animateCards)
                }
                .padding(.top, 24)
                
                // User Type Cards - Clean black and white
                VStack(spacing: 16) {
                    // Petitioner Card
                    CleanUserTypeCard(
                        userType: .petitioner,
                        isSelected: coordinator.userType == .petitioner,
                        animationDelay: 0.4,
                        isAnimated: animateCards,
                        localizationManager: localizationManager,
                        onTap: {
                            withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                                coordinator.userType = .petitioner
                            }
                        }
                    )
                    
                    // Advocate Card
                    CleanUserTypeCard(
                        userType: .advocate,
                        isSelected: coordinator.userType == .advocate,
                        animationDelay: 0.5,
                        isAnimated: animateCards,
                        localizationManager: localizationManager,
                        onTap: {
                            withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                                coordinator.userType = .advocate
                            }
                        }
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .onAppear {
            animateCards = true
        }
    }
}

struct CleanUserTypeCard: View {
    let userType: UserType
    let isSelected: Bool
    let animationDelay: Double
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Simple icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: userType.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .black : .white)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(duration: 0.4, bounce: 0.5), value: isSelected)
                
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(userType.localizedTitle(localizationManager: localizationManager))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(userType.localizedDescription(localizationManager: localizationManager))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                }
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .scaleEffect(isSelected ? 1.0 : 0.0)
                            .animation(.spring(duration: 0.4, bounce: 0.6), value: isSelected)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                    .stroke(Color.white.opacity(isSelected ? 0.3 : 0.1), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? .white.opacity(0.1) : .clear, radius: isSelected ? 12 : 0)
            .animation(.spring(duration: 0.5, bounce: 0.3), value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(y: isAnimated ? 0 : 30)
        .animation(.spring(duration: 0.6, bounce: 0.4).delay(animationDelay), value: isAnimated)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        UserTypeSelectionView(coordinator: OnboardingCoordinator())
    }
} 