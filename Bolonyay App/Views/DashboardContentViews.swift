import SwiftUI
import UIKit

// MARK: - Case Status Types
enum CaseStatus: String, CaseIterable {
    case drafts = "Drafts"
    case pendingAcceptance = "Pending Acceptance"
    case notAccepted = "Not Accepted"
    case deficitCourtFees = "Deficit Court Fees"
    case pendingScrutiny = "Pending Scrutiny"
    case defectiveCases = "Defective Cases"
    case eFiledCases = "E-Filed Cases"
    
    var icon: String {
        switch self {
        case .drafts: return "doc.text"
        case .pendingAcceptance: return "clock.arrow.circlepath"
        case .notAccepted: return "xmark.circle"
        case .deficitCourtFees: return "creditcard.trianglebadge.exclamationmark"
        case .pendingScrutiny: return "eye.circle"
        case .defectiveCases: return "exclamationmark.triangle"
        case .eFiledCases: return "checkmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .drafts: return .gray
        case .pendingAcceptance: return .orange
        case .notAccepted: return .red
        case .deficitCourtFees: return .purple
        case .pendingScrutiny: return .blue
        case .defectiveCases: return .yellow
        case .eFiledCases: return .green
        }
    }
    
    var description: String {
        switch self {
        case .drafts: return "Saved drafts"
        case .pendingAcceptance: return "Cases filed but pending technical acceptance"
        case .notAccepted: return "Cases failed technical checking"
        case .deficitCourtFees: return "Cases with insufficient court fees"
        case .pendingScrutiny: return "Cases pending scrutiny check by court registry"
        case .defectiveCases: return "Defective cases after registry checking"
        case .eFiledCases: return "Successfully filed cases"
        }
    }
    
    var titleKey: String {
        switch self {
        case .drafts: return "drafts"
        case .pendingAcceptance: return "pending_acceptance"
        case .notAccepted: return "not_accepted"
        case .deficitCourtFees: return "deficit_court_fees"
        case .pendingScrutiny: return "pending_scrutiny"
        case .defectiveCases: return "defective_cases"
        case .eFiledCases: return "e_filed_cases"
        }
    }
    
    var descriptionKey: String {
        switch self {
        case .drafts: return "saved_drafts"
        case .pendingAcceptance: return "cases_pending_acceptance"
        case .notAccepted: return "cases_failed_checking"
        case .deficitCourtFees: return "insufficient_court_fees"
        case .pendingScrutiny: return "cases_pending_scrutiny"
        case .defectiveCases: return "defective_after_checking"
        case .eFiledCases: return "successfully_filed"
        }
    }
}

enum MyCasesTab: String, CaseIterable {
    case eFiledCases = "E-Filed Cases"
    case eFiledDocuments = "E-Filed Documents"
    case deficitCourtFees = "Deficit Court Fees"
    case rejectedCases = "Rejected Cases"
    case unprocessedCases = "Unprocessed E-Filed Cases"
    
    var icon: String {
        switch self {
        case .eFiledCases: return "folder.fill"
        case .eFiledDocuments: return "doc.fill"
        case .deficitCourtFees: return "creditcard.fill"
        case .rejectedCases: return "trash.fill"
        case .unprocessedCases: return "hourglass"
        }
    }
}

// MARK: - Dashboard Home Content
struct DashboardHomeContent: View {
    let isAnimated: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedMyCasesTab: MyCasesTab = .eFiledCases
    
