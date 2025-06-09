import SwiftUI
import AVFoundation

struct LocationInfoView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var voiceLocationManager = VoiceLocationManager()
    @State private var animateContent = false
    @FocusState private var focusedField: Field?
    
    enum Field: CaseIterable {
        case establishment
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
                         "Speak your location details" :
                         localizationManager.text("speak_your_preferred_jurisdiction"))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.3), value: animateContent)
                }
                .padding(.top, 24)
                
                // Voice Location Input
                VoiceLocationInputView(
                    state: $coordinator.enrolledState,
                    district: $coordinator.enrolledDistrict,
                    animationDelay: 0.4,
                    isAnimated: animateContent
                )
                .padding(.horizontal, 24)
                
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
                    .padding(.horizontal, 24)
                }
                
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
        }
        .onAppear {
            animateContent = true
        }
    }
}

// MARK: - Voice Location Input Component

struct VoiceLocationInputView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var voiceManager = VoiceLocationManager()
    @Binding var state: String
    @Binding var district: String
    let animationDelay: Double
    let isAnimated: Bool
    @State private var recordingPulse = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Location Input Title
            VStack(spacing: 8) {
                Text(localizationManager.currentLanguage == "hindi" ? "अपना स्थान बताएं" : "Speak Your Location")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(localizationManager.currentLanguage == "hindi" ? "राज्य और जिले का नाम बोलें" : "Say your state and district name")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Voice Recording Button
            Button(action: {
                voiceManager.toggleRecording()
            }) {
                VStack(spacing: 12) {
                    ZStack {
                        // Pulse rings during recording
                        if voiceManager.recordingState == .recording {
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(Color.blue.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                                    .frame(width: 80 + CGFloat(index * 20), height: 80 + CGFloat(index * 20))
                                    .scaleEffect(recordingPulse ? 1.2 : 0.8)
                                    .opacity(recordingPulse ? 0.6 : 0)
                                    .animation(
                                        .easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(index) * 0.2),
                                        value: recordingPulse
                                    )
                            }
                        }
                        
                        // Main button
                        Circle()
                            .fill(buttonBackgroundColor)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Icon
                        Image(systemName: microphoneIcon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(microphoneColor)
                    }
                    
                    // Status text
                    statusText
                }
            }
            .disabled(voiceManager.recordingState == .processing)
            .scaleEffect(voiceManager.recordingState == .recording ? 1.1 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: voiceManager.recordingState)
            
            // Display extracted location
            if !state.isEmpty || !district.isEmpty {
                locationDisplay
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(y: isAnimated ? 0 : 30)
        .animation(.spring(duration: 0.6, bounce: 0.4).delay(animationDelay), value: isAnimated)
        .onChange(of: voiceManager.extractedState) { oldValue, newValue in
            if let newState = newValue, !newState.isEmpty {
                state = newState
            }
        }
        .onChange(of: voiceManager.extractedDistrict) { oldValue, newValue in
            if let newDistrict = newValue, !newDistrict.isEmpty {
                district = newDistrict
            }
        }
        .onChange(of: voiceManager.recordingState) { oldValue, newValue in
            if newValue == .recording {
                recordingPulse = true
            } else {
                recordingPulse = false
            }
        }
    }
    
    private var statusText: some View {
        Group {
            switch voiceManager.recordingState {
            case .idle:
                Text(localizationManager.currentLanguage == "hindi" ? "स्थान बताएं" : "Speak your location")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
            case .recording:
                Text(localizationManager.currentLanguage == "hindi" ? "सुन रहा हूं..." : "Listening...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                
            case .processing:
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text(localizationManager.currentLanguage == "hindi" ? "प्रोसेसिंग..." : "Processing...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                
            case .completed:
                Text(localizationManager.currentLanguage == "hindi" ? "✅ स्थान मिल गया" : "✅ Location found")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                
            case .error:
                Text(localizationManager.currentLanguage == "hindi" ? "❌ दोबारा कोशिश करें" : "❌ Try again")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
            }
        }
    }
    
    private var locationDisplay: some View {
        VStack(spacing: 12) {
            if !state.isEmpty {
                HStack {
                    Image(systemName: "map")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    Text(localizationManager.currentLanguage == "hindi" ? "राज्य:" : "State:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(state)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
            
            if !district.isEmpty {
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    Text(localizationManager.currentLanguage == "hindi" ? "जिला:" : "District:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(district)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var microphoneIcon: String {
        switch voiceManager.recordingState {
        case .recording:
            return "mic.fill"
        case .processing:
            return "waveform"
        case .completed:
            return "checkmark.circle.fill"
        case .error:
            return "mic.slash"
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
        case .completed:
            return .green
        case .error:
            return .red
        default:
            return .white
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch voiceManager.recordingState {
        case .recording:
            return Color.red.opacity(0.2)
        case .processing:
            return Color.blue.opacity(0.2)
        case .completed:
            return Color.green.opacity(0.2)
        case .error:
            return Color.red.opacity(0.2)
        default:
            return Color.white.opacity(0.1)
        }
    }
}

// MARK: - Voice Location Manager

@MainActor
class VoiceLocationManager: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var extractedState: String?
    @Published var extractedDistrict: String?
    @Published var errorMessage: String?
    
    private let azureOpenAIManager = AzureOpenAIManager()
    private var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession?
    
    enum RecordingState {
        case idle
        case recording
        case processing
        case completed
        case error
    }
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    func toggleRecording() {
        Task {
            switch recordingState {
            case .idle:
                await startRecording()
            case .recording:
                await stopRecordingAndProcess()
            default:
                print("⚠️ Cannot toggle in current state: \(recordingState)")
            }
        }
    }
    
    private func startRecording() async {
        print("🎤 [VoiceLocationManager] Starting location recording...")
        
        // Request permission
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            recordingState = .error
            errorMessage = "Microphone permission denied"
            return
        }
        
        // Setup recording
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("location_voice_recording.wav")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            let started = audioRecorder?.record() ?? false
            
            if started {
                recordingState = .recording
                errorMessage = nil
                print("✅ [VoiceLocationManager] Location recording started")
            } else {
                recordingState = .error
                errorMessage = "Failed to start recording"
            }
        } catch {
            recordingState = .error
            errorMessage = "Recording setup failed: \(error.localizedDescription)"
            print("❌ [VoiceLocationManager] Recording setup failed: \(error)")
        }
    }
    
    private func stopRecordingAndProcess() async {
        print("⏹️ [VoiceLocationManager] Stopping recording and processing...")
        
        guard let recorder = audioRecorder, recorder.isRecording else {
            recordingState = .error
            errorMessage = "No active recording found"
            return
        }
        
        // Stop recording
        recorder.stop()
        recordingState = .processing
        
        // Get audio file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("location_voice_recording.wav")
        
        do {
            // Read audio data
            let audioData = try Data(contentsOf: audioURL)
            print("✅ [VoiceLocationManager] Audio file read successfully (\(audioData.count) bytes)")
            
            // Clean up file
            try? FileManager.default.removeItem(at: audioURL)
            
            // Get transcription using Bhashini
            let transcription = await getTranscriptionFromAudioData(audioData)
            
            // Extract location information using Azure OpenAI
            let locationData = await extractLocationFromTranscription(transcription)
            self.extractedState = locationData.state
            self.extractedDistrict = locationData.district
            
            recordingState = .completed
            print("✅ [VoiceLocationManager] Processing completed - State: '\(locationData.state ?? "none")', District: '\(locationData.district ?? "none")'")
            
        } catch {
            recordingState = .error
            errorMessage = "Processing failed: \(error.localizedDescription)"
            print("❌ [VoiceLocationManager] Processing failed: \(error)")
        }
    }
    
    private func getTranscriptionFromAudioData(_ audioData: Data) async -> String {
        do {
            // Use existing Bhashini ASR infrastructure
            let pipelineConfig = try await getBhashiniASRPipelineConfig()
            let transcription = try await performASRInference(audioData: audioData, config: pipelineConfig)
            
            print("📝 [VoiceLocationManager] Transcription: '\(transcription)'")
            return transcription
            
        } catch {
            print("❌ [VoiceLocationManager] Transcription failed: \(error)")
            return ""
        }
    }
    
    private func extractLocationFromTranscription(_ transcription: String) async -> (state: String?, district: String?) {
        guard !transcription.isEmpty else { return (nil, nil) }
        
        let prompt = """
        Extract the Indian state and district/city names from this Hindi/English speech and return them in JSON format.
        
        Speech: "\(transcription)"
        
        Instructions:
        - Identify Indian state names (like Maharashtra, Delhi, Gujarat, etc.)
        - Identify district/city names (like Mumbai, Pune, Nashik, etc.)
        - Return in the appropriate language based on the input
        - If Hindi input, return Hindi names
        - If English input, return English names
        
        Return JSON with this exact structure:
        {
            "fullName": "extracted state name here or null",
            "mobileNumber": "extracted district/city name here or null"
        }
        """
        
        do {
            // Use Azure OpenAI to extract location data
            let response = try await azureOpenAIManager.extractFormData(prompt: prompt)
            
            // The response should contain location data
            // We'll use the fullName field for state and mobileNumber field for district as a workaround
            let state = response.fullName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let district = response.mobileNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("📍 [VoiceLocationManager] Extracted - State: '\(state ?? "none")', District: '\(district ?? "none")'")
            return (state?.isEmpty == false ? state : nil, district?.isEmpty == false ? district : nil)
            
        } catch {
            print("❌ [VoiceLocationManager] Location extraction failed: \(error)")
            return (nil, nil)
        }
    }
    
    // MARK: - Bhashini ASR Integration
    
    private func getBhashiniASRPipelineConfig() async throws -> [String: Any] {
        let url = URL(string: "https://meity-auth.ulcacontrib.org/ulca/apis/v0/model/getModelsPipeline")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("OIMRGSrr1AxW0kNeQORBGn5DG7YBGw6Z-0MPnUROAvjTdwDChye9MRvdtU9RBrS_", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "pipelineTasks": [
                [
                    "taskType": "asr",
                    "config": [
                        "language": [
                            "sourceLanguage": "hi"
                        ]
                    ]
                ]
            ],
            "pipelineRequestConfig": [
                "pipelineId": "64392f96daac500b55c543cd"
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VoiceLocationError.configurationFailed
        }
        
        return json
    }
    
    private func performASRInference(audioData: Data, config: [String: Any]) async throws -> String {
        let url = URL(string: "https://dhruva-api.bhashini.gov.in/services/inference/pipeline")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("OIMRGSrr1AxW0kNeQORBGn5DG7YBGw6Z-0MPnUROAvjTdwDChye9MRvdtU9RBrS_", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let base64Audio = audioData.base64EncodedString()
        
        guard let pipelineResponseConfig = config["pipelineResponseConfig"] as? [[String: Any]],
              let firstConfig = pipelineResponseConfig.first,
              let configArray = firstConfig["config"] as? [[String: Any]],
              let firstConfigItem = configArray.first,
              let serviceId = firstConfigItem["serviceId"] as? String,
              let modelId = firstConfigItem["modelId"] as? String else {
            throw VoiceLocationError.configurationFailed
        }
        
        let requestBody: [String: Any] = [
            "pipelineTasks": [
                [
                    "taskType": "asr",
                    "config": [
                        "modelId": modelId,
                        "serviceId": serviceId,
                        "language": [
                            "sourceLanguage": "hi"
                        ]
                    ]
                ]
            ],
            "inputData": [
                "audio": [
                    [
                        "audioContent": base64Audio
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VoiceLocationError.transcriptionFailed
        }
        
        // Parse transcription
        if let pipelineResponse = json["pipelineResponse"] as? [[String: Any]],
           let firstResponse = pipelineResponse.first,
           let output = firstResponse["output"] as? [[String: Any]],
           let firstOutput = output.first,
           let source = firstOutput["source"] as? String {
            return source.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        throw VoiceLocationError.transcriptionFailed
    }
    
    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func reset() {
        recordingState = .idle
        extractedState = nil
        extractedDistrict = nil
        errorMessage = nil
        audioRecorder?.stop()
        audioRecorder = nil
    }
}

// MARK: - Voice Location Errors

enum VoiceLocationError: Error, LocalizedError {
    case configurationFailed
    case transcriptionFailed
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .configurationFailed:
            return "Configuration failed"
        case .transcriptionFailed:
            return "Transcription failed"
        case .recordingFailed:
            return "Recording failed"
        }
    }
}

// MARK: - Preview

struct LocationInfoView_Previews: PreviewProvider {
    static var previews: some View {
        LocationInfoView(coordinator: OnboardingCoordinator())
            .environmentObject(LocalizationManager())
            .background(Color.black)
    }
} 