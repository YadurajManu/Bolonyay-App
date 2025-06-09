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
        case overview = "overview"
        case savedReports = "saved_reports"
        case cases = "cases"
        case sessions = "sessions"
        case analytics = "analytics"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .savedReports: return "doc.text.fill"
            case .cases: return "folder.fill"
            case .sessions: return "message.fill"
            case .analytics: return "chart.pie.fill"
            }
        }
        
        func localizedName(_ localizationManager: LocalizationManager) -> String {
            switch self {
            case .overview: return localizationManager.text("overview")
            case .savedReports: return "Saved Reports"
            case .cases: return localizationManager.text("my_cases")
            case .sessions: return localizationManager.text("sessions")
            case .analytics: return localizationManager.text("analytics")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                ElegantReportsHeader(
                    selectedTab: $selectedTab,
                    isAnimated: $isAnimated,
                    localizationManager: localizationManager
                )
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch selectedTab {
                        case .overview:
                            ElegantOverviewContent(
                                cases: cases,
                                sessions: sessions,
                                statistics: statistics,
                                isAnimated: isAnimated,
                                localizationManager: localizationManager
                            )
                            
                        case .savedReports:
                            EnhancedSavedReportsView()
                                .environmentObject(localizationManager)
                            
                        case .cases:
                            ElegantCasesContent(
                                cases: cases,
                                isAnimated: isAnimated,
                                localizationManager: localizationManager,
                                onRefresh: { await loadCases() }
                            )
                            
                        case .sessions:
                            ElegantSessionsContent(
                                sessions: sessions,
                                isAnimated: isAnimated,
                                localizationManager: localizationManager,
                                onRefresh: { await loadSessions() }
                            )
                            
                        case .analytics:
                            ElegantAnalyticsContent(
                                statistics: statistics,
                                cases: cases,
                                isAnimated: isAnimated,
                                localizationManager: localizationManager
                            )
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
                .refreshable {
                    await loadAllData()
                }
            }
            .background(Color.black.ignoresSafeArea())
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
                ElegantLoadingOverlay()
            }
        }
        .alert(localizationManager.text("error"), isPresented: .constant(errorMessage != nil)) {
            Button(localizationManager.text("ok")) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Data Loading
    
    private func loadAllData() async {
        await ensureUserExists()
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadCases() }
            group.addTask { await loadSessions() }
            group.addTask { await loadStatistics() }
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

// MARK: - Elegant Reports Header
struct ElegantReportsHeader: View {
    @Binding var selectedTab: ReportsView.ReportsTab
    @Binding var isAnimated: Bool
    let localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 32) {
            // Title Section
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.text("reports"))
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundColor(.white)
                        
                        Text(localizationManager.text("track_legal_journey"))
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Connection Status
                    HStack(spacing: 8) {
                        Circle()
                            .fill(FirebaseManager.shared.isConnected ? Color.white : Color.red)
                            .frame(width: 6, height: 6)
                        
                        Text(FirebaseManager.shared.isConnected ? 
                             localizationManager.text("connected") : 
                             localizationManager.text("offline"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Elegant Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.95)
            .opacity(isAnimated ? 1.0 : 0.0)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.1), value: isAnimated)
            
            // Tab Selector
            ElegantTabSelector(
                tabs: ReportsView.ReportsTab.allCases,
                selectedTab: $selectedTab,
                localizationManager: localizationManager,
                isAnimated: isAnimated
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}

// MARK: - Elegant Tab Selector
struct ElegantTabSelector: View {
    let tabs: [ReportsView.ReportsTab]
    @Binding var selectedTab: ReportsView.ReportsTab
    let localizationManager: LocalizationManager
    let isAnimated: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                ElegantTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    localizationManager: localizationManager,
                    action: {
                        withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                            selectedTab = tab
                        }
                    }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isAnimated ? 1.0 : 0.95)
        .opacity(isAnimated ? 1.0 : 0.0)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: isAnimated)
    }
}

struct ElegantTabButton: View {
    let tab: ReportsView.ReportsTab
    let isSelected: Bool
    let localizationManager: LocalizationManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.6))
                
                Text(tab.localizedName(localizationManager))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Elegant Overview Content