    var body: some View {
        VStack(spacing: 32) {
            // E-Filing Status Section
            VStack(spacing: 20) {
                SectionHeader(
                    title: localizationManager.text("e_filing_status"),
                    subtitle: localizationManager.text("track_progress"),
                    animationDelay: 0.5,
                    isAnimated: isAnimated
                )
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(Array(CaseStatus.allCases.enumerated()), id: \.element) { index, status in
                        StatusCard(
                            status: status,
                            count: Int.random(in: 0...10), // Sample data
                            animationDelay: 0.6 + (Double(index) * 0.1),
                            isAnimated: isAnimated
                        )
                    }
                }
            }
            
            // My Cases Section
            VStack(spacing: 20) {
                SectionHeader(
                    title: localizationManager.text("my_cases"),
                    subtitle: localizationManager.text("manage_cases"),
                    animationDelay: 1.4,
                    isAnimated: isAnimated
                )
                
                // Tab Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(MyCasesTab.allCases.enumerated()), id: \.element) { index, tab in
                            MyCasesTabButton(
                                tab: tab,
                                isSelected: selectedMyCasesTab == tab,
                                animationDelay: 1.5 + (Double(index) * 0.1),
                                isAnimated: isAnimated
                            ) {
                                withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                    selectedMyCasesTab = tab
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                // Cases Content
                MyCasesContent(
                    selectedTab: selectedMyCasesTab,
                    animationDelay: 2.0,
                    isAnimated: isAnimated
                )
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let subtitle: String
    let animationDelay: Double
    let isAnimated: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
        }
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(x: isAnimated ? 0 : -30)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay), value: isAnimated)
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let status: CaseStatus
    let count: Int
    let animationDelay: Double
    let isAnimated: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: status.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(status.color)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.3)
            .opacity(isAnimated ? 1.0 : 0.0)
            .animation(.spring(duration: 0.8, bounce: 0.5).delay(animationDelay + 0.1), value: isAnimated)
            
            // Content
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(localizationManager.text(status.titleKey))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(localizationManager.text(status.descriptionKey))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(status.color.opacity(0.3), lineWidth: 0.5)
        )
        .scaleEffect(isAnimated ? 1.0 : 0.95)
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(y: isAnimated ? 0 : 20)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay), value: isAnimated)
    }
}

// MARK: - My Cases Tab Button
struct MyCasesTabButton: View {
    let tab: MyCasesTab
    let isSelected: Bool
    let animationDelay: Double
    let isAnimated: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                    .stroke(Color.white.opacity(isSelected ? 0.3 : 0.2), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(color: isSelected ? .white.opacity(0.2) : .clear, radius: isSelected ? 8 : 0)
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(y: isAnimated ? 0 : 10)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay), value: isAnimated)
    }
}

// MARK: - My Cases Content
struct MyCasesContent: View {
    let selectedTab: MyCasesTab
    let animationDelay: Double
    let isAnimated: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Content based on selected tab
            EmptyStateView(
                icon: selectedTab.icon,
                title: "No \(selectedTab.rawValue)",
                message: "You haven't filed any cases yet. Click 'New Case' to get started.",
                animationDelay: animationDelay,
                isAnimated: isAnimated
            )
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isAnimated ? 1.0 : 0.95)
        .opacity(isAnimated ? 1.0 : 0.0)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay), value: isAnimated)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let animationDelay: Double
    let isAnimated: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .scaleEffect(isAnimated ? 1.0 : 0.3)
            .opacity(isAnimated ? 1.0 : 0.0)
            .animation(.spring(duration: 0.8, bounce: 0.5).delay(animationDelay + 0.1), value: isAnimated)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .opacity(isAnimated ? 1.0 : 0.0)
            .offset(y: isAnimated ? 0 : 20)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay + 0.2), value: isAnimated)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
    }
}

// MARK: - New Case Content
struct NewCaseContent: View {
    let isAnimated: Bool
    @StateObject private var voiceCaseManager = VoiceCaseFilingManager()
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 24) {
            SectionHeader(
                title: localizationManager.text("new_case"),
                subtitle: "Voice-driven case filing system",
                animationDelay: 0.5,
                isAnimated: isAnimated
            )
            
            VoiceCaseFilingView(manager: voiceCaseManager)
                .opacity(isAnimated ? 1.0 : 0.0)
                .scaleEffect(isAnimated ? 1.0 : 0.95)
                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.7), value: isAnimated)
        }
    }
}

