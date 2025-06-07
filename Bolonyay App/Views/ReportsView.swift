import SwiftUI
import UIKit

// MARK: - Reports View
struct ReportsView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab: ReportsTab = .overview
    @State private var isLoading = false
    @State private var cases: [FirebaseManager.CaseRecord] = []
    @State private var sessions: [FirebaseManager.ConversationSession] = []
    @State private var statistics: CaseStatistics?
    @State private var errorMessage: String?
    @State private var isAnimated = false
    
    enum ReportsTab: String, CaseIterable {
        case overview = "Overview"
        case cases = "My Cases"
        case sessions = "Sessions"
        case analytics = "Analytics"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .cases: return "folder.fill"
            case .sessions: return "message.fill"
            case .analytics: return "chart.pie.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                ReportsHeaderView(
                    selectedTab: $selectedTab,
                    isAnimated: $isAnimated
                )
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .overview:
                            OverviewContent(
                                cases: cases,
                                sessions: sessions,
                                statistics: statistics,
                                isAnimated: isAnimated
                            )
                            
                        case .cases:
                            CasesContent(
                                cases: cases,
                                isAnimated: isAnimated,
                                onRefresh: { await loadCases() }
                            )
                            
                        case .sessions:
                            SessionsContent(
                                sessions: sessions,
                                isAnimated: isAnimated,
                                onRefresh: { await loadSessions() }
                            )
                            
                        case .analytics:
                            AnalyticsContent(
                                statistics: statistics,
                                cases: cases,
                                isAnimated: isAnimated
                            )
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .refreshable {
                    await loadAllData()
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.blue.opacity(0.1),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                isAnimated = true
            }
            
            Task {
                await loadAllData()
            }
        }
        .overlay {
            if isLoading {
                LoadingOverlay()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Data Loading
    
    private func loadAllData() async {
        // Ensure user exists before loading any data
        await ensureUserExists()
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadCases() }
            group.addTask { await loadSessions() }
            group.addTask { await loadStatistics() }
        }
    }
    
    private func ensureUserExists() async {
        // Check if user already exists
        if firebaseManager.getCurrentUser() != nil {
            return // User already exists
        }
        
        // Create a user for reports access
        do {
            let deviceName = UIDevice.current.name
            let userName = deviceName.isEmpty ? "BoloNyay User" : deviceName
            
            let user = try await firebaseManager.createUser(
                email: nil,
                name: userName,
                userType: .petitioner,
                language: localizationManager.currentLanguage
            )
            print("✅ Auto-created user for reports: \(user.name)")
        } catch {
            print("❌ Failed to create user for reports: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create user account: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadCases() async {
        do {
            let fetchedCases = try await firebaseManager.getUserCases()
            DispatchQueue.main.async {
                self.cases = fetchedCases
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load cases: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadSessions() async {
        do {
            let fetchedSessions = try await firebaseManager.getUserSessions()
            DispatchQueue.main.async {
                self.sessions = fetchedSessions
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadStatistics() async {
        do {
            let stats = try await firebaseManager.getCaseStatistics()
            DispatchQueue.main.async {
                self.statistics = stats
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load statistics: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Reports Header View
struct ReportsHeaderView: View {
    @Binding var selectedTab: ReportsView.ReportsTab
    @Binding var isAnimated: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reports & Analytics")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Track your legal journey")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Firebase Connection Status
                HStack(spacing: 6) {
                    Circle()
                        .fill(FirebaseManager.shared.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(FirebaseManager.shared.isConnected ? "Connected" : "Offline")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .scaleEffect(isAnimated ? 1.0 : 0.95)
            .opacity(isAnimated ? 1.0 : 0.0)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.1), value: isAnimated)
            
            // Tab Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ReportsView.ReportsTab.allCases, id: \.self) { tab in
                        TabButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            action: {
                                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                                    selectedTab = tab
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.95)
            .opacity(isAnimated ? 1.0 : 0.0)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: isAnimated)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
        .background(
            Color.black.opacity(0.3)
                .blur(radius: 10)
        )
    }
}

struct TabButton: View {
    let tab: ReportsView.ReportsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                    .stroke(Color.white.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Overview Content
struct OverviewContent: View {
    let cases: [FirebaseManager.CaseRecord]
    let sessions: [FirebaseManager.ConversationSession]
    let statistics: CaseStatistics?
    let isAnimated: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Quick Stats Cards
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Total Cases",
                    value: "\(cases.count)",
                    icon: "folder.fill",
                    color: .blue,
                    animationDelay: 0.3
                )
                
                StatCard(
                    title: "Active Sessions",
                    value: "\(sessions.count)",
                    icon: "message.fill",
                    color: .green,
                    animationDelay: 0.4
                )
                
                StatCard(
                    title: "Filed This Month",
                    value: "\(casesThisMonth)",
                    icon: "calendar.badge.plus",
                    color: .orange,
                    animationDelay: 0.5
                )
                
                StatCard(
                    title: "Success Rate",
                    value: "\(Int(successRate))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple,
                    animationDelay: 0.6
                )
            }
            
            // Recent Cases
            if !cases.isEmpty {
                RecentCasesSection(
                    cases: Array(cases.prefix(3)),
                    animationDelay: 0.7
                )
            }
            
            // Quick Actions
            QuickActionsSection(animationDelay: 0.8)
        }
    }
    
    private var casesThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return cases.filter { calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month) }.count
    }
    
    private var successRate: Double {
        guard !cases.isEmpty else { return 0 }
        let completedCases = cases.filter { $0.status == .completed }.count
        return (Double(completedCases) / Double(cases.count)) * 100
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let animationDelay: Double
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(color.opacity(0.3), lineWidth: 1)
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(duration: 0.6, bounce: 0.4).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Cases Content
struct CasesContent: View {
    let cases: [FirebaseManager.CaseRecord]
    let isAnimated: Bool
    let onRefresh: () async -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("My Legal Cases")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    Task { await onRefresh() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            if cases.isEmpty {
                EmptyStateView(
                    icon: "folder.badge.plus",
                    title: "No Cases Filed",
                    message: "Start your legal journey by filing your first case using the voice assistant.",
                    animationDelay: 0.5,
                    isAnimated: isAnimated
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(cases.enumerated()), id: \.element.id) { index, caseRecord in
                        CaseCard(
                            caseRecord: caseRecord,
                            animationDelay: Double(index) * 0.1
                        )
                    }
                }
            }
        }
    }
}

struct CaseCard: View {
    let caseRecord: FirebaseManager.CaseRecord
    let animationDelay: Double
    @State private var isVisible = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(caseRecord.caseNumber)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(caseRecord.caseType)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: caseRecord.status)
                    
                    Text(formatDate(caseRecord.createdAt))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Case Details
            Text(caseRecord.caseDetails)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(isExpanded ? nil : 2)
            
            // Expand Button
            Button(action: {
                withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if !caseRecord.userResponses.isEmpty {
                        Text("Responses: \(caseRecord.userResponses.filter { !$0.isEmpty }.count)/\(caseRecord.filingQuestions.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Language:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(caseRecord.language.capitalized)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if let azureId = caseRecord.azureSessionId, !azureId.isEmpty {
                            Label("Azure Connected", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(statusColor(caseRecord.status).opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func statusColor(_ status: FirebaseManager.CaseRecord.CaseStatus) -> Color {
        switch status {
        case .filed: return .blue
        case .underReview: return .orange
        case .pending: return .yellow
        case .completed: return .green
        case .rejected: return .red
        }
    }
}

struct StatusBadge: View {
    let status: FirebaseManager.CaseRecord.CaseStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.8))
            )
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

// MARK: - Sessions Content
struct SessionsContent: View {
    let sessions: [FirebaseManager.ConversationSession]
    let isAnimated: Bool
    let onRefresh: () async -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Conversation Sessions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    Task { await onRefresh() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            if sessions.isEmpty {
                EmptyStateView(
                    icon: "message.badge.plus",
                    title: "No Sessions Found",
                    message: "Your conversation sessions will appear here after using the voice assistant.",
                    animationDelay: 0.5,
                    isAnimated: isAnimated
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                        SessionCard(
                            session: session,
                            animationDelay: Double(index) * 0.1
                        )
                    }
                }
            }
        }
    }
}

struct SessionCard: View {
    let session: FirebaseManager.ConversationSession
    let animationDelay: Double
    @State private var isVisible = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(formatDate(session.startedAt))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(session.totalMessages) messages")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text(session.language.capitalized)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Case Number (if available)
            if let caseNumber = session.caseNumber, !caseNumber.isEmpty {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                    
                    Text("Filed as: \(caseNumber)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            
            // Expand Button
            Button(action: {
                withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Hide Messages" : "View Messages")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Messages (when expanded)
            if isExpanded {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(session.messages.prefix(5).enumerated()), id: \.element.id) { index, message in
                            MessageRow(message: message)
                        }
                        
                        if session.messages.count > 5 {
                            Text("... and \(session.messages.count - 5) more messages")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 4)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MessageRow: View {
    let message: FirebaseManager.ConversationSession.SessionMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: message.type == .userTranscription ? "person.fill" : "brain.head.profile")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(message.type == .userTranscription ? .blue : .green)
                .frame(width: 16)
            
            Text(message.content)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Analytics Content
struct AnalyticsContent: View {
    let statistics: CaseStatistics?
    let cases: [FirebaseManager.CaseRecord]
    let isAnimated: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Case Analytics")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            if let stats = statistics {
                VStack(spacing: 20) {
                    // Status Distribution
                    AnalyticsCard(
                        title: "Cases by Status",
                        data: stats.casesByStatus,
                        animationDelay: 0.3
                    )
                    
                    // Type Distribution
                    AnalyticsCard(
                        title: "Cases by Type",
                        data: stats.casesByType,
                        animationDelay: 0.4
                    )
                    
                    // Language Distribution
                    AnalyticsCard(
                        title: "Cases by Language",
                        data: stats.casesByLanguage,
                        animationDelay: 0.5
                    )
                }
            } else {
                EmptyStateView(
                    icon: "chart.pie.fill",
                    title: "No Analytics Data",
                    message: "Analytics will be available once you file some cases.",
                    animationDelay: 0.5,
                    isAnimated: isAnimated
                )
            }
        }
    }
}

struct AnalyticsCard: View {
    let title: String
    let data: [String: Int]
    let animationDelay: Double
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            if data.isEmpty {
                Text("No data available")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(data.sorted(by: { $0.value > $1.value })), id: \.key) { key, value in
                        HStack {
                            Text(key.capitalized.replacingOccurrences(of: "_", with: " "))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(value)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Supporting Views

struct RecentCasesSection: View {
    let cases: [FirebaseManager.CaseRecord]
    let animationDelay: Double
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Cases")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(cases, id: \.id) { caseRecord in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(caseRecord.caseNumber)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(caseRecord.caseType)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        StatusBadge(status: caseRecord.status)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.03))
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

struct QuickActionsSection: View {
    let animationDelay: Double
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                QuickActionButton(
                    title: "Export Report",
                    icon: "square.and.arrow.up",
                    color: .blue,
                    action: { /* Export functionality */ }
                )
                
                QuickActionButton(
                    title: "Download PDF",
                    icon: "doc.text.fill",
                    color: .green,
                    action: { /* PDF download */ }
                )
                
                QuickActionButton(
                    title: "Share Analytics",
                    icon: "chart.bar.xaxis",
                    color: .purple,
                    action: { /* Share functionality */ }
                )
            }
        }
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}



struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("Loading Reports...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

 