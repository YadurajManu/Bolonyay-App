import SwiftUI

enum OnboardingStep: CaseIterable {
    case userType
    case basicInfo
    case advocateDetails // Only for advocates
    case locationInfo
    case completion
    
    func title(localizationManager: LocalizationManager) -> String {
        switch self {
        case .userType: return localizationManager.text("choose_your_role")
        case .basicInfo: return localizationManager.text("basic_information")
        case .advocateDetails: return localizationManager.text("professional_details")
        case .locationInfo: return localizationManager.text("location_jurisdiction")
        case .completion: return localizationManager.text("welcome_bolonyay")
        }
    }
    
    var title: String {
        switch self {
        case .userType: return "Choose Your Role"
        case .basicInfo: return "Basic Information"
        case .advocateDetails: return "Professional Details"
        case .locationInfo: return "Location & Jurisdiction"
        case .completion: return "Welcome to BoloNyay"
        }
    }
}

class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .userType
    @Published var userType: UserType = .petitioner
    @Published var isOnboardingComplete = false
    
    // User data
    @Published var mobileNumber = ""
    @Published var email = ""
    @Published var userId = ""
    @Published var fullName = ""
    
    // Advocate specific
    @Published var barRegistrationNumber = ""
    @Published var enrolledState = ""
    @Published var enrolledDistrict = ""
    @Published var enrolledEstablishment = ""
    @Published var yearsOfExperience = ""
    @Published var specialization = ""
    
    var totalSteps: Int {
        return userType == .advocate ? 5 : 4
    }
    
    var currentStepNumber: Int {
        switch currentStep {
        case .userType: return 1
        case .basicInfo: return 2
        case .advocateDetails: return 3
        case .locationInfo: return userType == .advocate ? 4 : 3
        case .completion: return totalSteps
        }
    }
    
    func nextStep() {
        switch currentStep {
        case .userType:
            currentStep = .basicInfo
        case .basicInfo:
            if userType == .advocate {
                currentStep = .advocateDetails
            } else {
                currentStep = .locationInfo
            }
        case .advocateDetails:
            currentStep = .locationInfo
        case .locationInfo:
            currentStep = .completion
        case .completion:
            isOnboardingComplete = true
        }
    }
    
    func previousStep() {
        switch currentStep {
        case .userType:
            break
        case .basicInfo:
            currentStep = .userType
        case .advocateDetails:
            currentStep = .basicInfo
        case .locationInfo:
            if userType == .advocate {
                currentStep = .advocateDetails
            } else {
                currentStep = .basicInfo
            }
        case .completion:
            currentStep = .locationInfo
        }
    }
    
    func canProceed() -> Bool {
        switch currentStep {
        case .userType:
            return true
        case .basicInfo:
            if userType == .petitioner {
                // Simplified requirements for petitioners: Mobile, Email, User ID only
                return !mobileNumber.isEmpty && !email.isEmpty && !userId.isEmpty
            } else {
                // Full requirements for advocates
                return !mobileNumber.isEmpty && !email.isEmpty && !fullName.isEmpty
            }
        case .advocateDetails:
            return !barRegistrationNumber.isEmpty && !specialization.isEmpty
        case .locationInfo:
            return !enrolledState.isEmpty && !enrolledDistrict.isEmpty
        case .completion:
            return true
        }
    }
    
    func reset() {
        // Reset onboarding state
        currentStep = .userType
        isOnboardingComplete = false
        
        // Reset user data
        mobileNumber = ""
        email = ""
        userId = ""
        fullName = ""
        
        // Reset advocate specific data
        barRegistrationNumber = ""
        enrolledState = ""
        enrolledDistrict = ""
        enrolledEstablishment = ""
        yearsOfExperience = ""
        specialization = ""
        
        // Reset user type to default
        userType = .petitioner
    }
} 