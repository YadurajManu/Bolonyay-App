import SwiftUI

struct VoiceEnabledTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    let keyboardType: UIKeyboardType
    let isFocused: Bool
    let animationDelay: Double
    let isAnimated: Bool
    let isSecure: Bool
    let voiceFieldType: IndividualVoiceInputView.VoiceFieldType?
    
    @State private var isSecureTextVisible = false
    
    init(title: String, text: Binding<String>, placeholder: String, icon: String, 
         keyboardType: UIKeyboardType = .default, isFocused: Bool = false, 
         animationDelay: Double = 0.0, isAnimated: Bool = true, isSecure: Bool = false,
         voiceFieldType: IndividualVoiceInputView.VoiceFieldType? = nil) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.keyboardType = keyboardType
        self.isFocused = isFocused
        self.animationDelay = animationDelay
        self.isAnimated = isAnimated
        self.isSecure = isSecure
        self.voiceFieldType = voiceFieldType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title with voice indicator
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                if voiceFieldType != nil {
                    Image(systemName: "mic.badge.plus")
                        .font(.system(size: 12))
                        .foregroundColor(.blue.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Text field with voice input
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isFocused ? .white : .white.opacity(0.6))
                    .frame(width: 20)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                // Text field
                if isSecure && !isSecureTextVisible {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .tint(.white)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .keyboardType(keyboardType)
                        .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                        .disableAutocorrection(keyboardType == .emailAddress)
                        .tint(.white)
                }
                
                // Voice input button (if enabled)
                if let voiceType = voiceFieldType {
                    if isSecure {
                        // Special password voice input
                        PasswordVoiceInputView(
                            passwordValue: $text
                        )
                    } else {
                        // Regular field voice input
                        IndividualVoiceInputView(
                            fieldValue: $text,
                            fieldType: voiceType,
                            placeholder: placeholder
                        )
                    }
                }
                
                // Password visibility toggle
                if isSecure {
                    Button(action: {
                        isSecureTextVisible.toggle()
                    }) {
                        Image(systemName: isSecureTextVisible ? "eye.slash" : "eye")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
                    .stroke(Color.white.opacity(isFocused ? 0.4 : 0.2), lineWidth: 1)
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.2), value: isFocused)
        }
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(y: isAnimated ? 0 : 20)
        .animation(.spring(duration: 0.6, bounce: 0.4).delay(animationDelay), value: isAnimated)
    }
}

// MARK: - Preview

struct VoiceEnabledTextField_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                VoiceEnabledTextField(
                    title: "पूरा नाम",
                    text: .constant(""),
                    placeholder: "अपना पूरा नाम दर्ज करें",
                    icon: "person",
                    voiceFieldType: .name
                )
                
                VoiceEnabledTextField(
                    title: "मोबाइल नंबर",
                    text: .constant(""),
                    placeholder: "+91 98765 43210",
                    icon: "phone",
                    keyboardType: .phonePad,
                    voiceFieldType: .phone
                )
                
                VoiceEnabledTextField(
                    title: "ईमेल पता",
                    text: .constant(""),
                    placeholder: "ram@gmail.com",
                    icon: "envelope",
                    keyboardType: .emailAddress,
                    voiceFieldType: .email
                )
                
                VoiceEnabledTextField(
                    title: "पासवर्ड",
                    text: .constant(""),
                    placeholder: "अपना पासवर्ड दर्ज करें",
                    icon: "lock",
                    isSecure: true
                )
            }
            .padding()
        }
        .environmentObject(LocalizationManager())
    }
} 