import Foundation
import SwiftUI
import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = "en"
    @Published var isLanguageDetected: Bool = false
    @Published var errorMessage: String? = nil
    
    private var translations: [String: [String: String]] = [:]
    private let bhashiniManager = BhashiniManager()
    private let azureOpenAIManager = AzureOpenAIManager()
    
    // Language code mapping
    private let languageMapping: [String: String] = [
        "hindi": "hi",
        "gujarati": "gu", 
        "english": "en",
        "urdu": "ur",
        "marathi": "mr"
    ]
    
    init() {
        loadTranslations()
        loadSavedLanguage()
    }
    
    // MARK: - Translation Methods
    
    func text(_ key: String) -> String {
        return translations[currentLanguage]?[key] ?? translations["en"]?[key] ?? key
    }
    
    func localizedString(for key: String) -> String {
        return translations[currentLanguage]?[key] ?? translations["en"]?[key] ?? key
    }
    
    private func loadTranslations() {
        guard let path = Bundle.main.path(forResource: "Translations", ofType: "json"),
              let data = NSData(contentsOfFile: path),
              let json = try? JSONSerialization.jsonObject(with: data as Data) as? [String: [String: String]] else {
            print("❌ Failed to load translations")
            return
        }
        translations = json
        print("✅ Translations loaded for languages: \(translations.keys)")
    }
    
    // MARK: - Language Detection with Bhashini ASR + Azure OpenAI
    
    func detectLanguageFromSpeech() async {
        do {
            print("🎤 Starting voice-based language detection with Bhashini ASR + Azure OpenAI...")
            
            // Step 1: Record audio and get transcription using Bhashini ASR (Hindi model)
            let transcription = try await bhashiniManager.getTranscriptionFromAudio()
            
            print("📝 Got transcription from Bhashini: '\(transcription)'")
            
            // Step 2: Send transcription to Azure OpenAI for language identification
            let detectedLanguage = try await azureOpenAIManager.identifyLanguage(from: transcription)
            
            print("✅ Azure OpenAI detected language: \(detectedLanguage)")
            
            DispatchQueue.main.async {
                self.setLanguage(detectedLanguage)
                self.isLanguageDetected = true
                self.errorMessage = nil
                self.saveLanguageToUserDefaults()
                self.saveLanguageToFirebase()
                print("✅ Language detection completed successfully: \(detectedLanguage)")
            }
            
        } catch {
            print("❌ Language detection failed: \(error)")
            
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLanguageDetected = false
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("LanguageDetectionError"), 
                    object: error.localizedDescription
                )
            }
        }
    }
    
    // MARK: - Language Management
    
    func setLanguage(_ language: String) {
        let mappedLanguage = languageMapping[language.lowercased()] ?? language
        
        if translations.keys.contains(mappedLanguage) {
            currentLanguage = mappedLanguage
            print("✅ Language set to: \(mappedLanguage)")
        } else {
            print("⚠️ Language not supported: \(language), falling back to English")
            currentLanguage = "en"
        }
    }
    
    private func loadSavedLanguage() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "user_preferred_language") {
            currentLanguage = savedLanguage
            isLanguageDetected = true
            print("✅ Loaded saved language: \(savedLanguage)")
        }
    }
    
    private func saveLanguageToUserDefaults() {
        UserDefaults.standard.set(currentLanguage, forKey: "user_preferred_language")
        print("💾 Language saved to UserDefaults: \(currentLanguage)")
    }
    
    private func saveLanguageToFirebase() {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).updateData([
            "preferredLanguage": currentLanguage,
            "languageDetectedAt": Timestamp()
        ]) { error in
            if let error = error {
                print("❌ Failed to save language to Firebase: \(error)")
            } else {
                print("✅ Language saved to Firebase: \(self.currentLanguage)")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func getSupportedLanguages() -> [String: String] {
        return [
            "en": "English",
            "hi": "हिंदी",
            "gu": "ગુજરાતી", 
            "ur": "اردو",
            "mr": "मराठी"
        ]
    }
    
    func getCurrentLanguageName() -> String {
        return getSupportedLanguages()[currentLanguage] ?? "English"
    }
    

    
    // MARK: - Testing Helper
    func clearSavedLanguagePreference() {
        UserDefaults.standard.removeObject(forKey: "user_preferred_language")
        isLanguageDetected = false
        print("🧹 Cleared saved language preference for testing")
    }
}

// MARK: - Azure OpenAI Manager

class AzureOpenAIManager {
    
    // Azure OpenAI Configuration
    private let apiKey = "D0IHVWMu9NsEsPpcKm8WIIZ8USoAniWSI59ZeQqy6szDwedgzETkJQQJ99BFACYeBjFXJ3w3AAABACOG9DIy"
    private let endpoint = "https://bolonyay.openai.azure.com/"
    private let deploymentName = "gpt-4.1"  // Your deployment name
    private let apiVersion = "2024-02-15-preview"
    
    // MARK: - Testing Method (for TestLanguageDetectionView)
    func identifyLanguage(from text: String) async throws -> String {
        let url = URL(string: "\(endpoint)openai/deployments/\(deploymentName)/chat/completions?api-version=\(apiVersion)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        let prompt = """
        You are a language detection expert for an Indian legal assistance app. Analyze the following text and identify which language it is written in.
        
        SUPPORTED LANGUAGES: Hindi, Gujarati, English, Urdu, Marathi
        
        TEXT TO ANALYZE: "\(text)"
        
        RESPONSE: Reply with ONLY the language name in lowercase (hindi, gujarati, english, urdu, or marathi). No explanations.
        """
        
        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "system",
                    "content": "You are a language detection expert. You must respond with only the language name in lowercase."
                ],
                [
                    "role": "user", 
                    "content": prompt
                ]
            ],
            "max_tokens": 10,
            "temperature": 0.1
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureOpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AzureOpenAIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AzureOpenAIError.invalidResponse
        }
        
        // Parse the response to extract the language
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            let detectedLanguage = content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            // Validate the response is one of our supported languages
            let supportedLanguages = ["hindi", "gujarati", "english", "urdu", "marathi"]
            if supportedLanguages.contains(detectedLanguage) {
                return detectedLanguage
            } else {
                return "english"
            }
        }
        
        throw AzureOpenAIError.invalidResponse
    }
    
    func validateDetectedLanguage(_ detectedLanguage: String) async throws -> String {
        let url = URL(string: "\(endpoint)openai/deployments/\(deploymentName)/chat/completions?api-version=\(apiVersion)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        let prompt = """
        You are a language validation expert for an Indian legal assistance app. A Bhashini ALD (Automatic Language Detection) model has detected a language from audio speech.
        
        DETECTED LANGUAGE: "\(detectedLanguage)"
        
        SUPPORTED LANGUAGES: hindi, gujarati, english, urdu, marathi
        
        VALIDATION TASK:
        1. Check if the detected language is one of our supported languages
        2. Map common variations to correct language codes:
           - "hi" or "hin" → "hindi"
           - "gu" or "guj" → "gujarati"  
           - "en" or "eng" → "english"
           - "ur" or "urd" → "urdu"
           - "mr" or "mar" → "marathi"
        3. If the detected language is not supported, default to "hindi"
        4. Ensure the response is always one of our 5 supported languages
        
        RESPONSE: Reply with ONLY the validated language name in lowercase (hindi, gujarati, english, urdu, or marathi). No explanations.
        """
        
        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "system",
                    "content": "You are a language validation expert. You must respond with only the validated language name in lowercase."
                ],
                [
                    "role": "user", 
                    "content": prompt
                ]
            ],
            "max_tokens": 10,
            "temperature": 0.1
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔗 Sending language validation request to Azure OpenAI...")
        print("📤 Validating: \(detectedLanguage)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureOpenAIError.invalidResponse
        }
        
        print("📡 Azure OpenAI Validation Response Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Azure OpenAI Validation Error: \(errorMessage)")
            throw AzureOpenAIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AzureOpenAIError.invalidResponse
        }
        
        // Parse the response to extract the validated language
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            let validatedLanguage = content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            print("🎯 Azure OpenAI validated language: \(validatedLanguage)")
            
            // Ensure the response is one of our supported languages
            let supportedLanguages = ["hindi", "gujarati", "english", "urdu", "marathi"]
            if supportedLanguages.contains(validatedLanguage) {
                return validatedLanguage
            } else {
                print("⚠️ Unsupported validated language: \(validatedLanguage), defaulting to Hindi")
                return "hindi"
            }
        }
        
        throw AzureOpenAIError.invalidResponse
    }
}

enum AzureOpenAIError: Error {
    case invalidResponse
    case apiError(Int, String)
    case networkError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from Azure OpenAI"
        case .apiError(let code, let message):
            return "Azure OpenAI API error (\(code)): \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Bhashini Integration Manager (Updated)

class BhashiniManager: NSObject, ObservableObject {
    
    // Bhashini API credentials
    private let udyatAPIKey = "08cc654a6f-976b-4c71-94ce-b14888897dc8"
    private let authorizationKey = "OIMRGSrr1AxW0kNeQORBGn5DG7YBGw6Z-0MPnUROAvjTdwDChye9MRvdtU9RBrS_"
    private let bhashiniConfigEndpoint = "https://meity-auth.ulcacontrib.org/ulca/apis/v0/model/getModelsPipeline"
    private let bhashiniInferenceEndpoint = "https://dhruva-api.bhashini.gov.in/services/inference/pipeline"
    
    // Audio recording
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession?
    
    override init() {
        super.init()
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
    
    // MARK: - Main ASR Function for Language Detection
    
    func getTranscriptionFromAudio() async throws -> String {
        print("🎤 Starting voice recording for ASR transcription...")
        
        // 1. Request microphone permission
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            throw BhashiniError.microphonePermissionDenied
        }
        
        // 2. Record audio for 3 seconds
        let audioData = try await recordAudio(duration: 3.0)
        print("✅ Audio recorded successfully")
        
        // 3. Use Bhashini ASR (Hindi model) to get transcription
        let transcription = try await performASRTranscription(audioData: audioData)
        
        print("📝 Bhashini ASR transcription: '\(transcription)'")
        return transcription
    }
    
    func detectLanguageFromAudio() async throws -> String {
        print("🎤 Starting voice recording for language detection using Bhashini ALD...")
        
        // 1. Request microphone permission
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            throw BhashiniError.microphonePermissionDenied
        }
        
        // 2. Record audio for 3 seconds
        let audioData = try await recordAudio(duration: 3.0)
        print("✅ Audio recorded successfully")
        
        // 3. Use Bhashini ALD (Automatic Language Detection) to detect language directly from audio
        let detectedLanguage = try await callBhashiniALD(audioData: audioData)
        
        print("🎯 Bhashini ALD detected language: \(detectedLanguage)")
        return detectedLanguage
    }
    
    // Note: Transcription scoring functions removed since we now use direct ALD
    
    // MARK: - Audio Recording
    
    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            recordingSession?.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    private func recordAudio(duration: TimeInterval) async throws -> Data {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording.wav")
        
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
            audioRecorder?.record()
            
            // Record for specified duration
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
            audioRecorder?.stop()
            
            // Read recorded audio data
            let audioData = try Data(contentsOf: audioURL)
            
            // Clean up
            try? FileManager.default.removeItem(at: audioURL)
            
            return audioData
            
        } catch {
            throw BhashiniError.audioRecordingFailed
        }
    }
    
    // MARK: - Bhashini ASR Integration
    
    private func performASRTranscription(audioData: Data) async throws -> String {
        // Get pipeline configuration for ASR (Hindi model)
        let pipelineConfig = try await getBhashiniASRPipelineConfig()
        
        // Call ASR service with audio data to get transcription
        let transcription = try await performASRInference(audioData: audioData, config: pipelineConfig)
        
        return transcription
    }
    
    // MARK: - Bhashini ALD Integration
    
    private func callBhashiniALD(audioData: Data) async throws -> String {
        // Get pipeline configuration for ALD (Automatic Language Detection)
        let pipelineConfig = try await getBhashiniALDPipelineConfig()
        
        // Call ALD service with audio data
        let detectedLanguage = try await performALDInference(audioData: audioData, config: pipelineConfig)
        
        return detectedLanguage
    }
    
    private func getBhashiniASRPipelineConfig() async throws -> [String: Any] {
        guard let url = URL(string: bhashiniConfigEndpoint) else {
            throw BhashiniError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authorizationKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Request configuration for ASR (Hindi model)
        let requestBody: [String: Any] = [
            "pipelineTasks": [
                [
                    "taskType": "asr",
                    "config": [
                        "language": [
                            "sourceLanguage": "hi"  // Hindi ASR model
                        ]
                    ]
                ]
            ],
            "pipelineRequestConfig": [
                "pipelineId": "64392f96daac500b55c543cd"
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📤 Requesting Bhashini ASR pipeline configuration...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BhashiniError.configurationError
        }
        
        print("📡 ASR Config Response Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let responseText = String(data: data, encoding: .utf8) ?? "No data"
            print("❌ ASR Config API Error: \(httpResponse.statusCode)")
            print("❌ Response: \(responseText)")
            throw BhashiniError.configurationError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BhashiniError.invalidResponse
        }
        
        print("✅ ASR Pipeline config received")
        return json
    }
    
    private func getBhashiniALDPipelineConfig() async throws -> [String: Any] {
        guard let url = URL(string: bhashiniConfigEndpoint) else {
            throw BhashiniError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authorizationKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Request configuration for Language Detection  
        let requestBody: [String: Any] = [
            "pipelineTasks": [
                [
                    "taskType": "tts", // Start with a known working task type for config request
                    "config": [
                        "language": [
                            "sourceLanguage": "hi"  // Use Hindi as default for config
                        ]
                    ]
                ]
            ],
            "pipelineRequestConfig": [
                "pipelineId": "64392f96daac500b55c543cd"
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📤 Requesting Bhashini ALD pipeline configuration...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BhashiniError.configurationError
        }
        
        print("📡 ALD Config Response Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let responseText = String(data: data, encoding: .utf8) ?? "No data"
            print("❌ ALD Config API Error: \(httpResponse.statusCode)")
            print("❌ Response: \(responseText)")
            throw BhashiniError.configurationError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BhashiniError.invalidResponse
        }
        
        print("✅ ALD Pipeline config received")
        return json
    }
    
    private func performASRInference(audioData: Data, config: [String: Any]) async throws -> String {
        guard let url = URL(string: bhashiniInferenceEndpoint) else {
            throw BhashiniError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authorizationKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert audio to base64
        let base64Audio = audioData.base64EncodedString()
        
        // Extract service details from config response
        guard let pipelineResponseConfig = config["pipelineResponseConfig"] as? [[String: Any]],
              let firstConfig = pipelineResponseConfig.first,
              let configArray = firstConfig["config"] as? [[String: Any]],
              let firstConfigItem = configArray.first,
              let serviceId = firstConfigItem["serviceId"] as? String,
              let modelId = firstConfigItem["modelId"] as? String else {
            throw BhashiniError.configurationError
        }
        
        let requestBody: [String: Any] = [
            "pipelineTasks": [
                [
                    "taskType": "asr", // Automatic Speech Recognition
                    "config": [
                        "modelId": modelId,
                        "serviceId": serviceId,
                        "language": [
                            "sourceLanguage": "hi"  // Hindi ASR model
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
        
        print("📤 Sending ASR inference request...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BhashiniError.networkError("Invalid response type")
        }
        
        print("📡 ASR Response Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let responseText = String(data: data, encoding: .utf8) ?? "No data"
            print("❌ ASR API Error: \(httpResponse.statusCode)")
            print("❌ Response: \(responseText)")
            throw BhashiniError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BhashiniError.invalidResponse
        }
        
        print("📨 ASR Response: \(json)")
        
        // Parse the response to extract transcription
        if let pipelineResponse = json["pipelineResponse"] as? [[String: Any]],
           let firstResponse = pipelineResponse.first,
           let output = firstResponse["output"] as? [[String: Any]],
           let firstOutput = output.first,
           let source = firstOutput["source"] as? String {
            
            print("📝 ASR transcription extracted: '\(source)'")
            return source.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try alternative response format for transcription
        if let outputs = json["output"] as? [[String: Any]],
           let firstOutput = outputs.first,
           let source = firstOutput["source"] as? String {
            
            print("📝 ASR transcription extracted (alt): '\(source)'")
            return source.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        print("❌ Could not extract transcription from ASR response")
        print("📋 Full response structure: \(json)")
        throw BhashiniError.languageDetectionFailed
    }
    
    private func performALDInference(audioData: Data, config: [String: Any]) async throws -> String {
        guard let url = URL(string: bhashiniInferenceEndpoint) else {
            throw BhashiniError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authorizationKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert audio to base64
        let base64Audio = audioData.base64EncodedString()
        
        // Extract service details from config response
        guard let pipelineResponseConfig = config["pipelineResponseConfig"] as? [[String: Any]],
              let firstConfig = pipelineResponseConfig.first,
              let configArray = firstConfig["config"] as? [[String: Any]],
              let firstConfigItem = configArray.first,
              let serviceId = firstConfigItem["serviceId"] as? String,
              let modelId = firstConfigItem["modelId"] as? String else {
            throw BhashiniError.configurationError
        }
        
        let requestBody: [String: Any] = [
            "pipelineTasks": [
                [
                    "taskType": "ald", // Automatic Language Detection
                    "config": [
                        "modelId": modelId,
                        "serviceId": serviceId
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BhashiniError.networkError("Invalid response type")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw BhashiniError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BhashiniError.invalidResponse
        }
        
        print("📨 ALD Response: \(json)")
        
        // Parse the response to extract detected language from ALD
        if let pipelineResponse = json["pipelineResponse"] as? [[String: Any]],
           let firstResponse = pipelineResponse.first,
           let output = firstResponse["output"] as? [[String: Any]],
           let firstOutput = output.first,
           let detectedLanguage = firstOutput["langPrediction"] as? [[String: Any]],
           let topPrediction = detectedLanguage.first,
           let langCode = topPrediction["langCode"] as? String {
            
            let normalizedLangCode = normalizeBhashiniLanguageCode(langCode)
            print("🎯 ALD detected language code: \(langCode) → normalized: \(normalizedLangCode)")
            return normalizedLangCode
        }
        
        // Try alternative response format for language detection
        if let outputs = json["output"] as? [[String: Any]],
           let firstOutput = outputs.first,
           let langPrediction = firstOutput["langPrediction"] as? [[String: Any]],
           let topPrediction = langPrediction.first,
           let langCode = topPrediction["langCode"] as? String {
            
            let normalizedLangCode = normalizeBhashiniLanguageCode(langCode)
            print("🎯 ALD detected language code (alt): \(langCode) → normalized: \(normalizedLangCode)")
            return normalizedLangCode
        }
        
        // Check if there's a simple language field
        if let pipelineResponse = json["pipelineResponse"] as? [[String: Any]],
           let firstResponse = pipelineResponse.first,
           let output = firstResponse["output"] as? [[String: Any]],
           let firstOutput = output.first,
           let language = firstOutput["language"] as? String {
            
            let normalizedLangCode = normalizeBhashiniLanguageCode(language)
            print("🎯 ALD detected language (simple): \(language) → normalized: \(normalizedLangCode)")
            return normalizedLangCode
        }
        
        print("❌ Could not extract language detection from ALD response")
        print("📋 Full response structure: \(json)")
        throw BhashiniError.languageDetectionFailed
    }
    
    // MARK: - Language Code Normalization
    
    private func normalizeBhashiniLanguageCode(_ bhashiniCode: String) -> String {
        let normalizedCode = bhashiniCode.lowercased()
        
        switch normalizedCode {
        case "hi", "hin", "hindi":
            return "hindi"
        case "gu", "guj", "gujarati":
            return "gujarati"
        case "en", "eng", "english":
            return "english"
        case "ur", "urd", "urdu":
            return "urdu"
        case "mr", "mar", "marathi":
            return "marathi"
        default:
            print("⚠️ Unknown Bhashini language code: \(bhashiniCode), defaulting to Hindi")
            return "hindi"
        }
    }
}

enum BhashiniError: Error {
    case invalidURL
    case invalidResponse
    case audioRecordingFailed
    case microphonePermissionDenied
    case networkError(String)
    case configurationError
    case languageDetectionFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from Bhashini API"
        case .audioRecordingFailed:
            return "Failed to record audio"
        case .microphonePermissionDenied:
            return "Microphone permission denied"
        case .networkError(let message):
            return "Network error: \(message)"
        case .configurationError:
            return "Bhashini configuration error"
        case .languageDetectionFailed:
            return "Could not detect language from speech"
        }
    }
} 