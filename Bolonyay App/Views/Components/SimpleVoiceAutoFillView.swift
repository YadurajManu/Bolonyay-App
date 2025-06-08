import SwiftUI

struct SimpleVoiceAutoFillView: View {
    @StateObject private var voiceManager = SimpleVoiceAutoFillManager()
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // Form fields binding
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Voice recording button
            voiceRecordingButton
            
            // Status text
            statusText
            
            // Auto-fill button (when data is available)
            if let data = voiceManager.extractedData, data.hasData {
                autoFillButton(data: data)
            }
            
            // Error message
            if let error = voiceManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Voice Recording Button
    
    private var voiceRecordingButton: some View {
        Button(action: {
            voiceManager.toggleRecording()
        }) {
            HStack {
                Image(systemName: microphoneIcon)
                    .foregroundColor(microphoneColor)
                    .font(.title2)
                
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(buttonBackgroundColor)
            .cornerRadius(8)
        }
        .disabled(voiceManager.recordingState == .processing)
    }
    
    // MARK: - Status Text
    
    private var statusText: some View {
        Group {
            switch voiceManager.recordingState {
            case .idle:
                Text(localizationManager.localizedString(for: "voice_auto_fill_instruction"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
            case .recording:
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(recordingPulse ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: recordingPulse)
                        .onAppear { recordingPulse = true }
                        .onDisappear { recordingPulse = false }
                    
                    Text("रिकॉर्डिंग चल रही है... फिर से टैप करें")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
            case .processing:
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("प्रोसेसिंग हो रही है...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
            case .completed:
                Text("✅ डेटा निकाला गया")
                    .font(.caption)
                    .foregroundColor(.green)
                
            case .error:
                Text("❌ कुछ गलत हुआ")
                    .font(.caption)
                    .foregroundColor(.red)
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
                Text("फॉर्म भरें")
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
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
            return .blue
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
            return Color.red.opacity(0.1)
        case .processing:
            return Color.blue.opacity(0.1)
        default:
            return Color.blue.opacity(0.1)
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
        
        // Show success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Preview

struct SimpleVoiceAutoFillView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleVoiceAutoFillView(
            name: .constant(""),
            email: .constant(""),
            phone: .constant("")
        )
        .environmentObject(LocalizationManager())
        .padding()
    }
} 