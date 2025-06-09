import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firebase Manager
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    @Published var isConnected = false
    @Published var currentUser: BoloNyayUser?
    
    // MARK: - User Data Models
    
    struct BoloNyayUser {
        let id: String
        let email: String?
        let name: String
        let userType: UserType
        let createdAt: Date
        let language: String
        
        enum UserType: String, CaseIterable {
            case petitioner = "petitioner"
            case advocate = "advocate"
            
            var displayName: String {
                switch self {
                case .petitioner: return "Petitioner (Citizen)"
                case .advocate: return "Advocate (Lawyer)"
                }
            }
            
            var icon: String {
                switch self {
                case .petitioner: return "person.fill"
                case .advocate: return "briefcase.fill"
                }
            }
        }
    }
    
    struct CaseRecord {
        let id: String
        let caseNumber: String
        let userId: String
        let caseType: String
        let caseDetails: String
        let conversationSummary: String
        let filingQuestions: [String]
        let userResponses: [String]
        let status: CaseStatus
        let createdAt: Date
        let updatedAt: Date
        let sessionId: String
        let azureSessionId: String?
        let language: String
        
        enum CaseStatus: String, CaseIterable {
            case filed = "filed"
            case underReview = "under_review"
            case pending = "pending"
            case completed = "completed"
            case rejected = "rejected"
            
            var displayName: String {
                switch self {
                case .filed: return "Filed"
                case .underReview: return "Under Review"
                case .pending: return "Pending"
                case .completed: return "Completed"
                case .rejected: return "Rejected"
                }
            }
            
            var color: String {
                switch self {
                case .filed: return "blue"
                case .underReview: return "orange"
                case .pending: return "yellow"
                case .completed: return "green"
                case .rejected: return "red"
                }
            }
        }
    }
    
    struct ConversationSession {
        let id: String
        let userId: String
        let messages: [SessionMessage]
        let startedAt: Date
        let endedAt: Date?
        let language: String
        let azureSessionId: String?
        let totalMessages: Int
        let caseNumber: String?
        
        struct SessionMessage {
            let id: String
            let type: MessageType
            let content: String
            let timestamp: Date
            let language: String
            
            enum MessageType: String {
                case userTranscription = "user_transcription"
                case aiResponse = "ai_response"
            }
        }
    }
    
    private init() {
        setupFirebase()
        
        // Initialize user state on launch
        Task {
            await initializeUserState()
        }
    }
    
    // MARK: - Firebase Setup
    
    private func setupFirebase() {
        // Configure Firebase if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Check connection
        checkConnection()
    }
    
    private func checkConnection() {
        // Simple connection test by attempting to read from Firestore
        db.collection("test").limit(to: 1).getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.isConnected = true
                    print("✅ Firebase connected successfully")
                } else {
                    self?.isConnected = false
                    print("❌ Firebase connection failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    // MARK: - User State Initialization
    
    @MainActor
    private func initializeUserState() async {
        // If there's an authenticated Firebase Auth user, try to load their BoloNyayUser profile
        if let authUser = Auth.auth().currentUser {
            do {
                let _ = try await loadUserById(authUser.uid)
            } catch {
                print("⚠️ Could not load existing user profile on launch: \(error)")
            }
        }
    }
    
    // MARK: - User Management
    
    func createUser(email: String?, name: String, userType: BoloNyayUser.UserType, language: String, userId: String? = nil) async throws -> BoloNyayUser {
        let userId = userId ?? UUID().uuidString
        
        let userData: [String: Any] = [
            "id": userId,
            "email": email ?? "",
            "name": name,
            "userType": userType.rawValue,
            "createdAt": Timestamp(date: Date()),
            "language": language
        ]
        
        try await db.collection("users").document(userId).setData(userData)
        
        let user = BoloNyayUser(
            id: userId,
            email: email,
            name: name,
            userType: userType,
            createdAt: Date(),
            language: language
        )
        
        DispatchQueue.main.async {
            self.currentUser = user
        }
        
        print("✅ User created successfully: \(userId)")
        return user
    }
    
    func getCurrentUser() -> BoloNyayUser? {
        return currentUser
    }
    
    // MARK: - User Loading
    
    func loadUserById(_ userId: String) async throws -> BoloNyayUser? {
        let document = try await db.collection("users").document(userId).getDocument()
        
        if document.exists, let data = document.data() {
            let user = BoloNyayUser(
                id: data["id"] as? String ?? userId,
                email: data["email"] as? String,
                name: data["name"] as? String ?? "BoloNyay User",
                userType: BoloNyayUser.UserType(rawValue: data["userType"] as? String ?? "petitioner") ?? .petitioner,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                language: data["language"] as? String ?? "english"
            )
            
            DispatchQueue.main.async {
                self.currentUser = user
            }
            
            print("✅ Loaded existing user: \(user.name) (\(userId))")
            return user
        }
        
        return nil
    }
    
    func ensureUserFromAuth() async throws -> BoloNyayUser {
        // First check if we already have a current user
        if let existingUser = currentUser {
            return existingUser
        }
        
        // Check if there's an authenticated user in AuthenticationManager
        if let authUser = Auth.auth().currentUser {
            // Try to load existing BoloNyayUser
            if let existingUser = try await loadUserById(authUser.uid) {
                return existingUser
            }
            
            // User is authenticated but doesn't have BoloNyayUser profile
            // Create one from their auth profile
            let user = try await createUser(
                email: authUser.email,
                name: authUser.displayName ?? "BoloNyay User",
                userType: .petitioner, // Default to petitioner
                language: LocalizationManager.shared.currentLanguage,
                userId: authUser.uid
            )
            
            print("✅ Created BoloNyayUser from authenticated profile: \(user.name)")
            return user
        }
        
        // No authenticated user - create anonymous user for basic functionality
        let user = try await createUser(
            email: nil,
            name: UIDevice.current.name.isEmpty ? "BoloNyay User" : UIDevice.current.name,
            userType: .petitioner,
            language: LocalizationManager.shared.currentLanguage
        )
        
        print("✅ Created anonymous user: \(user.name)")
        return user
    }
    
    // MARK: - Case Management
    
    func saveCase(
        caseNumber: String,
        caseType: String,
        caseDetails: String,
        conversationSummary: String,
        filingQuestions: [String],
        userResponses: [String],
        sessionId: String,
        azureSessionId: String?,
        language: String
    ) async throws -> CaseRecord {
        
        guard let userId = currentUser?.id else {
            throw FirebaseError.userNotFound
        }
        
        let caseId = UUID().uuidString
        let now = Date()
        
        let caseData: [String: Any] = [
            "id": caseId,
            "caseNumber": caseNumber,
            "userId": userId,
            "caseType": caseType,
            "caseDetails": caseDetails,
            "conversationSummary": conversationSummary,
            "filingQuestions": filingQuestions,
            "userResponses": userResponses,
            "status": CaseRecord.CaseStatus.filed.rawValue,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now),
            "sessionId": sessionId,
            "azureSessionId": azureSessionId ?? "",
            "language": language
        ]
        
        try await db.collection("cases").document(caseId).setData(caseData)
        
        let caseRecord = CaseRecord(
            id: caseId,
            caseNumber: caseNumber,
            userId: userId,
            caseType: caseType,
            caseDetails: caseDetails,
            conversationSummary: conversationSummary,
            filingQuestions: filingQuestions,
            userResponses: userResponses,
            status: .filed,
            createdAt: now,
            updatedAt: now,
            sessionId: sessionId,
            azureSessionId: azureSessionId,
            language: language
        )
        
        print("✅ Case saved to Firebase: \(caseNumber)")
        return caseRecord
    }
    
    func getUserCases() async throws -> [CaseRecord] {
        guard let userId = currentUser?.id else {
            throw FirebaseError.userNotFound
        }
        
        let snapshot = try await db.collection("cases")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        var cases: [CaseRecord] = []
        
        for document in snapshot.documents {
            let data = document.data()
            
            if let caseRecord = parseCaseRecord(from: data) {
                cases.append(caseRecord)
            }
        }
        
        // Sort cases by creation date (newest first) in the app
        cases.sort { $0.createdAt > $1.createdAt }
        
        print("✅ Retrieved \(cases.count) cases for user \(userId)")
        return cases
    }
    
    func updateCaseStatus(caseId: String, status: CaseRecord.CaseStatus) async throws {
        let updateData: [String: Any] = [
            "status": status.rawValue,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("cases").document(caseId).updateData(updateData)
        print("✅ Case status updated: \(caseId) -> \(status.rawValue)")
    }
    
    // MARK: - Session Management
    
    func saveConversationSession(
        messages: [ConversationSession.SessionMessage],
        language: String,
        azureSessionId: String?,
        caseNumber: String?
    ) async throws -> ConversationSession {
        
        guard let userId = currentUser?.id else {
            throw FirebaseError.userNotFound
        }
        
        let sessionId = UUID().uuidString
        let now = Date()
        
        let messagesData = messages.map { message in
            [
                "id": message.id,
                "type": message.type.rawValue,
                "content": message.content,
                "timestamp": Timestamp(date: message.timestamp),
                "language": message.language
            ]
        }
        
        let sessionData: [String: Any] = [
            "id": sessionId,
            "userId": userId,
            "messages": messagesData,
            "startedAt": Timestamp(date: now),
            "endedAt": NSNull(),
            "language": language,
            "azureSessionId": azureSessionId ?? "",
            "totalMessages": messages.count,
            "caseNumber": caseNumber ?? ""
        ]
        
        try await db.collection("sessions").document(sessionId).setData(sessionData)
        
        let session = ConversationSession(
            id: sessionId,
            userId: userId,
            messages: messages,
            startedAt: now,
            endedAt: nil,
            language: language,
            azureSessionId: azureSessionId,
            totalMessages: messages.count,
            caseNumber: caseNumber
        )
        
        print("✅ Conversation session saved: \(sessionId)")
        return session
    }
    
    func getUserSessions() async throws -> [ConversationSession] {
        guard let userId = currentUser?.id else {
            throw FirebaseError.userNotFound
        }
        
        let snapshot = try await db.collection("sessions")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        var sessions: [ConversationSession] = []
        
        for document in snapshot.documents {
            let data = document.data()
            
            if let session = parseConversationSession(from: data) {
                sessions.append(session)
            }
        }
        
        // Sort sessions by start date (newest first) in the app
        sessions.sort { $0.startedAt > $1.startedAt }
        
        print("✅ Retrieved \(sessions.count) sessions for user \(userId)")
        return sessions
    }
    
    // MARK: - Analytics & Reports
    
    func getCaseStatistics() async throws -> CaseStatistics {
        guard let userId = currentUser?.id else {
            throw FirebaseError.userNotFound
        }
        
        let snapshot = try await db.collection("cases")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        var totalCases = 0
        var casesByStatus: [String: Int] = [:]
        var casesByType: [String: Int] = [:]
        var casesByLanguage: [String: Int] = [:]
        
        for document in snapshot.documents {
            let data = document.data()
            totalCases += 1
            
            if let status = data["status"] as? String {
                casesByStatus[status, default: 0] += 1
            }
            
            if let type = data["caseType"] as? String {
                casesByType[type, default: 0] += 1
            }
            
            if let language = data["language"] as? String {
                casesByLanguage[language, default: 0] += 1
            }
        }
        
        return CaseStatistics(
            totalCases: totalCases,
            casesByStatus: casesByStatus,
            casesByType: casesByType,
            casesByLanguage: casesByLanguage
        )
    }
    
    // MARK: - Helper Methods
    
    private func parseCaseRecord(from data: [String: Any]) -> CaseRecord? {
        guard let id = data["id"] as? String,
              let caseNumber = data["caseNumber"] as? String,
              let userId = data["userId"] as? String,
              let caseType = data["caseType"] as? String,
              let caseDetails = data["caseDetails"] as? String,
              let conversationSummary = data["conversationSummary"] as? String,
              let filingQuestions = data["filingQuestions"] as? [String],
              let userResponses = data["userResponses"] as? [String],
              let statusString = data["status"] as? String,
              let status = CaseRecord.CaseStatus(rawValue: statusString),
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp,
              let sessionId = data["sessionId"] as? String,
              let language = data["language"] as? String else {
            return nil
        }
        
        return CaseRecord(
            id: id,
            caseNumber: caseNumber,
            userId: userId,
            caseType: caseType,
            caseDetails: caseDetails,
            conversationSummary: conversationSummary,
            filingQuestions: filingQuestions,
            userResponses: userResponses,
            status: status,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            sessionId: sessionId,
            azureSessionId: data["azureSessionId"] as? String,
            language: language
        )
    }
    
    private func parseConversationSession(from data: [String: Any]) -> ConversationSession? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let messagesData = data["messages"] as? [[String: Any]],
              let startedAtTimestamp = data["startedAt"] as? Timestamp,
              let language = data["language"] as? String,
              let totalMessages = data["totalMessages"] as? Int else {
            return nil
        }
        
        let messages = messagesData.compactMap { messageData -> ConversationSession.SessionMessage? in
            guard let messageId = messageData["id"] as? String,
                  let typeString = messageData["type"] as? String,
                  let type = ConversationSession.SessionMessage.MessageType(rawValue: typeString),
                  let content = messageData["content"] as? String,
                  let timestampData = messageData["timestamp"] as? Timestamp,
                  let messageLanguage = messageData["language"] as? String else {
                return nil
            }
            
            return ConversationSession.SessionMessage(
                id: messageId,
                type: type,
                content: content,
                timestamp: timestampData.dateValue(),
                language: messageLanguage
            )
        }
        
        let endedAt = (data["endedAt"] as? Timestamp)?.dateValue()
        
        return ConversationSession(
            id: id,
            userId: userId,
            messages: messages,
            startedAt: startedAtTimestamp.dateValue(),
            endedAt: endedAt,
            language: language,
            azureSessionId: data["azureSessionId"] as? String,
            totalMessages: totalMessages,
            caseNumber: data["caseNumber"] as? String
        )
    }
}

// MARK: - Supporting Types

struct CaseStatistics {
    let totalCases: Int
    let casesByStatus: [String: Int]
    let casesByType: [String: Int]
    let casesByLanguage: [String: Int]
}

enum FirebaseError: Error {
    case userNotFound
    case connectionFailed
    case dataParsingError
    case saveFailed
    
    var localizedDescription: String {
        switch self {
        case .userNotFound:
            return "User not found or not logged in"
        case .connectionFailed:
            return "Failed to connect to Firebase"
        case .dataParsingError:
            return "Failed to parse data from Firebase"
        case .saveFailed:
            return "Failed to save data to Firebase"
        }
    }
} 