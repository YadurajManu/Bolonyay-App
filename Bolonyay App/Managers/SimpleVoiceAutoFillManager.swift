import Foundation
import SwiftUI
import AVFoundation

// MARK: - Simple Voice Auto-Fill Manager (Brand New)
@MainActor
class SimpleVoiceAutoFillManager: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var extractedData: SimpleFormData?
    @Published var errorMessage: String?
    @Published var transcriptionText = ""
    
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
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Main Recording Function
    
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
    
    // MARK: - Recording Functions
    
    private func startRecording() async {
        print("🎤 [SimpleVoiceManager] Starting recording...")
        
        // Request permission
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            recordingState = .error
            errorMessage = "Microphone permission denied"
            return
        }
        
        // Setup recording
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("simple_voice_recording.wav")
        
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
                print("✅ [SimpleVoiceManager] Recording started successfully")
            } else {
                recordingState = .error
                errorMessage = "Failed to start recording"
            }
        } catch {
            recordingState = .error
            errorMessage = "Recording setup failed: \(error.localizedDescription)"
            print("❌ [SimpleVoiceManager] Recording setup failed: \(error)")
        }
    }
    
    private func stopRecordingAndProcess() async {
        print("⏹️ [SimpleVoiceManager] Stopping recording and processing...")
        
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
        let audioURL = documentsPath.appendingPathComponent("simple_voice_recording.wav")
        
        do {
            // Read audio data
            let audioData = try Data(contentsOf: audioURL)
            print("✅ [SimpleVoiceManager] Audio file read successfully (\(audioData.count) bytes)")
            
            // Clean up file
            try? FileManager.default.removeItem(at: audioURL)
            
            // Get transcription using Bhashini
            let transcription = await getTranscriptionFromAudioData(audioData)
            transcriptionText = transcription
            
            // Extract form data using Azure OpenAI
            let formData = await extractFormDataFromTranscription(transcription)
            extractedData = formData
            
            recordingState = .completed
            print("✅ [SimpleVoiceManager] Processing completed successfully")
            
        } catch {
            recordingState = .error
            errorMessage = "Processing failed: \(error.localizedDescription)"
            print("❌ [SimpleVoiceManager] Processing failed: \(error)")
        }
    }
    
    // MARK: - Audio Processing
    
    private func getTranscriptionFromAudioData(_ audioData: Data) async -> String {
        do {
            // Use existing Bhashini ASR infrastructure
            let bhashiniManager = BhashiniManager()
            
            // Get pipeline configuration for ASR
            let pipelineConfig = try await getBhashiniASRPipelineConfig()
            
            // Perform ASR inference
            let transcription = try await performASRInference(audioData: audioData, config: pipelineConfig)
            
            print("📝 [SimpleVoiceManager] Transcription: '\(transcription)'")
            return transcription
            
        } catch {
            print("❌ [SimpleVoiceManager] Transcription failed: \(error)")
            return ""
        }
    }
    
    private func extractFormDataFromTranscription(_ transcription: String) async -> SimpleFormData? {
        guard !transcription.isEmpty else { return nil }
        
        let prompt = """
        Extract form data from this Hindi/English speech for account creation:
        
        Speech: "\(transcription)"
        
        Extract: name, email, phone number
        
        Respond ONLY with JSON:
        {
            "name": "extracted name or null",
            "email": "extracted email or null", 
            "phone": "10-digit number or null"
        }
        """
        
        do {
            let response = try await azureOpenAIManager.extractFormData(prompt: prompt)
            
            return SimpleFormData(
                name: response.fullName,
                email: response.email,
                phone: response.mobileNumber
            )
            
        } catch {
            print("❌ [SimpleVoiceManager] Form data extraction failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Bhashini ASR Integration (Simplified)
    
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
            throw SimpleVoiceError.configurationFailed
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
            throw SimpleVoiceError.configurationFailed
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
            throw SimpleVoiceError.transcriptionFailed
        }
        
        // Parse transcription
        if let pipelineResponse = json["pipelineResponse"] as? [[String: Any]],
           let firstResponse = pipelineResponse.first,
           let output = firstResponse["output"] as? [[String: Any]],
           let firstOutput = output.first,
           let source = firstOutput["source"] as? String {
            return source.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        throw SimpleVoiceError.transcriptionFailed
    }
    
    // MARK: - Utilities
    
    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func reset() {
        recordingState = .idle
        extractedData = nil
        errorMessage = nil
        transcriptionText = ""
        audioRecorder?.stop()
        audioRecorder = nil
    }
}

// MARK: - Simple Form Data Model

struct SimpleFormData: Equatable {
    let name: String?
    let email: String?
    let phone: String?
    
    var hasData: Bool {
        return name != nil || email != nil || phone != nil
    }
    
    // Equatable conformance
    static func == (lhs: SimpleFormData, rhs: SimpleFormData) -> Bool {
        return lhs.name == rhs.name &&
               lhs.email == rhs.email &&
               lhs.phone == rhs.phone
    }
}

// MARK: - Simple Voice Errors

enum SimpleVoiceError: Error, LocalizedError {
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