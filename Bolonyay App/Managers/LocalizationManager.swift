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
    
    // MARK: - Legal Case Analysis
    
    func analyzeLegalCase(transcription: String, language: String) async throws -> String {
        let url = URL(string: "\(endpoint)openai/deployments/\(deploymentName)/chat/completions?api-version=\(apiVersion)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        let prompt = """
        You are a compassionate and expert legal advisor AI for BoloNyay app, helping Indian citizens access justice. A user just shared their legal concern with you in \(getLanguageName(for: language)).
        
        USER'S CONCERN:
        "\(transcription)"
        
        YOUR ROLE: Act like a caring legal expert who truly understands their situation. Listen carefully, provide helpful guidance, and ask thoughtful questions to better help them.
        
        RESPONSE STYLE: Write naturally in \(getLanguageName(for: language)) without using formatting symbols like asterisks, brackets, or mathematical symbols. Use simple, warm, conversational language that shows you understand their concern.
        
        STRUCTURE YOUR RESPONSE AS:
        
        मैं आपकी स्थिति समझ गया हूँ / I understand your situation
        [Acknowledge what they shared and show empathy]
        
        यह कानूनी मामला है / This appears to be a legal matter related to
        [Identify the type of case in simple terms with relevant Indian law context]
        
        आपकी मुख्य समस्याएं हैं / Your main concerns are
        [List 2-3 key issues in plain language without bullet points or symbols]
        
        मेरी सलाह है / My advice to you is
        [Provide practical, actionable legal guidance specific to Indian legal system, including relevant acts, procedures, and realistic expectations]
        
        आपको तुरंत ये काम करने चाहिए / You should immediately do these things
        [Give 3-4 specific action steps with timelines and requirements]
        
        महत्वपूर्ण बातें / Important things to remember
        [Share critical information about deadlines, costs, rights, required documents]
        
        मुझे आपसे कुछ और जानना है / I need to know more from you
        [Ask 3-4 intelligent, specific questions to better understand their case and provide more targeted help]
        
        आगे क्या करना है / What to do next
        [Clear next steps for using BoloNyay app or legal system]
        
        IMPORTANT GUIDELINES:
        - Write in pure conversational \(getLanguageName(for: language)) without any English mixing unless necessary for legal terms
        - NO formatting symbols, asterisks, bullets, or mathematical characters
        - Be warm, understanding, and encouraging
        - Provide specific legal guidance based on Indian laws
        - Ask smart questions that show you're thinking deeply about their case
        - Make them feel heard and supported
        """
        
        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful legal assistant AI for Indian legal system. You provide preliminary legal guidance and analysis in simple, understandable language."
                ],
                [
                    "role": "user", 
                    "content": prompt
                ]
            ],
            "max_tokens": 1200,
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🤖 Sending case analysis request to Azure OpenAI...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureOpenAIError.invalidResponse
        }
        
        print("📡 Azure OpenAI Response Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Azure OpenAI Error: \(httpResponse.statusCode) - \(errorMessage)")
            throw AzureOpenAIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AzureOpenAIError.invalidResponse
        }
        
        // Parse the response to extract the case analysis
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            print("✅ Case analysis received from Azure OpenAI")
            let cleanedContent = cleanFormattingSymbols(content)
            return cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        throw AzureOpenAIError.invalidResponse
    }
    
    func analyzeCaseForFiling(conversationSummary: String, language: String) async throws -> String {
        let url = URL(string: "\(endpoint)openai/deployments/\(deploymentName)/chat/completions?api-version=\(apiVersion)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        let prompt = """
        You are an expert legal case filing specialist for Indian courts with 20+ years experience. A user has shared their legal concern and wants to file a formal case.
        
        CONVERSATION SUMMARY:
        \(conversationSummary)
        
        YOUR EXPERTISE: Analyze this conversation with precision and create a comprehensive case filing questionnaire that covers all legal requirements for Indian courts.
        
        TASK BREAKDOWN:
        
        1. CASE TYPE IDENTIFICATION - Determine the exact legal category:
           • Civil Cases: Property disputes, contract breaches, defamation, money recovery, partnership disputes
           • Criminal Cases: Cheating, fraud, harassment, domestic violence, theft, assault
           • Family Cases: Divorce, maintenance, child custody, dowry harassment, domestic violence
           • Consumer Cases: Product defects, service failures, unfair trade practices
           • Labor Cases: Wrongful termination, salary disputes, workplace harassment
           • Property Cases: Land disputes, illegal possession, boundary issues, property fraud
           • Commercial Cases: Business disputes, trademark violations, competition issues
        
        2. LEGAL FOUNDATION - Summarize the core legal issue with relevant Indian laws
        
        3. COMPREHENSIVE QUESTIONNAIRE - Generate 8-12 specific questions covering:
           • Personal Details & Standing
           • Factual Timeline & Evidence
           • Parties Involved & Relationships
           • Financial Impact & Damages
           • Legal Relief Sought
           • Supporting Documents
           • Urgency & Timeline
           • Jurisdiction & Venue
           • Previous Legal Actions
           • Witness Information
        
        RESPONSE FORMAT (use exact headers):
        
        CASE TYPE: [Specific category with subcategory, e.g., "Civil Case - Property Dispute", "Criminal Case - Cheating and Fraud"]
        
        CASE DETAILS: [Detailed summary with relevant Indian legal provisions like IPC sections, Civil Procedure Code, specific acts]
        
        QUESTIONS:
        - आपका पूरा नाम, पता और उम्र क्या है? (What is your full name, address and age?)
        - घटना की सटीक तारीख और समय क्या था? (What was the exact date and time of the incident?)
        - [Continue with case-specific questions...]
        
        QUESTION CATEGORIES TO INCLUDE:
        
        FOR ALL CASES:
        • Personal identification and legal standing
        • Complete incident timeline with dates
        • All parties involved with full details
        • Evidence and documents available
        • Witnesses and their contact information
        • Financial losses or damages
        • Specific legal relief sought
        • Urgency factors and limitation periods
        
        FOR PROPERTY CASES:
        • Property details, survey numbers, documents
        • Chain of title and registration details
        • Possession history and current status
        • Market value and financial impact
        
        FOR CRIMINAL CASES:
        • FIR details if filed
        • Police station and investigating officer
        • Medical reports if applicable
        • Threat assessment and safety concerns
        
        FOR FAMILY CASES:
        • Marriage details and duration
        • Children and their custody
        • Financial support and assets
        • Domestic violence incidents with dates
        
        FOR CONSUMER CASES:
        • Product/service details and bills
        • Company/seller information
        • Complaint history and responses
        • Loss calculation with proof
        
        GUIDELINES:
        - Ask 8-12 comprehensive questions (not just 5-6)
        - Questions should be specific to the identified case type
        - Include both mandatory legal requirements and strategic evidence gathering
        - Frame questions for voice input (clear, simple Hindi)
        - Cover all elements needed for a complete case filing
        - Include questions about supporting documents and evidence
        - Ask about limitation periods and urgency
        - Ensure questions help establish legal standing and jurisdiction
        
        Write questions in \(getLanguageName(for: language)) that are optimized for voice responses.
        """
        
        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "system",
                    "content": "You are a legal case filing expert for Indian legal system. You analyze conversations and prepare structured case filing questionnaires."
                ],
                [
                    "role": "user", 
                    "content": prompt
                ]
            ],
            "max_tokens": 800,
            "temperature": 0.2
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📋 Sending case filing analysis request to Azure OpenAI...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureOpenAIError.invalidResponse
        }
        
        print("📡 Azure OpenAI Case Filing Response Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Azure OpenAI Case Filing Error: \(httpResponse.statusCode) - \(errorMessage)")
            throw AzureOpenAIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AzureOpenAIError.invalidResponse
        }
        
        // Parse the response to extract the case filing analysis
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            print("✅ Case filing analysis received from Azure OpenAI")
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        throw AzureOpenAIError.invalidResponse
    }
    
    private func getLanguageName(for code: String) -> String {
        switch code.lowercased() {
        case "hi": return "Hindi"
        case "gu": return "Gujarati"
        case "ur": return "Urdu"
        case "mr": return "Marathi"
        default: return "English"
        }
    }
    
    // MARK: - PDF Content Processing
    
    func extractDetailedCaseInformation(caseRecord: FirebaseManager.CaseRecord) async throws -> DetailedCaseInfo {
        let url = URL(string: "\(endpoint)openai/deployments/\(deploymentName)/chat/completions?api-version=\(apiVersion)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        let prompt = """
        You are an expert legal data extraction AI for Indian legal documents. Extract specific information from the case conversation to fill legal document fields.
        
        CASE INFORMATION:
        Case Type: \(caseRecord.caseType)
        Case Details: \(caseRecord.caseDetails)
        Conversation Summary: \(caseRecord.conversationSummary)
        
        QUESTIONS & RESPONSES:
        \(zip(caseRecord.filingQuestions, caseRecord.userResponses).map { "Q: \($0.0)\nA: \($0.1)" }.joined(separator: "\n\n"))
        
        EXTRACT the following information in EXACT JSON format. If information is not available, use appropriate placeholder text:
        
        {
          "petitioner": {
            "name": "Extract actual name or use 'Name to be filled'",
            "age": "Extract age or use 'Age to be filled'", 
            "occupation": "Extract occupation or use 'Occupation to be filled'",
            "address": "Extract full address or use 'Address to be filled'",
            "phone": "Extract phone number or use 'Phone to be filled'"
          },
          "respondent": {
            "name": "Extract respondent/accused name or use 'Respondent name to be filled'",
            "age": "Extract age or use 'Age to be filled'",
            "occupation": "Extract occupation or use 'Occupation to be filled'", 
            "address": "Extract address or use 'Address to be filled'",
            "relationship": "Extract relationship to petitioner or use 'Relationship to be filled'"
          },
          "incident": {
            "date": "Extract exact date or use 'Date to be filled'",
            "time": "Extract time or use 'Time to be filled'",
            "place": "Extract specific location or use 'Place to be filled'",
            "description": "Extract detailed incident description"
          },
          "amounts": {
            "damages": "Extract monetary amounts claimed or use '0'",
            "expenses": "Extract expenses incurred or use '0'"
          },
          "witnesses": ["Extract witness names or use empty array"],
          "urgentFactors": ["Extract urgency reasons or use standard reasons"]
        }
        
        IMPORTANT: 
        - Extract real information from conversation when available
        - Use professional placeholder text when information is missing
        - Ensure JSON is valid and properly formatted
        - Don't include explanations, only the JSON response
        """
        
        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "system",
                    "content": "You are a legal data extraction expert. Extract case information and respond with only valid JSON."
                ],
                [
                    "role": "user", 
                    "content": prompt
                ]
            ],
            "max_tokens": 800,
            "temperature": 0.1
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📊 Extracting detailed case information from Azure OpenAI...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AzureOpenAIError.invalidResponse
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AzureOpenAIError.invalidResponse
        }
        
        // Parse the JSON response
        guard let jsonData = content.data(using: .utf8),
              let extractedInfo = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AzureOpenAIError.invalidResponse
        }
        
        print("✅ Case information extraction completed")
        return DetailedCaseInfo(from: extractedInfo)
    }
    
    func processContentForLegalPDF(caseRecord: FirebaseManager.CaseRecord) async throws -> String {
        let url = URL(string: "\(endpoint)openai/deployments/\(deploymentName)/chat/completions?api-version=\(apiVersion)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        let prompt = """
        You are an expert legal document drafting specialist for Indian courts with 25+ years of experience. Your task is to transform a voice-recorded case consultation into a structured, professional legal document content suitable for court filing.
        
        CASE INFORMATION:
        Case Number: \(caseRecord.caseNumber)
        Case Type: \(caseRecord.caseType)
        Case Details: \(caseRecord.caseDetails)
        Conversation Summary: \(caseRecord.conversationSummary)
        
        FILING QUESTIONS & RESPONSES:
        \(zip(caseRecord.filingQuestions, caseRecord.userResponses).map { "Q: \($0.0)\nA: \($0.1)" }.joined(separator: "\n\n"))
        
        YOUR EXPERTISE: Transform this information into professional legal document content following Indian legal standards and court requirements.
        
        TASK: Create structured content for a formal legal document that covers:
        
        1. **LEGAL ANALYSIS**: Identify the core legal issues, applicable laws, and jurisdiction requirements
        2. **FACTUAL FOUNDATION**: Organize facts chronologically with legal significance
        3. **CAUSE OF ACTION**: Establish legal grounds and standing
        4. **RELIEF FRAMEWORK**: Define specific legal remedies sought
        5. **PROCEDURAL COMPLIANCE**: Ensure all mandatory elements are included
        
        RESPONSE FORMAT (use exact headers):
        
        CASE SUMMARY:
        [Write a comprehensive legal summary in formal court language, incorporating relevant Indian legal provisions like IPC sections, CPC, CrPC, specific acts. Convert casual conversation into legal terminology while preserving factual accuracy.]
        
        KEY FACTS:
        - [Fact 1: Chronological fact with legal relevance]
        - [Fact 2: Evidence-based factual assertion]
        - [Fact 3: Timeline with specific dates/amounts]
        - [Continue with all relevant facts]
        
        LEGAL ISSUES:
        - [Issue 1: Primary legal violation/right infringement]
        - [Issue 2: Secondary legal considerations]
        - [Issue 3: Procedural or jurisdictional matters]
        - [Continue with all applicable legal issues]
        
        RELIEF SOUGHT:
        - [Relief 1: Primary remedy with legal basis]
        - [Relief 2: Monetary compensation/damages]
        - [Relief 3: Injunctive or declaratory relief]
        - [Relief 4: Costs and other legal remedies]
        
        NEXT STEPS:
        - [Step 1: Immediate legal action required]
        - [Step 2: Evidence collection requirements]
        - [Step 3: Procedural compliance measures]
        - [Step 4: Timeline and limitation considerations]
        
        PROFESSIONAL STANDARDS:
        - Use formal legal language appropriate for Indian courts
        - Reference specific legal provisions where applicable
        - Ensure factual accuracy while enhancing legal presentation
        - Include all elements necessary for a complete case filing
        - Organize content logically for legal document structure
        - Convert voice conversation content into court-appropriate language
        - Maintain professional tone throughout
        
        Convert the informal conversation into formal legal language while preserving all factual content and ensuring completeness for court submission.
        """
        
        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "system",
                    "content": "You are a legal document drafting expert for Indian courts. You transform case conversations into formal legal document content."
                ],
                [
                    "role": "user", 
                    "content": prompt
                ]
            ],
            "max_tokens": 1500,
            "temperature": 0.2
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📄 Sending PDF content processing request to Azure OpenAI...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureOpenAIError.invalidResponse
        }
        
        print("📡 Azure OpenAI PDF Processing Response Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Azure OpenAI PDF Processing Error: \(httpResponse.statusCode) - \(errorMessage)")
            throw AzureOpenAIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AzureOpenAIError.invalidResponse
        }
        
        // Parse the response to extract the processed content
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            print("✅ PDF content processing completed by Azure OpenAI")
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        throw AzureOpenAIError.invalidResponse
    }
    
    private func cleanFormattingSymbols(_ text: String) -> String {
        var cleanedText = text
        
        // Remove common formatting symbols
        cleanedText = cleanedText.replacingOccurrences(of: "**", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "*", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "###", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "##", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "#", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "```", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "`", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "---", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "--", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "___", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "__", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "~~", with: "")
        
        // Remove markdown-style brackets and parentheses formatting
        cleanedText = cleanedText.replacingOccurrences(of: "[", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "]", with: "")
        
        // Clean up multiple spaces and line breaks
        cleanedText = cleanedText.replacingOccurrences(of: "  ", with: " ")
        cleanedText = cleanedText.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        
        return cleanedText
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
    
    // MARK: - Form Data Extraction
    
    func extractFormData(prompt: String) async throws -> ExtractedFormData {
        let url = URL(string: "\(endpoint)openai/deployments/\(deploymentName)/chat/completions?api-version=\(apiVersion)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "system",
                    "content": "You are a precise form data extraction AI. Always respond with valid JSON only."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.1
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("📤 Sending form data extraction request to Azure OpenAI...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AzureOpenAIError.invalidResponse
        }
        
        print("📡 Azure OpenAI Response Code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: String.Encoding.utf8) ?? "Unknown error"
            print("❌ Azure OpenAI Error: \(errorMessage)")
            throw AzureOpenAIError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AzureOpenAIError.invalidResponse
        }
        
        // Parse the response to extract form data JSON
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            
            print("📝 Raw Azure OpenAI response: \(content)")
            
            // Clean the response to extract JSON
            let cleanedContent = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            // Try to parse the JSON response
            if let jsonData = cleanedContent.data(using: String.Encoding.utf8) {
                do {
                    let extractedData = try JSONDecoder().decode(ExtractedFormData.self, from: jsonData)
                    print("✅ Successfully parsed extracted form data")
                    return extractedData
                } catch {
                    print("❌ Failed to parse JSON: \(error)")
                    print("📋 Content was: \(cleanedContent)")
                }
            }
        }
        
        // Return empty data if parsing fails
        return ExtractedFormData(
            fullName: nil,
            email: nil,
            mobileNumber: nil,
            state: nil,
            district: nil,
            userId: nil,
            confidence: "low"
        )
    }
}

// MARK: - Extracted Form Data Model

struct ExtractedFormData: Codable {
    let fullName: String?
    let email: String?
    let mobileNumber: String?
    let state: String?
    let district: String?
    let userId: String?
    let confidence: String?
    
    var hasAnyData: Bool {
        return fullName != nil || email != nil || mobileNumber != nil || 
               state != nil || district != nil || userId != nil
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
    
    func getTranscriptionFromAudio(duration: TimeInterval = 15.0) async throws -> String {
        print("🎤 Starting voice recording for ASR transcription...")
        
        // 1. Request microphone permission
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            throw BhashiniError.microphonePermissionDenied
        }
        
        // 2. Record audio for specified duration
        let audioData = try await recordAudio(duration: duration)
        print("✅ Audio recorded successfully (\(duration) seconds)")
        
        // 3. Use Bhashini ASR (Hindi model) to get transcription
        let transcription = try await performASRTranscription(audioData: audioData)
        
        print("📝 Bhashini ASR transcription: '\(transcription)'")
        return transcription
    }
    
    // New function for tap-to-start/tap-to-stop recording
    func startRecording() async throws {
        print("🎤 Starting tap-to-stop voice recording...")
        
        // 1. Request microphone permission
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            throw BhashiniError.microphonePermissionDenied
        }
        
        // 2. Start recording (no duration limit)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("tap_recording.wav")
        
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
            let recordingStarted = audioRecorder?.record() ?? false
            
            if recordingStarted {
                print("🔴 Recording started successfully - tap again to stop...")
                print("📊 Recorder state: isRecording=\(audioRecorder?.isRecording ?? false)")
            } else {
                print("❌ Failed to start recording")
                throw BhashiniError.audioRecordingFailed
            }
        } catch {
            print("❌ Audio recorder initialization failed: \(error)")
            throw BhashiniError.audioRecordingFailed
        }
    }
    
    func stopRecordingAndTranscribe() async throws -> String {
        print("⏹️ Stopping recording and starting transcription...")
        
        guard let recorder = audioRecorder else {
            print("❌ No audio recorder found")
            throw BhashiniError.audioRecordingFailed
        }
        
        guard recorder.isRecording else {
            print("❌ Recorder is not recording (state: \(recorder.isRecording))")
            throw BhashiniError.audioRecordingFailed
        }
        
        print("✅ Recorder is active, stopping now...")
        
        // Stop recording
        recorder.stop()
        
        // Read recorded audio data
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("tap_recording.wav")
        
        do {
            let audioData = try Data(contentsOf: audioURL)
            
            // Clean up audio file
            try? FileManager.default.removeItem(at: audioURL)
            
            // Get transcription
            let transcription = try await performASRTranscription(audioData: audioData)
            
            print("📝 Bhashini ASR transcription: '\(transcription)'")
            return transcription
            
        } catch {
            throw BhashiniError.audioRecordingFailed
        }
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

// MARK: - Detailed Case Information Models

struct DetailedCaseInfo {
    let petitioner: PartyInfo
    let respondent: PartyInfo
    let incident: IncidentInfo
    let amounts: AmountInfo
    let witnesses: [String]
    let urgentFactors: [String]
    
    init(from json: [String: Any]) {
        if let petitionerData = json["petitioner"] as? [String: Any] {
            self.petitioner = PartyInfo(from: petitionerData)
        } else {
            self.petitioner = PartyInfo()
        }
        
        if let respondentData = json["respondent"] as? [String: Any] {
            self.respondent = PartyInfo(from: respondentData)
        } else {
            self.respondent = PartyInfo()
        }
        
        if let incidentData = json["incident"] as? [String: Any] {
            self.incident = IncidentInfo(from: incidentData)
        } else {
            self.incident = IncidentInfo()
        }
        
        if let amountsData = json["amounts"] as? [String: Any] {
            self.amounts = AmountInfo(from: amountsData)
        } else {
            self.amounts = AmountInfo()
        }
        
        self.witnesses = json["witnesses"] as? [String] ?? []
        self.urgentFactors = json["urgentFactors"] as? [String] ?? []
    }
}

struct PartyInfo {
    let name: String
    let age: String
    let occupation: String
    let address: String
    let phone: String
    let relationship: String
    
    init(from json: [String: Any] = [:]) {
        self.name = json["name"] as? String ?? "Name to be filled"
        self.age = json["age"] as? String ?? "Age to be filled"
        self.occupation = json["occupation"] as? String ?? "Occupation to be filled"
        self.address = json["address"] as? String ?? "Address to be filled"
        self.phone = json["phone"] as? String ?? "Phone to be filled"
        self.relationship = json["relationship"] as? String ?? "Relationship to be filled"
    }
}

struct IncidentInfo {
    let date: String
    let time: String
    let place: String
    let description: String
    
    init(from json: [String: Any] = [:]) {
        self.date = json["date"] as? String ?? "Date to be filled"
        self.time = json["time"] as? String ?? "Time to be filled"
        self.place = json["place"] as? String ?? "Place to be filled"
        self.description = json["description"] as? String ?? "Detailed incident description to be filled"
    }
}

struct AmountInfo {
    let damages: String
    let expenses: String
    
    init(from json: [String: Any] = [:]) {
        self.damages = json["damages"] as? String ?? "0"
        self.expenses = json["expenses"] as? String ?? "0"
    }
} 