// MARK: - Voice Case Filing Manager
class VoiceCaseFilingManager: ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var transcription = ""
    @Published var caseAnalysis = ""
    @Published var errorMessage: String?
    @Published var recordingState: RecordingState = .idle
    @Published var audioLevel: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0.0
    @Published var conversationHistory: [ConversationMessage] = []
    @Published var currentTranscription = ""
    @Published var caseFilingState: CaseFilingState = .notStarted
    @Published var caseType = ""
    @Published var caseDetails = ""
    @Published var filingQuestions: [String] = []
    @Published var userResponses: [String] = []
    @Published var isFilingCase = false
    @Published var sessionId = UUID().uuidString
    
    private let localizationManager = LocalizationManager.shared
    private let firebaseManager = FirebaseManager.shared
    private let bhashiniManager = BhashiniManager()
    private let azureOpenAIManager = AzureOpenAIManager()
    
    private var recordingTimer: Timer?
    private var audioLevelTimer: Timer?
    private let maxRecordingDuration: TimeInterval = 15.0
    
    enum RecordingState {
        case idle
        case recording
        case processing
        case completed
        case error
    }
        
    enum CaseFilingState {
        case notStarted
        case analyzing
        case questionsReady
        case collectingInfo
        case readyToFile
        case filed
        case error
    }
    
    struct ConversationMessage {
        let id = UUID()
        let type: MessageType
        let content: String
        let timestamp: Date
        
        enum MessageType {
            case userTranscription
            case aiResponse
        }
    }
    
    // MARK: - Voice Recording Flow
    
    func startVoiceRecording() {
        print("🎤 Starting voice recording...")
        
        DispatchQueue.main.async {
            self.recordingState = .recording
            self.isRecording = true
            self.errorMessage = nil
            self.currentTranscription = ""
            self.recordingDuration = 0.0
        }
        
        // Start recording timer with auto-stop at max duration
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.recordingDuration += 0.1
            
            // Auto-stop at max duration
            if self.recordingDuration >= self.maxRecordingDuration {
                self.stopVoiceRecording()
            }
        }
        
        // Start audio level monitoring
        startAudioLevelMonitoring()
        
        // Start actual recording in background
        Task {
            await performVoiceRecording()
        }
    }
    
    func stopVoiceRecording() {
        print("⏹️ Stopping voice recording...")
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.recordingState = .processing
        }
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        stopAudioLevelMonitoring()
    }
    
    private func performVoiceRecording() async {
        do {
            // Wait for recording to complete
            while isRecording {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Step 1: Get transcription from Bhashini ASR
            print("📝 Getting transcription from Bhashini ASR (Language: \(localizationManager.currentLanguage))...")
            
            DispatchQueue.main.async {
                self.recordingState = .processing
                self.isProcessing = true
            }
            
            let transcriptionText = try await bhashiniManager.getTranscriptionFromAudio()
            
            DispatchQueue.main.async {
                self.currentTranscription = transcriptionText
                print("✅ Transcription received: '\(transcriptionText)'")
                
                // Add user message to conversation history
                let userMessage = ConversationMessage(
                    type: .userTranscription,
                    content: transcriptionText,
                    timestamp: Date()
                )
                self.conversationHistory.append(userMessage)
            }
            
            // Step 2: Send to Azure OpenAI for case analysis with conversation context
            await analyzeCaseWithAI(transcription: transcriptionText)
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.recordingState = .error
                self.isProcessing = false
                print("❌ Voice recording failed: \(error)")
            }
        }
    }
    
    private func analyzeCaseWithAI(transcription: String) async {
        do {
            print("🤖 Analyzing with Azure OpenAI (conversation context: \(conversationHistory.count) messages)...")
            
            // Build conversation context
            let conversationContext = buildConversationContext()
            let fullTranscription = conversationContext.isEmpty ? transcription : "\(conversationContext)\n\nLatest message: \(transcription)"
            
            let analysis = try await azureOpenAIManager.analyzeLegalCase(transcription: fullTranscription, language: localizationManager.currentLanguage)
            
            DispatchQueue.main.async {
                self.caseAnalysis = analysis
                self.recordingState = .completed
                self.isProcessing = false
                print("✅ Legal analysis completed")
                
                // Add AI response to conversation history
                let aiMessage = ConversationMessage(
                    type: .aiResponse,
                    content: analysis,
                    timestamp: Date()
                )
                self.conversationHistory.append(aiMessage)
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to analyze case: \(error.localizedDescription)"
                self.recordingState = .error
                self.isProcessing = false
                print("❌ Case analysis failed: \(error)")
            }
        }
    }
    
    private func buildConversationContext() -> String {
        guard !conversationHistory.isEmpty else { return "" }
        
        var context = "Previous conversation:\n"
        
        // Include last few messages for context (limit to avoid token overflow)
        let recentMessages = Array(conversationHistory.suffix(6))
        
        for message in recentMessages {
            switch message.type {
            case .userTranscription:
                context += "User: \(message.content)\n"
            case .aiResponse:
                context += "Legal Expert: \(message.content)\n"
            }
        }
        
        return context
    }
    
    // MARK: - Case Filing
    
    func startCaseFiling() {
        print("📋 Starting case filing process...")
        
        DispatchQueue.main.async {
            self.caseFilingState = .analyzing
            self.isFilingCase = true
            self.errorMessage = nil
        }
        
        Task {
            await analyzeCaseForFiling()
        }
    }
    
    private func analyzeCaseForFiling() async {
        do {
            print("🔍 Analyzing conversation for case filing...")
            
            // Build full conversation context
            let conversationSummary = buildFullConversationSummary()
            
            let caseAnalysis = try await azureOpenAIManager.analyzeCaseForFiling(
                conversationSummary: conversationSummary,
                language: localizationManager.currentLanguage
            )
            
            DispatchQueue.main.async {
                self.parseCaseAnalysis(caseAnalysis)
                self.caseFilingState = .questionsReady
                print("✅ Case analysis for filing completed")
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to analyze case for filing: \(error.localizedDescription)"
                self.caseFilingState = .error
                print("❌ Case filing analysis failed: \(error)")
            }
        }
    }
    
    private func buildFullConversationSummary() -> String {
        var summary = "Complete conversation summary:\n\n"
        
        for message in conversationHistory {
            switch message.type {
            case .userTranscription:
                summary += "User said: \(message.content)\n\n"
            case .aiResponse:
                summary += "Legal Expert responded: \(message.content)\n\n"
            }
        }
        
        return summary
    }
    
    private func parseCaseAnalysis(_ analysis: String) {
        // Parse the AI response to extract case type, details, and questions
        let lines = analysis.components(separatedBy: .newlines)
        var currentSection = ""
        var questions: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.contains("CASE TYPE:") {
                caseType = trimmedLine.replacingOccurrences(of: "CASE TYPE:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.contains("CASE DETAILS:") {
                currentSection = "details"
            } else if trimmedLine.contains("QUESTIONS:") {
                currentSection = "questions"
            } else if !trimmedLine.isEmpty {
                if currentSection == "details" && caseDetails.isEmpty {
                    caseDetails = trimmedLine
                } else if currentSection == "questions" && trimmedLine.hasPrefix("-") {
                    questions.append(trimmedLine.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
        
        filingQuestions = questions
        userResponses = Array(repeating: "", count: questions.count)
    }
    
    func submitCaseResponse(_ response: String, for questionIndex: Int) {
        guard questionIndex < userResponses.count else { return }
        
        DispatchQueue.main.async {
            self.userResponses[questionIndex] = response
            
            // Check if all questions are answered
            let allAnswered = self.userResponses.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            if allAnswered {
                self.caseFilingState = .readyToFile
            }
        }
    }
    
    func finalizeCase() {
        print("✅ Finalizing case filing...")
        
        DispatchQueue.main.async {
            self.caseFilingState = .filed
        }
        
        // Save to Firebase
        Task {
            await saveCaseToFirebase()
        }
    }
    
    private func saveCaseToFirebase() async {
        do {
            // Ensure user exists before saving case
            await ensureUserExists()
            
            // Generate case number
            let caseNumber = generateCaseNumber()
            
            // Build conversation summary
            let conversationSummary = buildFullConversationSummary()
            
            // Create session messages for Firebase
            let sessionMessages = conversationHistory.map { message in
                FirebaseManager.ConversationSession.SessionMessage(
                    id: UUID().uuidString,
                    type: message.type == .userTranscription ? .userTranscription : .aiResponse,
                    content: message.content,
                    timestamp: message.timestamp,
                    language: localizationManager.currentLanguage
                )
            }
            
            // Save conversation session first
            let session = try await firebaseManager.saveConversationSession(
                messages: sessionMessages,
                language: localizationManager.currentLanguage,
                azureSessionId: sessionId,
                caseNumber: caseNumber
            )
            
            // Save case record
            let caseRecord = try await firebaseManager.saveCase(
                caseNumber: caseNumber,
                caseType: caseType,
                caseDetails: caseDetails,
                conversationSummary: conversationSummary,
                filingQuestions: filingQuestions,
                userResponses: userResponses,
                sessionId: session.id,
                azureSessionId: sessionId,
                language: localizationManager.currentLanguage
            )
            
            print("✅ Case successfully saved to Firebase:")
            print("   Case Number: \(caseRecord.caseNumber)")
            print("   Case ID: \(caseRecord.id)")
            print("   Session ID: \(session.id)")
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to save case to Firebase: \(error.localizedDescription)"
                self.caseFilingState = .error
                print("❌ Failed to save case to Firebase: \(error)")
            }
        }
    }
    
    private func generateCaseNumber() -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        let randomNumber = Int.random(in: 100000...999999)
        return "BN\(currentYear)\(randomNumber)"
    }
    
    private func ensureUserExists() async {
        // Check if user already exists
        if firebaseManager.getCurrentUser() != nil {
            return // User already exists
        }
        
        // Create a user for case filing
        do {
            let deviceName = UIDevice.current.name
            let userName = deviceName.isEmpty ? "BoloNyay User" : deviceName
            
            let user = try await firebaseManager.createUser(
                email: nil,
                name: userName,
                userType: .petitioner,
                language: localizationManager.currentLanguage
            )
            print("✅ Auto-created user for case filing: \(user.name)")
        } catch {
            print("❌ Failed to create user: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create user account: \(error.localizedDescription)"
                self.caseFilingState = .error
            }
        }
    }
    
    // MARK: - Audio Level Monitoring
    
    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Simulate audio level for visual feedback
            self.audioLevel = Float.random(in: 0.1...0.9)
        }
    }
    
    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        audioLevel = 0.0
    }
    
    // MARK: - Conversation Management
    
    func continueConversation() {
        print("💬 Continuing conversation...")
        recordingState = .idle
        errorMessage = nil
        // Keep conversation history and case analysis
        // Reset only recording-specific states
        isRecording = false
        isProcessing = false
        currentTranscription = ""
        recordingDuration = 0.0
        audioLevel = 0.0
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        stopAudioLevelMonitoring()
    }
    
    func reset() {
        print("🔄 Resetting conversation...")
        recordingState = .idle
        isRecording = false
        isProcessing = false
        currentTranscription = ""
        caseAnalysis = ""
        conversationHistory.removeAll()
        errorMessage = nil
        recordingDuration = 0.0
        audioLevel = 0.0
        
        // Reset case filing state
        caseFilingState = .notStarted
        caseType = ""
        caseDetails = ""
        filingQuestions.removeAll()
        userResponses.removeAll()
        isFilingCase = false
        sessionId = UUID().uuidString
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        stopAudioLevelMonitoring()
    }
}

