import SwiftUI

struct EmailVoiceAutoFillView: View {
    @StateObject private var voiceManager = SimpleVoiceAutoFillManager()
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // Form fields binding - for email auth
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Simple microphone button
            Button(action: {
                voiceManager.toggleRecording()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: microphoneIcon)
                        .font(.system(size: 20))
                        .foregroundColor(microphoneColor)
                    
                    Text(buttonText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(buttonBackgroundColor)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(voiceManager.recordingState == .processing)
            
            // Status indicator
            statusIndicator
            
            // Auto-fill button (when data is available)
            if let data = voiceManager.extractedData, data.hasData {
                autoFillButton(data: data)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicator: some View {
        Group {
            switch voiceManager.recordingState {
            case .idle:
                Text("आवाज़ से फॉर्म भरने के लिए टैप करें")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
            case .recording:
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                        .scaleEffect(recordingPulse ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: recordingPulse)
                        .onAppear { recordingPulse = true }
                        .onDisappear { recordingPulse = false }
                    
                    Text("रिकॉर्डिंग हो रही है...")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
            case .processing:
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("प्रोसेसिंग...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
            case .completed:
                Text("✅ डेटा तैयार है")
                    .font(.caption)
                    .foregroundColor(.green)
                
            case .error:
                if let error = voiceManager.errorMessage {
                    Text("❌ \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // MARK: - Auto-Fill Button
    
    private func autoFillButton(data: SimpleFormData) -> some View {
        Button(action: {
            fillFormWithData(data)
        }) {
            HStack {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14))
                
                Text("फॉर्म भरें")
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(6)
        }
    }
    
    // MARK: - Helper Properties
    
    private var microphoneIcon: String {
        switch voiceManager.recordingState {
        case .recording:
            return "mic.fill"
        case .processing:
            return "waveform"
        default:
            return "mic"
        }
    }
    
    private var microphoneColor: Color {
        switch voiceManager.recordingState {
        case .recording:
            return .red
        case .processing:
            return .blue
        default:
            return .white
        }
    }
    
    private var buttonText: String {
        switch voiceManager.recordingState {
        case .idle:
            return "आवाज़ से भरें"
        case .recording:
            return "रुकने के लिए टैप करें"
        case .processing:
            return "प्रोसेसिंग..."
        case .completed:
            return "पूरा हुआ"
        case .error:
            return "दोबारा कोशिश करें"
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch voiceManager.recordingState {
        case .recording:
            return Color.red.opacity(0.2)
        case .processing:
            return Color.blue.opacity(0.2)
        default:
            return Color.white.opacity(0.1)
        }
    }
    
    @State private var recordingPulse = false
    
    // MARK: - Helper Functions
    
    private func fillFormWithData(_ data: SimpleFormData) {
        if let extractedName = data.name, !extractedName.isEmpty {
            name = extractedName
        }
        
        if let extractedEmail = data.email, !extractedEmail.isEmpty {
            email = extractedEmail
        }
        
        if let extractedPhone = data.phone, !extractedPhone.isEmpty {
            phone = extractedPhone
        }
        
        // Reset voice manager
        voiceManager.reset()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Preview

struct EmailVoiceAutoFillView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            EmailVoiceAutoFillView(
                name: .constant(""),
                email: .constant(""),
                phone: .constant("")
            )
            .environmentObject(LocalizationManager())
            .padding()
        }
    }
} 