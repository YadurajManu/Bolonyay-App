import SwiftUI
import UIKit
import MessageUI

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
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var pdfManager = PDFGenerationManager.shared
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var cases: [FirebaseManager.CaseRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var generatedPDFURL: URL?
    @State private var showPDFPreview = false
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                LoadingCasesView(animationDelay: animationDelay)
            } else if cases.isEmpty {
                // Show empty state only when no cases exist
                EmptyStateView(
                    icon: selectedTab.icon,
                    title: localizationManager.text("no_filed_cases"),
                    message: localizationManager.text("file_first_case_message"),
                    animationDelay: animationDelay,
                    isAnimated: isAnimated
                )
            } else {
                // Show actual cases
                LazyVStack(spacing: 12) {
                    ForEach(Array(filteredCases.enumerated()), id: \.element.id) { index, caseRecord in
                        CompactCaseCard(
                            caseRecord: caseRecord,
                            localizationManager: localizationManager,
                            animationDelay: animationDelay + Double(index) * 0.1,
                            isAnimated: isAnimated
                        )
                    }
                }
            }
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
        .onAppear {
            Task {
                await loadCases()
            }
            setupPDFGenerationObserver()
        }
        .refreshable {
            await loadCases()
        }
        .alert(localizationManager.text("error"), isPresented: .constant(errorMessage != nil)) {
            Button(localizationManager.text("ok")) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showPDFPreview) {
            if let pdfURL = generatedPDFURL {
                PDFPreviewView(pdfURL: pdfURL)
            }
        }
    }
    
    private var filteredCases: [FirebaseManager.CaseRecord] {
        switch selectedTab {
        case .eFiledCases:
            return cases.filter { $0.status == .filed || $0.status == .completed }
        case .eFiledDocuments:
            return cases // For now, show all cases - can be filtered later for document-specific cases
        case .deficitCourtFees:
            return cases.filter { $0.status == .pending }
        case .rejectedCases:
            return cases.filter { $0.status == .rejected }
        case .unprocessedCases:
            return cases.filter { $0.status == .underReview }
        }
    }
    
    private func loadCases() async {
        // Ensure user exists before loading cases
        await ensureUserExists()
        
        isLoading = true
        
        do {
            let fetchedCases = try await firebaseManager.getUserCases()
            DispatchQueue.main.async {
                self.cases = fetchedCases
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load cases: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func ensureUserExists() async {
        if firebaseManager.getCurrentUser() != nil {
            return
        }
        
        do {
            let deviceName = UIDevice.current.name
            let userName = deviceName.isEmpty ? "BoloNyay User" : deviceName
            
            let user = try await firebaseManager.createUser(
                email: nil,
                name: userName,
                userType: .petitioner,
                language: localizationManager.currentLanguage
            )
            print("✅ Auto-created user for cases: \(user.name)")
        } catch {
            print("❌ Failed to create user for cases: \(error)")
        }
    }
    
    private func setupPDFGenerationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GeneratePDFForCase"),
            object: nil,
            queue: .main
        ) { notification in
            if let caseRecord = notification.object as? FirebaseManager.CaseRecord {
                generatePDF(for: caseRecord)
            }
        }
    }
    
    private func generatePDF(for caseRecord: FirebaseManager.CaseRecord) {
        Task {
            do {
                guard let user = firebaseManager.getCurrentUser() else {
                    print("❌ No user found for PDF generation")
                    return
                }
                
                let pdfURL = try await pdfManager.generateLegalCasePDF(for: caseRecord, user: user)
                
                DispatchQueue.main.async {
                    self.generatedPDFURL = pdfURL
                    self.showPDFPreview = true
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "PDF generation failed: \(error.localizedDescription)"
                }
                print("❌ PDF generation failed: \(error)")
            }
        }
    }
}