struct ElegantOverviewContent: View {
    let cases: [FirebaseManager.CaseRecord]
    let sessions: [FirebaseManager.ConversationSession]
    let statistics: CaseStatistics?
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 32) {
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ElegantStatCard(
                    title: localizationManager.text("total_cases"),
                    value: "\(cases.count)",
                    icon: "folder.fill",
                    animationDelay: 0.3
                )
                
                ElegantStatCard(
                    title: localizationManager.text("sessions"),
                    value: "\(sessions.count)",
                    icon: "message.fill",
                    animationDelay: 0.4
                )
                
                ElegantStatCard(
                    title: localizationManager.text("filed_cases"),
                    value: "\(filedCasesCount)",
                    icon: "checkmark.circle.fill",
                    animationDelay: 0.5
                )
                
                ElegantStatCard(
                    title: localizationManager.text("success_rate"),
                    value: "\(Int(successRate))%",
                    icon: "chart.line.uptrend.xyaxis",
                    animationDelay: 0.6
                )
            }
            
            // Recent Activity
            if !cases.isEmpty || !sessions.isEmpty {
                ElegantRecentActivity(
                    cases: Array(cases.prefix(3)),
                    sessions: Array(sessions.prefix(2)),
                    localizationManager: localizationManager,
                    animationDelay: 0.7
                )
            }
        }
    }
    
    private var filedCasesCount: Int {
        cases.filter { $0.status == .filed }.count
    }
    
    private var successRate: Double {
        guard !cases.isEmpty else { return 0 }
        let completedCases = cases.filter { $0.status == .completed }.count
        return (Double(completedCases) / Double(cases.count)) * 100
    }
}

