import Foundation

struct APIConfig {
    // MARK: - Bhashini API Configuration
    static let bhashiniAPIKey = "08cc654a6f-976b-4c71-94ce-b14888897dc8"
    static let bhashiniBaseURL = "https://dhruva-api.bhashini.gov.in/services"
    
    // MARK: - Azure OpenAI Configuration
    static let azureOpenAIKey1 = "D0IHVWMu9NsEsPpcKm8WIIZ8USoAniWSI59ZeQqy6szDwedgzETkJQQJ99BFACYeBjFXJ3w3AAABACOG9DIy"
    static let azureOpenAIKey2 = "1NieFFFB07YoiKZcBVZuPoOeCgI4FIEu2mxIi936syqiFm3Vv4iAJQQJ99BFACYeBjFXJ3w3AAABACOGkzrw"
    static let azureOpenAIEndpoint = "https://bolonyay.openai.azure.com/"
    static let azureLocation = "eastus"
    
    // MARK: - API Endpoints
    struct Endpoints {
        static let pipelineSearch = "\(bhashiniBaseURL)/inference/pipeline"
        static let pipelineConfig = "\(bhashiniBaseURL)/inference/pipeline"
        static let pipelineCompute = "\(bhashiniBaseURL)/inference/pipeline"
    }
    
    // MARK: - Language Codes (ISO-639)
    struct LanguageCodes {
        static let hindi = "hi"
        static let english = "en"
        static let bengali = "bn"
        static let gujarati = "gu"
        static let kannada = "kn"
        static let malayalam = "ml"
        static let marathi = "mr"
        static let punjabi = "pa"
        static let tamil = "ta"
        static let telugu = "te"
        static let urdu = "ur"
        static let assamese = "as"
        static let oriya = "or"
    }
} 