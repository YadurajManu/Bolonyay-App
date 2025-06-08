import SwiftUI
import AVFoundation

struct LanguageDetectionView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var isListening = false
    @State private var isDetecting = false
    @State private var showLanguageDetected = false
    @State private var animationPhase = 0
    @State private var micScale: CGFloat = 1.0
    @State private var pulseAnimation = false
    @State private var showError = false
    @State private var errorText = ""
    @State private var detectionProgress = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Text(localizationManager.text("welcome"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(showLanguageDetected ? 0 : 1)
                    
                    Text(localizationManager.text("speak_to_detect_language"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .opacity(showLanguageDetected ? 0 : 1)
                    
                    // Azure OpenAI Integration Badge
                    if !showLanguageDetected && !showError {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text("Powered by Azure OpenAI + Bhashini AI")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue.opacity(0.8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                        .opacity(showLanguageDetected ? 0 : 1)
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: showLanguageDetected)
                
                // Language Detection Result
                if showLanguageDetected {
                    VStack(spacing: 16) {
                        Text(localizationManager.text("language_detected"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                        
                        Text(localizationManager.getCurrentLanguageName())
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .stroke(Color.green, lineWidth: 2)
                            )
                        
                        // Success badge
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Verified by Azure OpenAI")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green.opacity(0.8))
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Error Display
                if showError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                        
                        Text("Detection Failed")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.red)
                        
                        Text(errorText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button(action: resetDetection) {
                            Text("Try Again")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.red.opacity(0.2))
                                        .stroke(Color.red, lineWidth: 2)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Detection Progress
                if isDetecting && !detectionProgress.isEmpty {
                    VStack(spacing: 12) {
                        Text(detectionProgress)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                        
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    }
                    .transition(.opacity)
                }
                
                Spacer()
                
                // Microphone Interface
                VStack(spacing: 30) {
                    // Mic Button
                    Button(action: toggleListening) {
                        ZStack {
                            // Pulse rings
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 120 + CGFloat(index * 30), height: 120 + CGFloat(index * 30))
                                    .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                                    .opacity(pulseAnimation ? 0 : 0.6)
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(index) * 0.2),
                                        value: pulseAnimation
                                    )
                            }
                            
                            // Main mic circle
                            Circle()
                                .fill(isListening ? Color.red : Color.white.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                            
                            // Mic icon
                            Image(systemName: isListening ? "mic.fill" : "mic")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(isListening ? .white : .white.opacity(0.8))
                                .scaleEffect(micScale)
                        }
                    }
                    .scaleEffect(isListening ? 1.1 : 1.0)
                    .animation(.spring(duration: 0.3, bounce: 0.3), value: isListening)
                    .disabled(isDetecting)
                    
                    // Status Text
                    Group {
                        if isDetecting {
                            Text(localizationManager.text("detecting_language"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.orange)
                        } else if isListening {
                            Text(localizationManager.text("speak_now"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        } else if !showLanguageDetected {
                            Text(localizationManager.text("tap_microphone_to_start"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: isListening)
                    .animation(.easeInOut(duration: 0.3), value: isDetecting)
                }
                
                Spacer()
                
                // Action Buttons
                if showLanguageDetected {
                    HStack(spacing: 20) {
                        Button(action: resetDetection) {
                            Text(localizationManager.text("try_again"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: proceedWithDetectedLanguage) {
                            Text(localizationManager.text("continue"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 40)
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            startPulseAnimation()
            
            // Listen for language detection errors
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("LanguageDetectionError"),
                object: nil,
                queue: .main
            ) { notification in
                if let error = notification.object as? String {
                    showErrorState(error)
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // MARK: - Actions
    
    private func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    private func startListening() {
        isListening = true
        micScale = 1.2
        
        // Start the detection process after 3 seconds (recording duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            stopListening()
            startDetection()
        }
    }
    
    private func stopListening() {
        isListening = false
        micScale = 1.0
    }
    
    private func startDetection() {
        isDetecting = true
        detectionProgress = "🎤 Processing voice recording..."
        
        // Update progress messages
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            detectionProgress = "📝 Transcribing with Bhashini AI..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            detectionProgress = "🧠 Analyzing with Azure OpenAI..."
        }
        
        Task {
            await localizationManager.detectLanguageFromSpeech()
            
            DispatchQueue.main.async {
                isDetecting = false
                detectionProgress = ""
                
                if localizationManager.isLanguageDetected {
                    showSuccessState()
                }
            }
        }
    }
    
    private func showSuccessState() {
        withAnimation(.spring(duration: 0.6, bounce: 0.4)) {
            showLanguageDetected = true
        }
    }
    
    private func showErrorState(_ error: String) {
        errorText = error
        isDetecting = false
        detectionProgress = ""
        
        withAnimation(.spring(duration: 0.6, bounce: 0.4)) {
            showError = true
        }
    }
    
    private func resetDetection() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showLanguageDetected = false
            showError = false
            errorText = ""
            detectionProgress = ""
        }
        
        localizationManager.clearSavedLanguagePreference()
    }
    
    private func proceedWithDetectedLanguage() {
        coordinator.startLogin()
    }
    
    private func startPulseAnimation() {
        pulseAnimation = true
    }
}

// Note: ScaleButtonStyle is defined in LoginView.swift

#Preview {
    LanguageDetectionView()
        .environmentObject(LocalizationManager())
        .environmentObject(AppCoordinator())
} 