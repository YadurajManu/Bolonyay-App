import SwiftUI

struct LocationInfoView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showStatePicker = false
    @State private var showDistrictPicker = false
    @State private var showEstablishmentPicker = false
    @State private var animateContent = false
    @FocusState private var focusedField: Field?
    
    enum Field: CaseIterable {
        case establishment
    }
    
    private let indianStates = [
        "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
        "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
        "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
        "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
        "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
        "Delhi", "Jammu and Kashmir", "Ladakh"
    ]
    
    private var availableDistricts: [String] {
        // This would typically come from an API based on selected state
        // For demo purposes, showing sample districts
        switch coordinator.enrolledState {
        case "Delhi":
            return ["Central Delhi", "East Delhi", "New Delhi", "North Delhi", "North East Delhi", "North West Delhi", "Shahdara", "South Delhi", "South East Delhi", "South West Delhi", "West Delhi"]
        case "Maharashtra":
            return ["Mumbai City", "Mumbai Suburban", "Pune", "Nagpur", "Thane", "Nashik", "Aurangabad", "Solapur", "Amravati", "Kolhapur"]
        case "Karnataka":
            return ["Bangalore Urban", "Bangalore Rural", "Mysore", "Tumkur", "Belgaum", "Gulbarga", "Dakshina Kannada", "Bellary", "Bijapur", "Shimoga"]
        default:
            return ["District 1", "District 2", "District 3", "District 4", "District 5"]
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Clean description
                VStack(spacing: 12) {
                    Text(localizationManager.text("location_jurisdiction"))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.2), value: animateContent)
                    
                    Text(coordinator.userType == .advocate ? 
                         "Where are you enrolled to practice?" :
                         localizationManager.text("select_preferred_jurisdiction"))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.3), value: animateContent)
                }
                .padding(.top, 24)
                
                // Form Fields - Clean black and white
                VStack(spacing: 16) {
                    // State Picker
                    CleanDropdownField(
                        title: localizationManager.text("enrolled_state"),
                        selectedValue: $coordinator.enrolledState,
                        placeholder: localizationManager.text("select_your_state"),
                        icon: "map",
                        options: indianStates,
                        isExpanded: $showStatePicker,
                        animationDelay: 0.4,
                        isAnimated: animateContent
                    ) {
                        // Reset district when state changes
                        coordinator.enrolledDistrict = ""
                    }
                    
                    // District Picker
                    CleanDropdownField(
                        title: localizationManager.text("enrolled_district"),
                        selectedValue: $coordinator.enrolledDistrict,
                        placeholder: localizationManager.text("select_your_district"),
                        icon: "building.2",
                        options: availableDistricts,
                        isExpanded: $showDistrictPicker,
                        animationDelay: 0.5,
                        isAnimated: animateContent,
                        isDisabled: coordinator.enrolledState.isEmpty
                    )
                    
                    // Establishment (for advocates only)
                    if coordinator.userType == .advocate {
                        CleanTextField(
                            title: "Enrolled Establishment",
                            text: $coordinator.enrolledEstablishment,
                            placeholder: "e.g., High Court, District Court, Supreme Court",
                            icon: "building.columns",
                            keyboardType: UIKeyboardType.default,
                            isFocused: focusedField == .establishment,
                            animationDelay: 0.6,
                            isAnimated: animateContent
                        )
                        .focused($focusedField, equals: .establishment)
                    }
                }
                .padding(.horizontal, 24)
                
                // Security note - minimal design
                HStack(spacing: 8) {
                    Image(systemName: "location.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(coordinator.userType == .advocate ? 
                         "Cases matched by jurisdiction" :
                         localizationManager.text("advocates_suggested_from_area"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.7), value: animateContent)
                
                Spacer()
            }
        }
        .onTapGesture {
            focusedField = nil
            closeAllDropdowns()
        }
        .onAppear {
            animateContent = true
        }
    }
    
    private func closeAllDropdowns() {
        withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
            showStatePicker = false
            showDistrictPicker = false
            showEstablishmentPicker = false
        }
    }
}

struct CleanDropdownField: View {
    let title: String
    @Binding var selectedValue: String
    let placeholder: String
    let icon: String
    let options: [String]
    @Binding var isExpanded: Bool
    let animationDelay: Double
    let isAnimated: Bool
    let isDisabled: Bool
    let onSelectionChange: (() -> Void)?
    
    init(title: String, selectedValue: Binding<String>, placeholder: String, icon: String, options: [String], isExpanded: Binding<Bool>, animationDelay: Double, isAnimated: Bool, isDisabled: Bool = false, onSelectionChange: (() -> Void)? = nil) {
        self.title = title
        self._selectedValue = selectedValue
        self.placeholder = placeholder
        self.icon = icon
        self.options = options
        self._isExpanded = isExpanded
        self.animationDelay = animationDelay
        self.isAnimated = isAnimated
        self.isDisabled = isDisabled
        self.onSelectionChange = onSelectionChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Clean title
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            // Dropdown button
            Button(action: {
                if !isDisabled {
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                        isExpanded.toggle()
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDisabled ? .white.opacity(0.3) : (isExpanded ? .white : .white.opacity(0.6)))
                        .frame(width: 20)
                    
                    Text(selectedValue.isEmpty ? placeholder : selectedValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDisabled ? .white.opacity(0.3) : (selectedValue.isEmpty ? .white.opacity(0.6) : .white))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isDisabled ? .white.opacity(0.3) : .white.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(isDisabled ? 0.02 : (isExpanded ? 0.1 : 0.05)))
                        .stroke(Color.white.opacity(isDisabled ? 0.1 : (isExpanded ? 0.4 : 0.2)), lineWidth: 1)
                )
                .scaleEffect(isExpanded ? 1.02 : 1.0)
                .animation(.spring(duration: 0.3, bounce: 0.2), value: isExpanded)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isDisabled)
            
            // Options list
            if isExpanded && !isDisabled {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                    selectedValue = option
                                    isExpanded = false
                                    onSelectionChange?()
                                }
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    if selectedValue == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedValue == option ? Color.white.opacity(0.1) : Color.white.opacity(0.03))
                                        .stroke(Color.white.opacity(selectedValue == option ? 0.3 : 0.1), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .frame(maxHeight: 200)
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .top)),
                    removal: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .top))
                ))
            }
        }
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(y: isAnimated ? 0 : 20)
        .animation(.spring(duration: 0.6, bounce: 0.4).delay(animationDelay), value: isAnimated)
    }
}



#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LocationInfoView(coordinator: OnboardingCoordinator())
    }
} 