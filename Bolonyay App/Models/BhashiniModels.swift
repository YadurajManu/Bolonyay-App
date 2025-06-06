import Foundation

// MARK: - Language Support
struct Language: Codable, Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    let nativeName: String
    
    static let supportedLanguages = [
        Language(code: "hi", name: "Hindi", nativeName: "हिन्दी"),
        Language(code: "en", name: "English", nativeName: "English"),
        Language(code: "bn", name: "Bengali", nativeName: "বাংলা"),
        Language(code: "gu", name: "Gujarati", nativeName: "ગુજરાતી"),
        Language(code: "kn", name: "Kannada", nativeName: "ಕನ್ನಡ"),
        Language(code: "ml", name: "Malayalam", nativeName: "മലയാളം"),
        Language(code: "mr", name: "Marathi", nativeName: "मराठी"),
        Language(code: "pa", name: "Punjabi", nativeName: "ਪੰਜਾਬੀ"),
        Language(code: "ta", name: "Tamil", nativeName: "தமிழ்"),
        Language(code: "te", name: "Telugu", nativeName: "తెలుగు"),
        Language(code: "ur", name: "Urdu", nativeName: "اردو"),
        Language(code: "as", name: "Assamese", nativeName: "অসমীয়া"),
        Language(code: "or", name: "Oriya", nativeName: "ଓଡ଼ିଆ")
    ]
}

// MARK: - Pipeline Search Request
struct PipelineSearchRequest: Codable {
    let pipelineTasks: [PipelineTask]
    let config: PipelineSearchConfig
    
    struct PipelineTask: Codable {
        let taskType: String
        let config: TaskConfig
        
        struct TaskConfig: Codable {
            let language: LanguageConfig
            
            struct LanguageConfig: Codable {
                let sourceLanguage: String
                let targetLanguage: String?
            }
        }
    }
    
    struct PipelineSearchConfig: Codable {
        let authorizationKeys: [AuthorizationKey]
        
        struct AuthorizationKey: Codable {
            let name: String
            let value: String
        }
    }
}

// MARK: - Pipeline Search Response
struct PipelineSearchResponse: Codable {
    let pipelineResponseConfig: [PipelineResponseConfig]
    
    struct PipelineResponseConfig: Codable {
        let pipelineId: String
        let taskType: String
        let config: [ConfigItem]
        
        struct ConfigItem: Codable {
            let serviceId: String
            let modelId: String
            let language: LanguageConfig
            
            struct LanguageConfig: Codable {
                let sourceLanguage: String
                let targetLanguage: String?
            }
        }
    }
}

// MARK: - Pipeline Config Request
struct PipelineConfigRequest: Codable {
    let pipelineRequestConfig: PipelineRequestConfig
    
    struct PipelineRequestConfig: Codable {
        let pipelineId: String
        let inputData: InputData
        let authorizationKeys: [AuthorizationKey]
        
        struct InputData: Codable {
            let input: [InputItem]
            let audio: [AudioItem]?
            
            struct InputItem: Codable {
                let source: String
            }
            
            struct AudioItem: Codable {
                let audioContent: String
            }
        }
        
        struct AuthorizationKey: Codable {
            let name: String
            let value: String
        }
    }
}

// MARK: - Pipeline Config Response
struct PipelineConfigResponse: Codable {
    let pipelineResponseConfig: [PipelineResponseConfig]
    
    struct PipelineResponseConfig: Codable {
        let taskType: String
        let config: [ConfigItem]
        
        struct ConfigItem: Codable {
            let serviceId: String
            let modelId: String
            let language: LanguageConfig
            let callbackUrl: String
            let inferenceApiKey: InferenceApiKey
            
            struct LanguageConfig: Codable {
                let sourceLanguage: String
                let targetLanguage: String?
            }
            
            struct InferenceApiKey: Codable {
                let name: String
                let value: String
            }
        }
    }
}

// MARK: - Pipeline Compute Request
struct PipelineComputeRequest: Codable {
    let pipelineRequestConfig: PipelineRequestConfig
    
    struct PipelineRequestConfig: Codable {
        let pipelineId: String
        let inputData: InputData
        let authorizationKeys: [AuthorizationKey]
        
        struct InputData: Codable {
            let input: [InputItem]?
            let audio: [AudioItem]?
            
            struct InputItem: Codable {
                let source: String
            }
            
            struct AudioItem: Codable {
                let audioContent: String
            }
        }
        
        struct AuthorizationKey: Codable {
            let name: String
            let value: String
        }
    }
}

// MARK: - Pipeline Compute Response
struct PipelineComputeResponse: Codable {
    let pipelineResponse: [PipelineResponse]
    
    struct PipelineResponse: Codable {
        let taskType: String
        let output: [OutputItem]
        
        struct OutputItem: Codable {
            let source: String
            let target: String?
        }
    }
}

// MARK: - STT State Management
enum STTState {
    case idle
    case listening
    case processing
    case completed
    case error(String)
    
    var displayText: String {
        switch self {
        case .idle:
            return "Tap to start speaking"
        case .listening:
            return "Listening..."
        case .processing:
            return "Processing your speech..."
        case .completed:
            return "Speech recognized!"
        case .error(let message):
            return "Error: \(message)"
        }
    }
} 