import Foundation

/// API Configuration for Voice Chatbot Integration
/// 
/// IMPORTANT: Please replace the placeholder values below with your actual API credentials
/// 
struct APIConfiguration {
    
    // MARK: - Bhashini API Configuration
    /// Bhashini API Key for ASR and TTS services (using exact same as LocalizationManager)
    static let bhashiniAPIKey = "OIMRGSrr1AxW0kNeQORBGn5DG7YBGw6Z-0MPnUROAvjTdwDChye9MRvdtU9RBrS_"
    
    /// Bhashini Pipeline Configuration Endpoint (using exact same as LocalizationManager)
    static let bhashiniConfigEndpoint = "https://meity-auth.ulcacontrib.org/ulca/apis/v0/model/getModelsPipeline"
    
    /// Bhashini Inference Endpoint for ASR and TTS (using exact same as LocalizationManager)
    static let bhashiniInferenceEndpoint = "https://dhruva-api.bhashini.gov.in/services/inference/pipeline"
    
    // MARK: - Azure OpenAI Configuration
    /// Azure OpenAI API Key (using existing credentials from LocalizationManager)
    static let azureAPIKey = "D0IHVWMu9NsEsPpcKm8WIIZ8USoAniWSI59ZeQqy6szDwedgzETkJQQJ99BFACYeBjFXJ3w3AAABACOG9DIy"
    
    /// Azure OpenAI Endpoint URL (using existing endpoint from LocalizationManager)
    static let azureEndpoint = "https://bolonyay.openai.azure.com"
    
    /// Azure OpenAI Deployment Name for GPT-4 (using existing deployment)
    static let azureDeploymentName = "gpt-4.1"
    
    /// Azure OpenAI API Version
    static let azureAPIVersion = "2024-02-15-preview"
    
    // MARK: - Voice Chatbot Settings
    /// Maximum characters for AI responses (increased for better context)
    static let maxResponseCharacters = 500
    
    /// Maximum recording duration in seconds
    static let maxRecordingDuration: TimeInterval = 30.0
    
    /// Audio sample rate for ASR (16kHz as required by Bhashini)
    static let audioSampleRate: Double = 16000.0
    
    /// Default language for voice chatbot
    static let defaultLanguage = "hi" // Hindi
    
    // MARK: - Validation
    /// Check if all required API keys are configured
    static var isConfigured: Bool {
        return !bhashiniAPIKey.contains("YOUR_")
        // Azure OpenAI credentials are already configured from LocalizationManager
    }
    
    /// Get validation error message if configuration is incomplete
    static var configurationError: String? {
        if bhashiniAPIKey.contains("YOUR_") {
            return "Please configure your Bhashini API Key in APIConfiguration.swift. Azure OpenAI is already configured."
        }
        return nil
    }
}

/// Extension to provide computed URLs
extension APIConfiguration {
    
    /// Complete Azure OpenAI Chat Completions URL
    static var azureChatCompletionsURL: String {
        return "\(azureEndpoint)/openai/deployments/\(azureDeploymentName)/chat/completions?api-version=\(azureAPIVersion)"
    }
}