// MARK: - Loading Cases View
struct LoadingCasesView: View {
    let animationDelay: Double
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 60, height: 60)
                
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(Color.white, lineWidth: 3)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    )
            }
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
            
            Text("Loading your cases...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Compact Case Card
struct CompactCaseCard: View {
    let caseRecord: FirebaseManager.CaseRecord
    let localizationManager: LocalizationManager
    let animationDelay: Double
    let isAnimated: Bool
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(caseRecord.caseNumber)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(caseRecord.caseType)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                CompactStatusBadge(status: caseRecord.status)
            }
            
            // Case Details Preview
            Text(caseRecord.caseDetails)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
            
            // Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(DateFormatter.compact.string(from: caseRecord.createdAt))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // PDF Generation Button
                Button(action: {
                    // This will be handled by the parent view
                    NotificationCenter.default.post(
                        name: NSNotification.Name("GeneratePDFForCase"),
                        object: caseRecord
                    )
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 10))
                        Text("PDF")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Text(caseRecord.language.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Compact Status Badge
struct CompactStatusBadge: View {
    let status: FirebaseManager.CaseRecord.CaseStatus
    
    var body: some View {
        Text(statusText)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusColor.opacity(0.15))
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var statusText: String {
        switch status {
        case .filed: return "Filed"
        case .underReview: return "Review"
        case .pending: return "Pending"
        case .completed: return "Complete"
        case .rejected: return "Rejected"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .filed: return .blue
        case .underReview: return .orange
        case .pending: return .yellow
        case .completed: return .green
        case .rejected: return .red
        }
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
                subtitle: localizationManager.text("voice_case_filing_subtitle"),
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
        
        // Start actual recording
        Task {
            await startRecording()
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
        
        // Stop recording and transcribe
        Task {
            await stopRecordingAndTranscribe()
        }
    }
    
    private func startRecording() async {
        do {
            try await bhashiniManager.startRecording()
            print("🔴 Recording started - tap again to stop...")
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.recordingState = .error
                self.isProcessing = false
                self.isRecording = false
                print("❌ Failed to start recording: \(error)")
            }
        }
    }
    
    private func stopRecordingAndTranscribe() async {
        do {
            // Step 1: Stop recording and get transcription from Bhashini ASR
            print("📝 Stopping recording and getting transcription from Bhashini ASR...")
            
            DispatchQueue.main.async {
                self.recordingState = .processing
                self.isProcessing = true
            }
            
            let transcriptionText = try await bhashiniManager.stopRecordingAndTranscribe()
            
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
        print("🔍 Parsing case analysis response...")
        print("📋 Full response: \(analysis)")
        
        // Parse the AI response to extract case type, details, and questions
        let lines = analysis.components(separatedBy: .newlines)
        var currentSection = ""
        var questions: [String] = []
        var detailsLines: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.uppercased().contains("CASE TYPE:") {
                caseType = trimmedLine.replacingOccurrences(of: "CASE TYPE:", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                currentSection = ""
            } else if trimmedLine.uppercased().contains("CASE DETAILS:") {
                currentSection = "details"
            } else if trimmedLine.uppercased().contains("QUESTIONS:") {
                currentSection = "questions"
            } else if !trimmedLine.isEmpty {
                if currentSection == "details" {
                    detailsLines.append(trimmedLine)
                } else if currentSection == "questions" {
                    // Accept various question formats
                    if trimmedLine.hasPrefix("-") || 
                       trimmedLine.hasPrefix("•") || 
                       trimmedLine.hasPrefix("1.") ||
                       trimmedLine.hasPrefix("2.") ||
                       trimmedLine.contains("आपका") ||
                       trimmedLine.contains("क्या") ||
                       trimmedLine.contains("कौन") ||
                       trimmedLine.contains("कब") ||
                       trimmedLine.contains("कहाँ") ||
                       trimmedLine.contains("कैसे") ||
                       trimmedLine.contains("What") ||
                       trimmedLine.contains("Who") ||
                       trimmedLine.contains("When") ||
                       trimmedLine.contains("Where") ||
                       trimmedLine.contains("How") {
                        
                        let cleanQuestion = trimmedLine
                            .replacingOccurrences(of: "^[-•\\d\\.\\s]+", with: "", options: .regularExpression)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if cleanQuestion.count > 10 { // Only add substantial questions
                            questions.append(cleanQuestion)
                        }
                    }
                }
            }
        }
        
        // Join details if multiple lines
        if !detailsLines.isEmpty {
            caseDetails = detailsLines.joined(separator: " ")
        }
        
        filingQuestions = questions
        userResponses = Array(repeating: "", count: questions.count)
        
        print("✅ Parsed case analysis:")
        print("   Case Type: \(caseType)")
        print("   Case Details: \(caseDetails)")
        print("   Questions Count: \(questions.count)")
        print("   Questions: \(questions)")
        
        // IMPORTANT: Set the state to questionsReady after parsing
        if !questions.isEmpty && !caseType.isEmpty {
            caseFilingState = .questionsReady
            print("✅ Case filing state set to questionsReady")
        } else {
            print("❌ Parsing failed - missing questions or case type")
            caseFilingState = .error
            errorMessage = "Failed to extract case information from AI response"
        }
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
        // Check if FirebaseManager user already exists
        if firebaseManager.getCurrentUser() != nil {
            return // User already exists
        }
        
        // Try to get user from AuthenticationManager first
        let authManager = await AuthenticationManager()
        
        if let authUser = await authManager.currentUser,
           let userProfile = await authManager.userProfile {
            
            // Create FirebaseManager user from authenticated user
            do {
                let user = try await firebaseManager.createUser(
                    email: userProfile.email.isEmpty ? nil : userProfile.email,
                    name: userProfile.fullName.isEmpty ? "BoloNyay User" : userProfile.fullName,
                    userType: userProfile.userType == .advocate ? .advocate : .petitioner,
                    language: localizationManager.currentLanguage
                )
                print("✅ Created FirebaseManager user from authenticated profile: \(user.name)")
                return
            } catch {
                print("❌ Failed to create user from auth profile: \(error)")
            }
        }
        
        // Fallback: Create basic user (this should trigger proper sign-up flow)
        do {
            let userName = "BoloNyay User" // Don't use device name
            let user = try await firebaseManager.createUser(
                email: nil,
                name: userName,
                userType: .petitioner,
                language: localizationManager.currentLanguage
            )
            print("⚠️ Created fallback user - User should complete proper registration: \(user.name)")
        } catch {
            print("❌ Failed to create fallback user: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Please complete user registration to continue"
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
    
    private var recordingButtonAction: () -> Void {
        return {
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
        }
    }
    
    private var recordingButtonContent: some View {
        ZStack {
            recordingPulseRings
            mainButtonBackground
            innerHighlight
            audioLevelVisualization
            buttonIcon
            processingIndicator
        }
    }
    
    private var recordingPulseRings: some View {
        Group {
            if manager.isRecording {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.red.opacity(0.4 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: 120 + CGFloat(index * 25), height: 120 + CGFloat(index * 25))
                        .scaleEffect(manager.isRecording ? 1.3 : 0.8)
                        .opacity(manager.isRecording ? 0.7 : 0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                            value: manager.isRecording
                        )
                }
            }
        }
    }
    
    private var mainButtonBackground: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: manager.isRecording ? 
                        [Color.red.opacity(0.9), Color.red.opacity(0.7)] :
                        [Color.blue.opacity(0.9), Color.blue.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 110, height: 110)
            .shadow(
                color: (manager.isRecording ? Color.red : Color.blue).opacity(0.4), 
                radius: manager.isRecording ? 20 : 15, 
                x: 0, 
                y: manager.isRecording ? 8 : 5
            )
            .scaleEffect(manager.isRecording ? 1.05 : 1.0)
            .animation(.spring(duration: 0.4, bounce: 0.2), value: manager.isRecording)
    }
    
    private var innerHighlight: some View {
        Circle()
            .fill(Color.white.opacity(0.15))
            .frame(width: 90, height: 90)
            .scaleEffect(manager.isRecording ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: manager.isRecording)
    }
    
    private var audioLevelVisualization: some View {
        Group {
            if manager.isRecording {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(
                        width: 60 + CGFloat(manager.audioLevel * 40), 
                        height: 60 + CGFloat(manager.audioLevel * 40)
                    )
                    .animation(.easeInOut(duration: 0.1), value: manager.audioLevel)
            }
        }
    }
    
    private var buttonIcon: some View {
        ZStack {
            if manager.isRecording {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .scaleEffect(manager.isRecording ? 1.0 : 0.0)
                    .animation(.spring(duration: 0.3, bounce: 0.4).delay(0.1), value: manager.isRecording)
            } else {
                Image(systemName: "mic.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(manager.isRecording ? 0.0 : 1.0)
                    .animation(.spring(duration: 0.3, bounce: 0.4), value: manager.isRecording)
            }
        }
    }
    
    private var processingIndicator: some View {
        Group {
            if manager.isProcessing {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: manager.isProcessing)
            }
        }
    }
    
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
                        Button(action: recordingButtonAction) {
                            recordingButtonContent
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
                                    Text(localizationManager.text("file_this_case"))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.orange)
                                    
                                    Text(localizationManager.text("convert_conversation_legal"))
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
                return localizationManager.text("tap_to_start_recording")
            } else {
                return localizationManager.text("tap_to_continue_conversation")
            }
        case .recording:
            return localizationManager.text("recording_tap_to_stop")
        case .processing:
            return localizationManager.text("processing_message")
        case .completed:
            return localizationManager.text("tap_to_continue_conversation")
        case .error:
            return localizationManager.text("error_try_again")
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
                        Text(localizationManager.text("case_filing"))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(localizationManager.text("prepare_legal_case"))
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
    @State private var isRecordingAnswer = false
    @State private var isProcessingVoice = false
    @State private var voiceAnswerError: String?
    @State private var recordingDuration: TimeInterval = 0.0
    @State private var recordingTimer: Timer?
    @StateObject private var bhashiniManager = BhashiniManager()
    
    private let maxRecordingDuration: TimeInterval = 15.0
    
    private var voiceRecordingAction: () -> Void {
        return {
            if isRecordingAnswer {
                stopVoiceRecording()
            } else {
                startVoiceRecording()
            }
        }
    }
    
    private var voiceRecordingButtonContent: some View {
        HStack(spacing: 8) {
            ZStack {
                questionPulseRings
                questionMainButton
                questionInnerHighlight
                questionButtonIcon
                questionProcessingIndicator
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isRecordingAnswer ? "Recording..." : "Tap to start")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(isRecordingAnswer ? "Tap again to stop & transcribe" : "Speak in Hindi")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .stroke(isRecordingAnswer ? Color.red.opacity(0.5) : Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var questionPulseRings: some View {
        Group {
            if isRecordingAnswer {
                ForEach(0..<2) { index in
                    Circle()
                        .stroke(Color.red.opacity(0.5 - Double(index) * 0.2), lineWidth: 1.5)
                        .frame(width: 50 + CGFloat(index * 15), height: 50 + CGFloat(index * 15))
                        .scaleEffect(isRecordingAnswer ? 1.4 : 0.8)
                        .opacity(isRecordingAnswer ? 0.8 : 0)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.2),
                            value: isRecordingAnswer
                        )
                }
            }
        }
    }
    
    private var questionMainButton: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: isRecordingAnswer ? 
                        [Color.red.opacity(0.8), Color.red.opacity(0.6)] :
                        [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 44, height: 44)
            .shadow(
                color: (isRecordingAnswer ? Color.red : Color.blue).opacity(0.3), 
                radius: isRecordingAnswer ? 8 : 4, 
                x: 0, 
                y: 3
            )
            .scaleEffect(isRecordingAnswer ? 1.1 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.3), value: isRecordingAnswer)
    }
    
    private var questionInnerHighlight: some View {
        Circle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 36, height: 36)
            .scaleEffect(isRecordingAnswer ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isRecordingAnswer)
    }
    
    private var questionButtonIcon: some View {
        ZStack {
            if isRecordingAnswer {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .scaleEffect(isRecordingAnswer ? 1.0 : 0.0)
                    .animation(.spring(duration: 0.3, bounce: 0.4).delay(0.1), value: isRecordingAnswer)
            } else {
                Image(systemName: "mic.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(isRecordingAnswer ? 0.0 : 1.0)
                    .animation(.spring(duration: 0.3, bounce: 0.4), value: isRecordingAnswer)
            }
        }
    }
    
    private var questionProcessingIndicator: some View {
        Group {
            if isProcessingVoice {
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isProcessingVoice)
            }
        }
    }
    
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(question)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    // Voice recording indicator
                    if isRecordingAnswer {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isRecordingAnswer ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecordingAnswer)
                            
                            Text("Recording... \(formatDuration(recordingDuration))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red)
                                .monospacedDigit()
                        }
                    }
                    
                    if isProcessingVoice {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            
                            Text("Converting speech to text...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                }
                
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
                            
                            Button(action: {
                                withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                                    isExpanded = true
                                    textAnswer = answer
                                    voiceAnswerError = nil
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 10, weight: .medium))
                                    Text("Edit")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.blue.opacity(0.1))
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
                                )
                            }
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
                        VStack(spacing: 12) {
                            // Voice Input Section
                            VStack(spacing: 8) {
                                HStack {
                                    Text("हिंदी में बोलकर जवाब दें (Speak in Hindi)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blue)
                                    
                                    Spacer()
                                }
                                
                                // Voice Recording Button
                                Button(action: voiceRecordingAction) {
                                    voiceRecordingButtonContent
                                }
                                .disabled(isProcessingVoice)
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Text Input Section
                            VStack(spacing: 8) {
                                HStack {
                                    Text("या टाइप करें (Or type)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                }
                                
                                TextField("Type your answer...", text: $textAnswer, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 14))
                                    .lineLimit(3...6)
                            }
                            
                            // Error Display
                            if let error = voiceAnswerError {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                    
                                    Text(error)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.red.opacity(0.1))
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Submit Button
                            HStack {
                                Button(action: {
                                    withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                                        isExpanded = false
                                        textAnswer = ""
                                        voiceAnswerError = nil
                                    }
                                }) {
                                    Text("Cancel")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    submitAnswer()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                        
                                        Text("Submit Answer")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(textAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.green)
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
        .onChange(of: answer) { newAnswer in
            // Keep textAnswer in sync with the updated answer from parent
            if !isExpanded {
                textAnswer = newAnswer
            }
        }
        .onDisappear {
            cleanupRecording()
        }
    }
    
    // MARK: - Voice Recording Functions
    
    private func startVoiceRecording() {
        print("🎤 Starting voice recording for question \(questionNumber)...")
        
        isRecordingAnswer = true
        isProcessingVoice = false
        voiceAnswerError = nil
        recordingDuration = 0.0
        
        // Start recording timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
            
            // Auto-stop at max duration (safety limit)
            if recordingDuration >= maxRecordingDuration {
                stopVoiceRecording()
            }
        }
        
        // Start actual recording
        Task {
            await performVoiceRecording()
        }
    }
    
    private func stopVoiceRecording() {
        print("⏹️ Stopping voice recording for question \(questionNumber)...")
        
        isRecordingAnswer = false
        isProcessingVoice = true
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Start transcription process
        Task {
            await performVoiceRecording()
        }
    }
    
    private func performVoiceRecording() async {
        do {
            if isRecordingAnswer {
                // Start recording
                print("🎤 Starting recording for question \(questionNumber)...")
                try await bhashiniManager.startRecording()
                
            } else {
                // Stop recording and transcribe
                print("📝 Stopping recording and transcribing for question \(questionNumber)...")
                let transcription = try await bhashiniManager.stopRecordingAndTranscribe()
                
                await MainActor.run {
                    self.textAnswer = transcription
                    self.isProcessingVoice = false
                    self.voiceAnswerError = nil
                    print("✅ Voice answer transcribed: '\(transcription)'")
                }
            }
            
        } catch {
            await MainActor.run {
                self.voiceAnswerError = "Voice recording failed: \(error.localizedDescription)"
                self.isProcessingVoice = false
                self.isRecordingAnswer = false
                print("❌ Voice recording failed for question \(self.questionNumber): \(error)")
            }
        }
    }
    
    private func submitAnswer() {
        let finalAnswer = textAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalAnswer.isEmpty {
            onAnswerSubmit(finalAnswer)
            withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                isExpanded = false
            }
            cleanupRecording()
            
            // Force UI refresh by clearing and setting textAnswer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.textAnswer = finalAnswer
            }
        }
    }
    
    private func cleanupRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecordingAnswer = false
        isProcessingVoice = false
        recordingDuration = 0.0
        voiceAnswerError = nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct ReadyToFileView: View {
    @ObservedObject var manager: VoiceCaseFilingManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
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
                Text(localizationManager.text("ready_to_file"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(localizationManager.text("case_ready_filing"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Case Summary
            VStack(alignment: .leading, spacing: 16) {
                Text(localizationManager.text("case_summary"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(localizationManager.text("case_type"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(manager.caseType)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.text("case_details"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(manager.caseDetails)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text(String(format: localizationManager.text("responses_completed"), manager.userResponses.filter { !$0.isEmpty }.count))
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
                    
                    Text(localizationManager.text("file_case_now"))
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
    @StateObject private var pdfManager = PDFGenerationManager.shared
    @State private var showPDFPreview = false
    @State private var generatedPDFURL: URL?
    
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
            
            // PDF Generation Section
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Legal Document PDF")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Generate official court filing document")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.3))
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                
                // PDF Generation Button
                if pdfManager.isGeneratingPDF {
                    VStack(spacing: 12) {
                        ProgressView(value: pdfManager.pdfGenerationProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(height: 8)
                        
                        Text("Generating PDF... \(Int(pdfManager.pdfGenerationProgress * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)
                } else if let pdfURL = generatedPDFURL {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("PDF Generated Successfully!")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        
                        // PDF Action Buttons - Two rows for better layout
                        VStack(spacing: 12) {
                            // First row - Preview and Email
                            HStack(spacing: 16) {
                                Button(action: {
                                    showPDFPreview = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "eye.fill")
                                        Text("Preview")
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.blue)
                                    )
                                }
                                
                                Button(action: {
                                    emailPDF(pdfURL)
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "envelope.fill")
                                        Text("Email")
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.green)
                                    )
                                }
                            }
                            
                            // Second row - Share button (full width)
                            Button(action: {
                                sharePDF(pdfURL)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share with Other Apps")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                            }
                        }
                    }
                } else {
                    Button(action: {
                        generatePDF()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("Generate Court Filing PDF")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                }
                
                // Error Message
                if let errorMessage = pdfManager.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
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
        .sheet(isPresented: $showPDFPreview) {
            if let pdfURL = generatedPDFURL {
                PDFPreviewView(pdfURL: pdfURL)
            }
        }
    }
    
    private func generateDisplayCaseNumber() -> String {
        if !manager.conversationHistory.isEmpty {
            let currentYear = Calendar.current.component(.year, from: Date())
            let randomNumber = Int.random(in: 100000...999999)
            return "BN\(currentYear)\(randomNumber)"
        }
        return "BN2024000000"
    }
    
    // MARK: - PDF Functions
    
    private func generatePDF() {
        Task {
            do {
                // Get current user and create a dummy case record for demo
                guard let user = FirebaseManager.shared.getCurrentUser() else {
                    print("❌ No user found for PDF generation")
                    return
                }
                
                // Create case record from manager data
                let caseRecord = FirebaseManager.CaseRecord(
                    id: UUID().uuidString,
                    caseNumber: "BN2024\(Int.random(in: 100000...999999))",
                    userId: user.id,
                    caseType: manager.caseType,
                    caseDetails: manager.caseDetails,
                    conversationSummary: buildConversationSummary(),
                    filingQuestions: manager.filingQuestions,
                    userResponses: manager.userResponses,
                    status: .filed,
                    createdAt: Date(),
                    updatedAt: Date(),
                    sessionId: manager.sessionId,
                    azureSessionId: manager.sessionId,
                    language: LocalizationManager.shared.currentLanguage
                )
                
                let pdfURL = try await pdfManager.generateLegalCasePDF(for: caseRecord, user: user)
                
                DispatchQueue.main.async {
                    self.generatedPDFURL = pdfURL
                }
                
            } catch {
                print("❌ PDF generation failed: \(error)")
            }
        }
    }
    
    private func buildConversationSummary() -> String {
        var summary = "Case Filing Conversation Summary:\n\n"
        
        for message in manager.conversationHistory {
            switch message.type {
            case .userTranscription:
                summary += "User: \(message.content)\n\n"
            case .aiResponse:
                summary += "Legal Expert: \(message.content)\n\n"
            }
        }
        
        return summary
    }
    
    private func sharePDF(_ pdfURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func emailPDF(_ pdfURL: URL) {
        EmailManager.shared.sendLegalDocument(pdfURL: pdfURL) { success, message in
            DispatchQueue.main.async {
                if !success && !message.contains("cancelled") {
                    // Show error alert only if not cancelled
                    let alert = UIAlertController(
                        title: "Email Error",
                        message: message,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(alert, animated: true)
                    }
                }
            }
        }
    }

}

// MARK: - Mail Coordinator for CaseFiledView
class MailCoordinator: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = MailCoordinator() // Singleton to prevent deallocation
    
    private override init() {
        super.init()
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        
        // Handle result
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var message = ""
            var isSuccess = false
            
            switch result {
            case .sent:
                message = "✅ Email sent successfully!"
                isSuccess = true
            case .saved:
                message = "📄 Email saved as draft"
                isSuccess = true
            case .cancelled:
                message = "❌ Email cancelled"
            case .failed:
                message = "❌ Failed to send email"
            @unknown default:
                message = "❌ Unknown error occurred"
            }
            
            // Show result alert
            let alert = UIAlertController(
                title: isSuccess ? "Success" : "Email Status",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(alert, animated: true)
            }
        }
    }
}

// MARK: - Enhanced Email Manager
class EmailManager {
    static let shared = EmailManager()
    
    private init() {}
    
    func sendLegalDocument(pdfURL: URL, completion: @escaping (Bool, String) -> Void) {
        // Enhanced email options with better recipients
        let emailOptions = [
            ("👨‍💼 Legal Advisor", "legal.advisor@example.com"),
            ("🏛️ Court Registry", "registry@district.court.gov.in"),
            ("👨‍⚖️ Public Prosecutor", "prosecutor@district.court.gov.in"),
            ("👥 Family Member", "family@example.com"),
            ("📧 Gmail Direct", "gmail"),
            ("✉️ Custom Email", "custom")
        ]
        
        let alert = UIAlertController(
            title: "📧 Send Legal Document",
            message: "Choose how you'd like to send your legal document",
            preferredStyle: .actionSheet
        )
        
        // Add predefined options
        for (title, email) in emailOptions {
            if email == "custom" {
                alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                    self.showCustomEmailInput(pdfURL: pdfURL, completion: completion)
                })
            } else if email == "gmail" {
                alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                    self.sendViaGmailDirect(pdfURL: pdfURL, completion: completion)
                })
            } else {
                alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                    self.composeAdvancedEmail(to: email, pdfURL: pdfURL, completion: completion)
                })
            }
        }
        
        alert.addAction(UIAlertAction(title: "❌ Cancel", style: .cancel) { _ in
            completion(false, "Email cancelled")
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            // For iPad
            if let popover = alert.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func showCustomEmailInput(pdfURL: URL, completion: @escaping (Bool, String) -> Void) {
        let alert = UIAlertController(
            title: "📮 Enter Email Address",
            message: "Please enter the recipient's email address for sending your legal document",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "example@domain.com"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.clearButtonMode = .whileEditing
        }
        
        alert.addAction(UIAlertAction(title: "📧 Send Email", style: .default) { _ in
            if let email = alert.textFields?.first?.text, !email.isEmpty {
                if self.isValidEmail(email) {
                    self.composeAdvancedEmail(to: email, pdfURL: pdfURL, completion: completion)
                } else {
                    completion(false, "Invalid email address format")
                }
            } else {
                completion(false, "Email address is required")
            }
        })
        
        alert.addAction(UIAlertAction(title: "❌ Cancel", style: .cancel) { _ in
            completion(false, "Email cancelled")
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func composeAdvancedEmail(to email: String, pdfURL: URL, completion: @escaping (Bool, String) -> Void) {
        // First try Gmail integration if Mail app is not available
        guard MFMailComposeViewController.canSendMail() else {
            // Use Gmail Manager for better email options
            let emailTemplate = GmailManager.shared.createLegalDocumentEmail(
                caseNumber: "BN\(Calendar.current.component(.year, from: Date()))\(Int.random(in: 100000...999999))",
                documentType: "Legal Case Filing"
            )
            
            GmailManager.shared.sendEmailViaGmail(
                to: email,
                subject: emailTemplate.subject,
                body: emailTemplate.body,
                attachmentURL: pdfURL,
                completion: completion
            )
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = MailCoordinator.shared
        
        // Set enhanced email details
        mailComposer.setToRecipients([email])
        mailComposer.setSubject("🏛️ Legal Document - BoloNyay Case Filing")
        
        // Enhanced email body with better formatting
        let currentDate = DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short)
        let caseNumber = "BN\(Calendar.current.component(.year, from: Date()))\(Int.random(in: 100000...999999))"
        
        let emailBody = """
        📧 Legal Document from BoloNyay Legal Assistant
        
        Dear Recipient,
        
        I hope this email finds you well. Please find attached the legal document generated through BoloNyay Legal Assistant platform.
        
        📋 Document Details:
        ───────────────────────
        • Case Reference: \(caseNumber)
        • Generated Date: \(currentDate)
        • Document Type: Legal Case Filing
        • Platform: BoloNyay Legal Assistant
        • Format: PDF Document
        
        📝 Important Information:
        ───────────────────────
        This document contains important case filing information and legal details that should be reviewed carefully by qualified legal professionals.
        
        The document has been generated using AI-assisted legal guidance and should be verified for accuracy and completeness before any official submission.
        
        📞 Need Help?
        ──────────────
        If you have any questions about this document or need further assistance, please don't hesitate to contact our support team.
        
        • Email: support@bolonyay.com
        • Website: www.bolonyay.com
        • Legal Helpline: +91-XXXXX-XXXXX
        
        🔒 Confidentiality Notice:
        ─────────────────────────
        This email and its attachments contain confidential legal information. If you are not the intended recipient, please delete this email immediately and notify the sender.
        
        Best regards,
        BoloNyay Legal Assistant Team
        
        ───────────────────────
        🌟 Powered by BoloNyay
        Making Legal Assistance Accessible to Everyone
        """
        
        mailComposer.setMessageBody(emailBody, isHTML: false)
        
        // Enhanced PDF attachment with better filename
        do {
            let pdfData = try Data(contentsOf: pdfURL)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HHmm"
            let dateString = formatter.string(from: Date())
            let fileName = "BoloNyay_Legal_Document_\(dateString).pdf"
            
            mailComposer.addAttachmentData(pdfData, mimeType: "application/pdf", fileName: fileName)
            
            print("✅ PDF attached successfully: \(fileName)")
        } catch {
            print("❌ Failed to attach PDF: \(error)")
            completion(false, "Failed to attach PDF document")
            return
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(mailComposer, animated: true)
            completion(true, "Email composer opened successfully")
        } else {
            completion(false, "Unable to present email composer")
        }
    }
    
    private func sendViaGmailDirect(pdfURL: URL, completion: @escaping (Bool, String) -> Void) {
        let emailTemplate = GmailManager.shared.createLegalDocumentEmail(
            caseNumber: "BN\(Calendar.current.component(.year, from: Date()))\(Int.random(in: 100000...999999))",
            documentType: "Legal Case Filing"
        )
        
        let alert = UIAlertController(
            title: "📧 Gmail Direct Send",
            message: "Enter recipient's email address for Gmail",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "recipient@gmail.com"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        alert.addAction(UIAlertAction(title: "📧 Send via Gmail", style: .default) { _ in
            if let email = alert.textFields?.first?.text, !email.isEmpty {
                GmailManager.shared.sendEmailViaGmail(
                    to: email,
                    subject: emailTemplate.subject,
                    body: emailTemplate.body,
                    attachmentURL: pdfURL,
                    completion: completion
                )
            } else {
                completion(false, "Email address is required")
            }
        })
        
        alert.addAction(UIAlertAction(title: "❌ Cancel", style: .cancel) { _ in
            completion(false, "Gmail send cancelled")
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }

    private func fallbackToShareSheet(pdfURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
        
        // Customize share sheet
        activityViewController.setValue("Share Legal Document", forKey: "subject")
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            // For iPad
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
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
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        HelpSystemView(animationDelay: 0.0)
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

// MARK: - Elegant Help Components

struct ElegantUserProfileCard: View {
    let user: FirebaseManager.BoloNyayUser?
    let localizationManager: LocalizationManager
    let animationDelay: Double
    let isAnimated: Bool
    let onProfileTap: () -> Void
    @State private var isVisible = false
    @State private var showProfileManagement = false
    
    var body: some View {
        Button(action: {
            showProfileManagement = true
        }) {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: user?.userType.icon ?? "person.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user?.name ?? localizationManager.text("guest_user"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(user?.email ?? localizationManager.text("no_email"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        
                        Text(localizationManager.text("active"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
        .sheet(isPresented: $showProfileManagement) {
            UserProfileManagementView()
        }
    }
}

struct ElegantLanguageSettings: View {
    let currentLanguage: String
    let localizationManager: LocalizationManager
    let animationDelay: Double
    let isAnimated: Bool
    let onLanguageChange: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(localizationManager.text("language_settings"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Button(action: onLanguageChange) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizationManager.text("current_language"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(localizationManager.getCurrentLanguageName())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

struct ElegantHelpSection: View {
    let icon: String
    let title: String
    let subtitle: String
    let animationDelay: Double
    let isAnimated: Bool
    let action: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

struct ElegantAccountManagement: View {
    let localizationManager: LocalizationManager
    let animationDelay: Double
    let isAnimated: Bool
    let onDeleteAccount: () -> Void
    let onLogout: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(localizationManager.text("account_management"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Logout Button
                Button(action: onLogout) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                        
                        Text(localizationManager.text("logout"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Delete Account Button
                Button(action: onDeleteAccount) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                        
                        Text(localizationManager.text("delete_account"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

struct ElegantLanguagePicker: View {
    let localizationManager: LocalizationManager
    let onLanguageSelected: (String) -> Void
    @State private var isAnimated = false
    
    private let supportedLanguages = [
        ("en", "English", "🇺🇸"),
        ("hi", "हिंदी", "🇮🇳"),
        ("gu", "ગુજરાતી", "🇮🇳"),
        ("ur", "اردو", "🇵🇰"),
        ("mr", "मराठी", "🇮🇳")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text(localizationManager.text("select_language"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(localizationManager.text("choose_preferred_language"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Language Options
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(supportedLanguages.enumerated()), id: \.element.0) { index, language in
                            ElegantLanguageOption(
                                code: language.0,
                                name: language.1,
                                flag: language.2,
                                isSelected: localizationManager.currentLanguage == language.0,
                                animationDelay: Double(index) * 0.1,
                                isAnimated: isAnimated,
                                onTap: {
                                    onLanguageSelected(language.0)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.text("done")) {
                        onLanguageSelected(localizationManager.currentLanguage)
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                isAnimated = true
            }
        }
    }
}

struct ElegantLanguageOption: View {
    let code: String
    let name: String
    let flag: String
    let isSelected: Bool
    let animationDelay: Double
    let isAnimated: Bool
    let onTap: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(flag)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(code.uppercased())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
                    .stroke(isSelected ? Color.green.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

struct ElegantUserProfileView: View {
    let user: FirebaseManager.BoloNyayUser?
    let localizationManager: LocalizationManager
    @State private var isAnimated = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Profile Header
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: user?.userType.icon ?? "person.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .scaleEffect(isAnimated ? 1.0 : 0.8)
                        .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: isAnimated)
                    
                    VStack(spacing: 8) {
                        Text(user?.name ?? localizationManager.text("guest_user"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(user?.email ?? localizationManager.text("no_email"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(user?.userType.rawValue ?? "Guest")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.2))
                            )
                    }
                }
                .opacity(isAnimated ? 1.0 : 0.0)
                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.3), value: isAnimated)
                
                // Profile Details
                VStack(spacing: 16) {
                    ElegantProfileRow(
                        icon: "calendar",
                        title: localizationManager.text("member_since"),
                        value: DateFormatter.memberSince.string(from: user?.createdAt ?? Date())
                    )
                    
                    ElegantProfileRow(
                        icon: "globe",
                        title: localizationManager.text("preferred_language"),
                        value: localizationManager.getCurrentLanguageName()
                    )
                    
                    ElegantProfileRow(
                        icon: "person.badge.shield.checkmark",
                        title: localizationManager.text("account_type"),
                        value: user?.userType.rawValue ?? "Guest"
                    )
                }
                .opacity(isAnimated ? 1.0 : 0.0)
                .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.5), value: isAnimated)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(localizationManager.text("profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.text("done")) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                isAnimated = true
            }
        }
    }
}

struct ElegantProfileRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let memberSince: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let compact: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter
    }()
}