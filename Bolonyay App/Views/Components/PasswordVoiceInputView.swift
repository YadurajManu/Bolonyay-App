import SwiftUI
import AVFoundation
import Foundation

struct PasswordVoiceInputView: View {
    @StateObject private var voiceManager = PasswordVoiceManager()
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // Password field binding
    @Binding var passwordValue: String
    
    var body: some View {
        HStack(spacing: 8) {
            // Voice recording button
            Button(action: {
                voiceManager.toggleRecording()
            }) {
                Image(systemName: microphoneIcon)
                    .font(.system(size: 16))
                    .foregroundColor(microphoneColor)
                    .frame(width: 20, height: 20)
            }
            .disabled(voiceManager.recordingState == .processing)
            
            // Status indicator
            statusIndicator
        }
        .onChange(of: voiceManager.extractedPassword) { oldValue, newPassword in
            if let password = newPassword, !password.isEmpty {
                passwordValue = password
                
                // Reset after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    voiceManager.reset()
                }
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    // MARK: - Status Indicator
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch voiceManager.recordingState {
        case .idle:
            Text("पासवर्ड बोलें")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            
        case .recording:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 4, height: 4)
                    .scaleEffect(recordingPulse ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(), value: recordingPulse)
                    .onAppear { recordingPulse = true }
                    .onDisappear { recordingPulse = false }
                
                Text("सुन रहा हूं...")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
            
        case .processing:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text("प्रोसेसिंग...")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
        case .completed:
            Text("✅ भरा गया")
                .font(.caption2)
                .foregroundColor(.green)
            
        case .error:
            Text("❌ दोबारा करें")
                .font(.caption2)
                .foregroundColor(.red)
        }
    }
    
    // MARK: - Helper Properties
    
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
            return .white.opacity(0.7)
        }
    }
    
    @State private var recordingPulse = false
}

// MARK: - Password Voice Manager

@MainActor
class PasswordVoiceManager: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var extractedPassword: String?
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
        print("🎤 [PasswordVoiceManager] Starting password recording...")
        
        // Request permission
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            recordingState = .error
            errorMessage = "Microphone permission denied"
            return
        }
        
        // Setup recording
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("password_voice_recording.wav")
        
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
                print("✅ [PasswordVoiceManager] Password recording started")
            } else {
                recordingState = .error
                errorMessage = "Failed to start recording"
            }
        } catch {
            recordingState = .error
            errorMessage = "Recording setup failed: \(error.localizedDescription)"
            print("❌ [PasswordVoiceManager] Recording setup failed: \(error)")
        }
    }
    
    private func stopRecordingAndProcess() async {
        print("⏹️ [PasswordVoiceManager] Stopping recording and processing password...")
        
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
        let audioURL = documentsPath.appendingPathComponent("password_voice_recording.wav")
        
        do {
            // Read audio data
            let audioData = try Data(contentsOf: audioURL)
            print("✅ [PasswordVoiceManager] Audio file read successfully (\(audioData.count) bytes)")
            
            // Clean up file
            try? FileManager.default.removeItem(at: audioURL)
            
            // Get transcription using Bhashini
            let transcription = await getTranscriptionFromAudioData(audioData)
            
            // Extract password using Azure OpenAI
            let password = await extractPasswordFromTranscription(transcription)
            self.extractedPassword = password
            
            recordingState = .completed
            print("✅ [PasswordVoiceManager] Password processing completed: '\(password ?? "none")'")
            
        } catch {
            recordingState = .error
            errorMessage = "Processing failed: \(error.localizedDescription)"
            print("❌ [PasswordVoiceManager] Processing failed: \(error)")
        }
    }
    
    private func getTranscriptionFromAudioData(_ audioData: Data) async -> String {
        do {
            // Use existing Bhashini ASR infrastructure
            let pipelineConfig = try await getBhashiniASRPipelineConfig()
            let transcription = try await performASRInference(audioData: audioData, config: pipelineConfig)
            
            print("📝 [PasswordVoiceManager] Transcription: '\(transcription)'")
            return transcription
            
        } catch {
            print("❌ [PasswordVoiceManager] Transcription failed: \(error)")
            return ""
        }
    }
    
    private func extractPasswordFromTranscription(_ transcription: String) async -> String? {
        guard !transcription.isEmpty else { return nil }
        
        let prompt = """
        Extract the password from this Hindi/English speech and return it in JSON format.
        
        Speech: "\(transcription)"
        
        Instructions:
        - Extract ONLY the password part from the speech
        - Remove any words like "my password is", "password", "मेरा पासवर्ड है", etc.
        - Keep all characters, numbers, and symbols exactly as spoken
        - If numbers are spelled out (like "one two three"), convert to digits (123)
        
        Return JSON with this exact structure:
        {
            "fullName": "extracted password here"
        }
        """
        
        do {
            // Use existing extractFormData method and use fullName field for password
            let response = try await azureOpenAIManager.extractFormData(prompt: prompt)
            
            let cleanedPassword = response.fullName?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
            print("🔐 [PasswordVoiceManager] Extracted password: '\(cleanedPassword)'")
            return cleanedPassword.isEmpty ? nil : cleanedPassword
            
        } catch {
            print("❌ [PasswordVoiceManager] Password extraction failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Bhashini Integration
    
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
            throw PasswordVoiceError.configurationFailed
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
            throw PasswordVoiceError.configurationFailed
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
            throw PasswordVoiceError.transcriptionFailed
        }
        
        // Parse transcription
        if let pipelineResponse = json["pipelineResponse"] as? [[String: Any]],
           let firstResponse = pipelineResponse.first,
           let output = firstResponse["output"] as? [[String: Any]],
           let firstOutput = output.first,
           let source = firstOutput["source"] as? String {
            return source.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        throw PasswordVoiceError.transcriptionFailed
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
        extractedPassword = nil
        errorMessage = nil
        audioRecorder?.stop()
        audioRecorder = nil
    }
}

// MARK: - Password Voice Errors

enum PasswordVoiceError: Error, LocalizedError {
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

struct PasswordVoiceInputView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            PasswordVoiceInputView(
                passwordValue: .constant("")
            )
            .environmentObject(LocalizationManager())
            .padding()
        }
    }
} 