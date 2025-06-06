import SwiftUI

struct CleanTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    let keyboardType: UIKeyboardType
    let isFocused: Bool
    let animationDelay: Double
    let isAnimated: Bool
    let isSecure: Bool
    
    @State private var isSecureTextVisible = false
    
    init(title: String, text: Binding<String>, placeholder: String, icon: String, 
         keyboardType: UIKeyboardType = .default, isFocused: Bool = false, 
         animationDelay: Double = 0.0, isAnimated: Bool = true, isSecure: Bool = false) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.keyboardType = keyboardType
        self.isFocused = isFocused
        self.animationDelay = animationDelay
        self.isAnimated = isAnimated
        self.isSecure = isSecure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Clean title
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            // Minimal text field
            HStack(spacing: 12) {
                // Simple icon
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