// MARK: - Elegant Stat Card
struct ElegantStatCard: View {
    let title: String
    let value: String
    let icon: String
    let animationDelay: Double
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Elegant Recent Activity
struct ElegantRecentActivity: View {
    let cases: [FirebaseManager.CaseRecord]
    let sessions: [FirebaseManager.ConversationSession]
    let localizationManager: LocalizationManager
    let animationDelay: Double
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(localizationManager.text("recent_activity"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(cases.enumerated()), id: \.element.id) { index, caseRecord in
                    ElegantActivityItem(
                        title: caseRecord.caseNumber,
                        subtitle: caseRecord.caseType,
                        icon: "folder.fill",
                        date: caseRecord.createdAt,
                        animationDelay: animationDelay + Double(index) * 0.1
                    )
                }
                
                ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                    ElegantActivityItem(
                        title: localizationManager.text("conversation_session"),
                        subtitle: "\(session.totalMessages) " + localizationManager.text("messages"),
                        icon: "message.fill",
                        date: session.startedAt,
                        animationDelay: animationDelay + Double(cases.count + index) * 0.1
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

struct ElegantActivityItem: View {
    let title: String
    let subtitle: String
    let icon: String
    let date: Date
    let animationDelay: Double
    @State private var isVisible = false
    
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(DateFormatter.elegantShort.string(from: date))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Elegant Cases Content
struct ElegantCasesContent: View {
    let cases: [FirebaseManager.CaseRecord]
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    let onRefresh: () async -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text(localizationManager.text("my_cases"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(cases.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if cases.isEmpty {
                ElegantEmptyState(
                    icon: "folder.badge.plus",
                    title: localizationManager.text("no_cases"),
                    subtitle: localizationManager.text("file_first_case"),
                    animationDelay: 0.3
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(cases.enumerated()), id: \.element.id) { index, caseRecord in
                        ElegantCaseCard(
                            caseRecord: caseRecord,
                            localizationManager: localizationManager,
                            animationDelay: Double(index) * 0.1
                        )
                    }
                }
            }
        }
    }
}

struct ElegantCaseCard: View {
    let caseRecord: FirebaseManager.CaseRecord
    let localizationManager: LocalizationManager
    let animationDelay: Double
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(caseRecord.caseNumber)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(caseRecord.caseType)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                ElegantStatusBadge(status: caseRecord.status, localizationManager: localizationManager)
            }
            
            Text(caseRecord.caseDetails)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)
            
            HStack {
                Text(DateFormatter.elegant.string(from: caseRecord.createdAt))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text(caseRecord.language.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
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

struct ElegantStatusBadge: View {
    let status: FirebaseManager.CaseRecord.CaseStatus
    let localizationManager: LocalizationManager
    
    var body: some View {
        Text(statusText)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(statusColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor.opacity(0.15))
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var statusText: String {
        switch status {
        case .filed: return localizationManager.text("filed")
        case .underReview: return localizationManager.text("under_review")
        case .pending: return localizationManager.text("pending")
        case .completed: return localizationManager.text("completed")
        case .rejected: return localizationManager.text("rejected")
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

// MARK: - Elegant Sessions Content
struct ElegantSessionsContent: View {
    let sessions: [FirebaseManager.ConversationSession]
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    let onRefresh: () async -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text(localizationManager.text("sessions"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(sessions.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if sessions.isEmpty {
                ElegantEmptyState(
                    icon: "message.badge.plus",
                    title: localizationManager.text("no_sessions"),
                    subtitle: localizationManager.text("start_conversation"),
                    animationDelay: 0.3
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                        ElegantSessionCard(
                            session: session,
                            localizationManager: localizationManager,
                            animationDelay: Double(index) * 0.1
                        )
                    }
                }
            }
        }
    }
}

struct ElegantSessionCard: View {
    let session: FirebaseManager.ConversationSession
    let localizationManager: LocalizationManager
    let animationDelay: Double
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.text("session"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(session.id.prefix(8).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("\(session.totalMessages)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("\(session.totalMessages) " + localizationManager.text("messages"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(session.language.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            Text(DateFormatter.elegant.string(from: session.startedAt))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
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

// MARK: - Elegant Analytics Content
struct ElegantAnalyticsContent: View {
    let statistics: CaseStatistics?
    let cases: [FirebaseManager.CaseRecord]
    let isAnimated: Bool
    let localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Text(localizationManager.text("analytics"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let stats = statistics {
                VStack(spacing: 24) {
                    // Cases by Status
                    ElegantAnalyticsSection(
                        title: localizationManager.text("cases_by_status"),
                        data: stats.casesByStatus,
                        localizationManager: localizationManager,
                        animationDelay: 0.3
                    )
                    
                    // Cases by Type
                    ElegantAnalyticsSection(
                        title: localizationManager.text("cases_by_type"),
                        data: stats.casesByType,
                        localizationManager: localizationManager,
                        animationDelay: 0.5
                    )
                    
                    // Cases by Language
                    ElegantAnalyticsSection(
                        title: localizationManager.text("cases_by_language"),
                        data: stats.casesByLanguage,
                        localizationManager: localizationManager,
                        animationDelay: 0.7
                    )
                }
            } else {
                ElegantEmptyState(
                    icon: "chart.bar.fill",
                    title: localizationManager.text("no_analytics"),
                    subtitle: localizationManager.text("analytics_available_after_cases"),
                    animationDelay: 0.3
                )
            }
        }
    }
}

struct ElegantAnalyticsSection: View {
    let title: String
    let data: [String: Int]
    let localizationManager: LocalizationManager
    let animationDelay: Double
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(data.sorted(by: { $0.value > $1.value }).enumerated()), id: \.element.key) { index, item in
                    ElegantAnalyticsRow(
                        label: item.key,
                        value: item.value,
                        total: data.values.reduce(0, +),
                        animationDelay: animationDelay + Double(index) * 0.1
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

struct ElegantAnalyticsRow: View {
    let label: String
    let value: Int
    let total: Int
    let animationDelay: Double
    @State private var isVisible = false
    @State private var animateBar = false
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(value)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("(\(Int(percentage * 100))%)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: animateBar ? geometry.size.width * percentage : 0, height: 6)
                        .animation(.easeInOut(duration: 1.0).delay(animationDelay), value: animateBar)
                }
            }
            .frame(height: 6)
        }
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                animateBar = true
            }
        }
    }
}

// MARK: - Elegant Empty State
struct ElegantEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let animationDelay: Double
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.white.opacity(0.4))
                )
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Elegant Loading Overlay
struct ElegantLoadingOverlay: View {
    @State private var rotation = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(Color.white, lineWidth: 3)
                            .rotationEffect(.degrees(rotation))
                    )
                    .onAppear {
                        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                
                Text("Loading...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Date Formatter Extensions
extension DateFormatter {
    static let elegant: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let elegantShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter
    }()
}

 