// MARK: - Voice Case Filing View
struct VoiceCaseFilingView: View {
    @ObservedObject var manager: VoiceCaseFilingManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Voice Recording Interface
            VStack(spacing: 20) {
                // Recording Button with Visual Feedback
                VStack(spacing: 16) {
                    ZStack {
                        // Outer pulse ring
                        if manager.isRecording {
                            Circle()
                                .stroke(Color.red.opacity(0.3), lineWidth: 4)
                                .frame(width: 140, height: 140)
                                .scaleEffect(manager.isRecording ? 1.2 : 1.0)
                                .opacity(manager.isRecording ? 0.0 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: manager.isRecording)
                        }
                        
                        // Main recording button
                        Button(action: {
                            if manager.isRecording {
                                manager.stopVoiceRecording()
                            } else if manager.recordingState == .completed {
                                manager.continueConversation()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    manager.startVoiceRecording()
                                }
                            } else {
                                manager.startVoiceRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(manager.isRecording ? Color.red : Color.blue)
                                    .frame(width: 100, height: 100)
                                    .shadow(color: (manager.isRecording ? Color.red : Color.blue).opacity(0.3), radius: 10, x: 0, y: 0)
                                
                                // Audio level visualization
                                if manager.isRecording {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 100 * CGFloat(manager.audioLevel), height: 100 * CGFloat(manager.audioLevel))
                                        .animation(.easeInOut(duration: 0.1), value: manager.audioLevel)
                                }
                                
                                Image(systemName: manager.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .scaleEffect(manager.isRecording ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: manager.isRecording)
                            }
                        }
                        .disabled(manager.isProcessing)
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // Recording State Text
                    VStack(spacing: 4) {
                        Text(getRecordingStateText())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if manager.isRecording {
                            Text(formatDuration(manager.recordingDuration))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .monospacedDigit()
                        }
                    }
                }
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Conversation History Display
            if !manager.conversationHistory.isEmpty && manager.conversationHistory.count > 2 {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.purple)
                        
                        Text("Conversation History")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(manager.conversationHistory.count/2) exchanges")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            // Show only the most recent exchanges (excluding the current one)
                            let historyToShow = Array(manager.conversationHistory.dropLast(2).suffix(4))
                            
                            ForEach(historyToShow, id: \.id) { message in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: message.type == .userTranscription ? "person.fill" : "brain.head.profile")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(message.type == .userTranscription ? .blue : .green)
                                        .frame(width: 20)
                                    
                                    Text(message.content)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(3)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.02))
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            // Current Transcription Display
            if !manager.currentTranscription.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "text.quote")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("Latest Message")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    Text(manager.currentTranscription)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.03))
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            // AI Analysis Display
            if !manager.caseAnalysis.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("Legal Expert Response")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    Text(manager.caseAnalysis)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.03))
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            // Error Display
            if let errorMessage = manager.errorMessage {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                        
                        Text("Error")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.03))
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            // Processing Indicator
            if manager.isProcessing {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                    
                    Text("Understanding your case and preparing guidance...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 20)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            // Action Buttons
            if manager.recordingState != .idle && !manager.isFilingCase {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Continue/Record Again Button
                        if manager.recordingState == .completed {
                            Button(action: {
                                manager.continueConversation()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    manager.startVoiceRecording()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 14, weight: .medium))
                                    
                                    Text("Continue Talking")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.2))
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        // Reset Button
                        Button(action: {
                            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                                manager.reset()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text("New Case")
                                    .font(.system(size: 16, weight: .semibold))
                            }
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
                    }
                    
                    // File Case Button (Premium Feature)
                    if manager.recordingState == .completed && !manager.conversationHistory.isEmpty {
                        Button(action: {
                            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                                manager.startCaseFiling()
                            }
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.orange)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("File This Case")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.orange)
                                    
                                    Text("Convert conversation to legal filing")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.orange.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.orange.opacity(0.05))
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                                    .shadow(color: Color.orange.opacity(0.2), radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            // Case Filing Interface
            if manager.isFilingCase {
                CaseFilingView(manager: manager)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0.3), value: manager.recordingState)
    }
    
    private func getRecordingStateText() -> String {
        switch manager.recordingState {
        case .idle:
            if manager.conversationHistory.isEmpty {
                return "Tap to record your case (15 seconds)"
            } else {
                return "Tap to continue conversation (15 seconds)"
            }
        case .recording:
            return "Recording... Speak clearly (15 sec max)"
        case .processing:
            return "Understanding your message..."
        case .completed:
            return "Tap to continue conversation"
        case .error:
            return "Error occurred"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Case Filing View
struct CaseFilingView: View {
    @ObservedObject var manager: VoiceCaseFilingManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var currentQuestionIndex = 0
    @State private var answerText = ""
    @State private var isAnsweringVoice = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Case Filing")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Let's prepare your legal case")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                            manager.isFilingCase = false
                            manager.caseFilingState = .notStarted
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Progress Bar
                if manager.caseFilingState == .questionsReady || manager.caseFilingState == .collectingInfo {
                    ProgressView(value: Double(manager.userResponses.filter { !$0.isEmpty }.count), total: Double(manager.filingQuestions.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .scaleEffect(y: 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.05))
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            
            // Content based on state
            Group {
                switch manager.caseFilingState {
                case .analyzing:
                    AnalyzingView()
                    
                case .questionsReady, .collectingInfo:
                    QuestionnaireView(
                        manager: manager,
                        currentQuestionIndex: $currentQuestionIndex,
                        answerText: $answerText,
                        isAnsweringVoice: $isAnsweringVoice
                    )
                    
                case .readyToFile:
                    ReadyToFileView(manager: manager)
                    
                case .filed:
                    CaseFiledView(manager: manager)
                    
                case .error:
                    ErrorView(message: manager.errorMessage ?? "Unknown error")
                    
                default:
                    EmptyView()
                }
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0.3), value: manager.caseFilingState)
    }
}

// MARK: - Case Filing Sub-Views

struct AnalyzingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("Analyzing Your Case")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Our AI is reviewing your conversation to identify case type and prepare filing questions...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

struct QuestionnaireView: View {
    @ObservedObject var manager: VoiceCaseFilingManager
    @Binding var currentQuestionIndex: Int
    @Binding var answerText: String
    @Binding var isAnsweringVoice: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Case Summary
            if !manager.caseType.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("Case Identified")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(manager.caseType)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.blue)
                        
                        if !manager.caseDetails.isEmpty {
                            Text(manager.caseDetails)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.05))
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            // Questions Section
            if !manager.filingQuestions.isEmpty {
                VStack(spacing: 16) {
                    HStack {
                        Text("Additional Information Required")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(manager.userResponses.filter { !$0.isEmpty }.count)/\(manager.filingQuestions.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    // Question Cards
                    ForEach(Array(manager.filingQuestions.enumerated()), id: \.offset) { index, question in
                        QuestionCard(
                            question: question,
                            answer: index < manager.userResponses.count ? manager.userResponses[index] : "",
                            isAnswered: index < manager.userResponses.count && !manager.userResponses[index].isEmpty,
                            questionNumber: index + 1,
                            onAnswerSubmit: { answer in
                                manager.submitCaseResponse(answer, for: index)
                            }
                        )
                    }
                }
            }
            
            // Action Buttons
            if manager.caseFilingState == .readyToFile {
                Button(action: {
                    manager.finalizeCase()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                        
                        Text("File Case Now")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.green)
                            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
}

struct QuestionCard: View {
    let question: String
    let answer: String
    let isAnswered: Bool
    let questionNumber: Int
    let onAnswerSubmit: (String) -> Void
    
    @State private var textAnswer = ""
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question Header
            HStack {
                ZStack {
                    Circle()
                        .fill(isAnswered ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    if isAnswered {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text("\(questionNumber)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
                
                Text(question)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(isExpanded ? nil : 2)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Answer Section
            if isExpanded || !answer.isEmpty {
                VStack(spacing: 12) {
                    if !answer.isEmpty {
                        HStack {
                            Text("Your Answer:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.green)
                            
                            Spacer()
                        }
                        
                        Text(answer)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.05))
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    } else if isExpanded {
                        VStack(spacing: 8) {
                            TextField("Type your answer...", text: $textAnswer)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 14))
                            
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    if !textAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        onAnswerSubmit(textAnswer)
                                        textAnswer = ""
                                        withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                                            isExpanded = false
                                        }
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                        
                                        Text("Submit")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange)
                                    )
                                }
                                .disabled(textAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .stroke(isAnswered ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            textAnswer = answer
        }
    }
}

struct ReadyToFileView: View {
    @ObservedObject var manager: VoiceCaseFilingManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("Ready to File!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("All required information has been collected. Your case is ready for filing.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Case Summary
            VStack(alignment: .leading, spacing: 16) {
                Text("Case Summary")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Type:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(manager.caseType)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(manager.caseDetails)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Responses: \(manager.userResponses.filter { !$0.isEmpty }.count) completed")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
            
            // File Button
            Button(action: {
                manager.finalizeCase()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("File Case Now")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.green)
                        .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CaseFiledView: View {
    @ObservedObject var manager: VoiceCaseFilingManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("Case Filed Successfully!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.green)
                
                Text("Your case has been submitted to the legal system. You will receive updates on the progress.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                HStack {
                    Text("Case ID:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(generateDisplayCaseNumber())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Filed on:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.05))
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func generateDisplayCaseNumber() -> String {
        if !manager.conversationHistory.isEmpty {
            let currentYear = Calendar.current.component(.year, from: Date())
            let randomNumber = Int.random(in: 100000...999999)
            return "BN\(currentYear)\(randomNumber)"
        }
        return "BN2024000000"
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 8) {
                Text("Error")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.05))
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Documents Content
struct DocumentsContent: View {
    let isAnimated: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            SectionHeader(
                title: "Documents",
                subtitle: "File miscellaneous documents",
                animationDelay: 0.5,
                isAnimated: isAnimated
            )
            
            ComingSoonView(
                icon: "doc.text.fill",
                title: "Document Filing",
                message: "Document filing functionality will be available soon. You'll be able to file affidavits, applications, and other miscellaneous documents.",
                animationDelay: 0.7,
                isAnimated: isAnimated
            )
        }
    }
}

// MARK: - Reports Content
struct ReportsContent: View {
    let isAnimated: Bool
    
    var body: some View {
        ReportsView()
    }
}

// MARK: - Help Content
struct HelpContent: View {
    let isAnimated: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            SectionHeader(
                title: "Help & Support",
                subtitle: "Get assistance and guidance",
                animationDelay: 0.5,
                isAnimated: isAnimated
            )
            
            ComingSoonView(
                icon: "questionmark.circle.fill",
                title: "Help Center",
                message: "Help and support functionality will be available soon. You'll find user guides, FAQs, and contact support.",
                animationDelay: 0.7,
                isAnimated: isAnimated
            )
        }
    }
}

// MARK: - Coming Soon View
struct ComingSoonView: View {
    let icon: String
    let title: String
    let message: String
    let animationDelay: Double
    let isAnimated: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(Color.blue.opacity(0.05))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.blue)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.3)
            .opacity(isAnimated ? 1.0 : 0.0)
            .animation(.spring(duration: 0.8, bounce: 0.5).delay(animationDelay), value: isAnimated)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                
                Text("Coming Soon")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.top, 8)
            }
            .opacity(isAnimated ? 1.0 : 0.0)
            .offset(y: isAnimated ? 0 : 30)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay + 0.2), value: isAnimated)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isAnimated ? 1.0 : 0.95)
        .opacity(isAnimated ? 1.0 : 0.0)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay + 0.1), value: isAnimated)
    }
} 