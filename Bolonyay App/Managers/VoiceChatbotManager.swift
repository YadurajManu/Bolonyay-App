import Foundation
import AVFoundation
import Combine
import SwiftUI

@MainActor
class VoiceChatbotManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var currentTranscription = ""
    @Published var chatbotResponse = ""
    @Published var conversationHistory: [ChatMessage] = []
    @Published var errorMessage: String? = nil
    @Published var audioLevel: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0.0
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var audioLevelTimer: Timer?
    private let audioSession = AVAudioSession.sharedInstance()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Data Models
    
    struct ChatMessage: Identifiable, Codable {
        let id = UUID()
        let content: String
        let isUser: Bool
        let timestamp: Date
        let language: String
        
        init(content: String, isUser: Bool, language: String = "hindi") {
            self.content = content
            self.isUser = isUser
            self.timestamp = Date()
            self.language = language
        }
    }
    
    struct AzureResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: Message
        }
        
        struct Message: Codable {
            let content: String
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupAudioSession()
        validateConfiguration()
    }
    
    // MARK: - Configuration Validation
    
    private func validateConfiguration() {
        if let configError = APIConfiguration.configurationError {
            errorMessage = configError
            print("⚠️ API Configuration Error: \(configError)")
        }
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Request microphone permission
            audioSession.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        self?.errorMessage = "Microphone permission is required for voice chat"
                    }
                }
            }
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Voice Recording
    
    func startListening() {
        guard !isListening else { return }
        
        errorMessage = nil
        currentTranscription = ""
        
        // Clean up any existing recorder
        cleanupAudioRecorder()
        
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentsPath.appendingPathComponent("voice_recording.wav")
            
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: audioURL.path) {
                try FileManager.default.removeItem(at: audioURL)
                print("🗑️ Removed existing audio file")
            }
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isListening = true
            recordingDuration = 0.0
            
            startRecordingTimer()
            startAudioLevelMonitoring()
            
            print("🎤 Started voice recording to: \(audioURL.path)")
            
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            print("❌ Recording start error: \(error)")
        }
    }
    
    func stopListening() {
        guard isListening else { return }
        
        audioRecorder?.stop()
        isListening = false
        
        stopRecordingTimer()
        stopAudioLevelMonitoring()
        
        print("🛑 Stopped voice recording")
        
        // Process the recorded audio
        if let audioURL = audioRecorder?.url {
            processRecordedAudio(audioURL)
        }
        
        // Clean up the recorder to prevent conflicts
        cleanupAudioRecorder()
    }
    
    private func cleanupAudioRecorder() {
        audioRecorder?.delegate = nil
        audioRecorder = nil
        
        // Deactivate and reactivate audio session to reset
        do {
            try audioSession.setActive(false)
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Warning: Could not reset audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Timer Management
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
            
            // Auto-stop after maximum duration
            if self.recordingDuration >= APIConfiguration.maxRecordingDuration {
                self.stopListening()
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            let level = recorder.averagePower(forChannel: 0)
            
            // Convert dB to 0-1 range
            let normalizedLevel = max(0.0, (level + 80) / 80.0)
            self.audioLevel = Float(normalizedLevel)
        }
    }
    
    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        audioLevel = 0.0
    }
    
    // MARK: - Audio Processing Pipeline
    
    private func processRecordedAudio(_ audioURL: URL) {
        isProcessing = true
        
        Task {
            do {
                // Step 1: Convert audio to text using Bhashini ASR
                let transcription = try await transcribeAudioWithBhashini(audioURL)
                
                await MainActor.run {
                    self.currentTranscription = transcription
                    // Add user message to conversation
                    let userMessage = ChatMessage(content: transcription, isUser: true)
                    self.conversationHistory.append(userMessage)
                }
                
                // Step 2: Get AI response from Azure
                let aiResponse = try await getAzureResponse(for: transcription)
                
                await MainActor.run {
                    self.chatbotResponse = aiResponse
                    // Add AI message to conversation
                    let aiMessage = ChatMessage(content: aiResponse, isUser: false)
                    self.conversationHistory.append(aiMessage)
                }
                
                // Response is ready - just display the text
                
                await MainActor.run {
                    self.isProcessing = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Voice processing failed: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - Bhashini ASR Integration
    
    private func transcribeAudioWithBhashini(_ audioURL: URL) async throws -> String {
        let audioData = try Data(contentsOf: audioURL)
        
        // Step 1: Get pipeline configuration for ASR
        let pipelineConfig = try await getBhashiniASRPipelineConfig()
        
        // Step 2: Perform ASR inference using the configured pipeline
        return try await performASRInference(audioData: audioData, config: pipelineConfig)
    }
    
    private func getBhashiniASRPipelineConfig() async throws -> [String: Any] {
        // Use exact same config as working case filing system
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
        
        print("📤 ASR Config: Requesting pipeline configuration...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let responseText = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ ASR Config: Request failed")
            print("❌ ASR Config: Response: \(responseText)")
            throw NSError(domain: "BhashiniASR", code: 2, userInfo: [NSLocalizedDescriptionKey: "ASR config request failed"])
        }
        
        print("✅ ASR Config: Pipeline configuration received")
        return json
    }
    
    private func performASRInference(audioData: Data, config: [String: Any]) async throws -> String {
        // Use exact same inference endpoint as working case filing system
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
            print("❌ ASR: Invalid config structure")
            throw NSError(domain: "BhashiniASR", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid config structure"])
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
        
        print("📤 ASR: Sending inference request...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let responseText = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ ASR: Inference failed")
            print("❌ ASR: Response: \(responseText)")
            throw NSError(domain: "BhashiniASR", code: 3, userInfo: [NSLocalizedDescriptionKey: "ASR inference failed"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ ASR: Could not parse JSON response")
            throw NSError(domain: "BhashiniASR", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid ASR response"])
        }
        
        print("📦 ASR: Response received")
        
        // Parse ASR response - same structure as case filing system
        if let pipelineResponse = json["pipelineResponse"] as? [[String: Any]],
           let firstResponse = pipelineResponse.first,
           let output = firstResponse["output"] as? [[String: Any]],
           let firstOutput = output.first,
           let source = firstOutput["source"] as? String {
            
            print("🎯 ASR Transcript: \(source)")
            return source
        }
        
        print("❌ ASR: No transcript found in response")
        throw NSError(domain: "BhashiniASR", code: 5, userInfo: [NSLocalizedDescriptionKey: "No transcript found in response"])
    }
    
    // MARK: - Azure AI Integration
    
    private func getAzureResponse(for text: String) async throws -> String {
        var request = URLRequest(url: URL(string: APIConfiguration.azureChatCompletionsURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfiguration.azureAPIKey, forHTTPHeaderField: "api-key")
        
        let systemPrompt = """
        आप "न्याय" हैं, एक कानूनी सहायक। संक्षिप्त और स्पष्ट उत्तर दें।

        निर्देश:
        • 2-3 वाक्यों में मुख्य बात बताएं
        • सरल हिंदी का प्रयोग करें
        • केवल जरूरी जानकारी दें
        • वकील से सलाह लेने की सिफारिश करें
        """
        
        let requestBody: [String: Any] = [
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "max_tokens": 80,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "AzureAI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Azure AI request failed"])
        }
        
        let azureResponse = try JSONDecoder().decode(AzureResponse.self, from: data)
        
        guard let aiResponse = azureResponse.choices.first?.message.content else {
            throw NSError(domain: "AzureAI", code: 2, userInfo: [NSLocalizedDescriptionKey: "No AI response received"])
        }
        
        print("🤖 AI Response: \(aiResponse)")
        return aiResponse
    }
    
    // MARK: - Conversation Management
    
    func clearConversation() {
        conversationHistory.removeAll()
        currentTranscription = ""
        chatbotResponse = ""
        errorMessage = nil
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceChatbotManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                self.errorMessage = "Recording failed to complete"
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.errorMessage = "Recording error: \(error.localizedDescription)"
            }
        }
    }
} 