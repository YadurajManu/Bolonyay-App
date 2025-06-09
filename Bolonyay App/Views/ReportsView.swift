import SwiftUI
import UIKit
import PDFKit

// MARK: - Reports View
struct ReportsView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var pdfManager = PDFGenerationManager.shared
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var cases: [FirebaseManager.CaseRecord] = []
    @State private var sessions: [FirebaseManager.ConversationSession] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingPDFPreview = false
    @State private var generatedPDFURL: URL?
    @State private var showingShareSheet = false
    @State private var isGeneratingPDF = false
    @State private var selectedCase: FirebaseManager.CaseRecord?
    @State private var showingDetailedCaseView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with PDF export
                        headerView
                        
                        // Stats
                        statsView
                        
                        // Detailed Cases View
                        if !cases.isEmpty {
                            detailedCasesView
                        }
                        
                        // PDF Export Section
                        pdfExportSection
                        
                        Spacer(minLength: 100)
                    }
                }
                .refreshable {
                    await loadData()
                }
                
                // Loading overlay
                if isGeneratingPDF {
                    loadingOverlay
            }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task { await loadData() }
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfURL = generatedPDFURL {
                ReportPDFPreviewView(pdfURL: pdfURL, showingShareSheet: $showingShareSheet)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfURL = generatedPDFURL {
                ReportShareSheet(items: [pdfURL])
            }
        }
        .sheet(isPresented: $showingDetailedCaseView) {
            if let selectedCase = selectedCase {
                DetailedCaseView(caseRecord: selectedCase)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 24) {
                HStack {
                Text("रिपोर्ट")
                    .font(.system(size: 28, weight: .light))
                            .foregroundColor(.white)
                    
                    Spacer()
                    
                HStack(spacing: 16) {
                    // PDF Export Button
                    Button(action: generatePDFReport) {
                        Image(systemName: "doc.badge.arrow.up")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    .disabled(isGeneratingPDF)
                    
                    statusIndicator
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(firebaseManager.isConnected ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            
            Text(firebaseManager.isConnected ? "connected" : "offline")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }
    
    // MARK: - Stats
    
    private var statsView: some View {
        VStack(spacing: 32) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                MinimalStatCard(
                    title: "मामले",
                    value: "\(cases.count)",
                    icon: "folder"
                )
                
                MinimalStatCard(
                    title: "सत्र",
                    value: "\(sessions.count)",
                    icon: "message"
                )
                
                MinimalStatCard(
                    title: "दायर",
                    value: "\(filedCount)",
                    icon: "checkmark.circle"
                )
                
                MinimalStatCard(
                    title: "सफलता",
                    value: "\(successRate)%",
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }
    
    // MARK: - Detailed Cases View
    
    private var detailedCasesView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("सभी मामले")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(cases.count) कुल")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            LazyVStack(spacing: 16) {
                ForEach(cases, id: \.id) { caseRecord in
                    DetailedCaseCard(caseRecord: caseRecord) {
                        selectedCase = caseRecord
                        showingDetailedCaseView = true
                    } onDownloadPDF: {
                        generatePDFForCase(caseRecord)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }
    
    // MARK: - PDF Export Section
    
    private var pdfExportSection: some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("PDF रिपोर्ट")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("अपनी सभी केसों और आंकड़ों की विस्तृत रिपोर्ट डाउनलोड करें")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button("डाउनलोड") {
                        generatePDFReport()
                    }
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(isGeneratingPDF)
                    
                    if generatedPDFURL != nil {
                        Button("शेयर") {
                            showingShareSheet = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("PDF तैयार कर रहे हैं...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.black.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Computed Properties
    
    private var filedCount: Int {
        cases.filter { $0.status == .filed }.count
    }
    
    private var successRate: Int {
        guard !cases.isEmpty else { return 0 }
        let completed = cases.filter { $0.status == .completed }.count
        return Int((Double(completed) / Double(cases.count)) * 100)
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let _ = try await firebaseManager.ensureUserFromAuth()
            let fetchedCases = try await firebaseManager.getUserCases()
            let fetchedSessions = try await firebaseManager.getUserSessions()
            
            DispatchQueue.main.async {
                self.cases = fetchedCases
                self.sessions = fetchedSessions
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - PDF Generation for Individual Cases
    
    private func generatePDFForCase(_ caseRecord: FirebaseManager.CaseRecord) {
        guard let user = firebaseManager.getCurrentUser() else {
            errorMessage = "User not found for PDF generation"
            return
        }
        
        isGeneratingPDF = true
        
        Task {
            do {
                let pdfURL = try await pdfManager.generateLegalCasePDF(for: caseRecord, user: user)
                DispatchQueue.main.async {
                    self.generatedPDFURL = pdfURL
                    self.isGeneratingPDF = false
                    self.showingPDFPreview = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isGeneratingPDF = false
                    self.errorMessage = "PDF generation failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - PDF Generation
    
    private func generatePDFReport() {
        isGeneratingPDF = true
        
        Task {
            do {
                let pdfURL = try await createPDFReport()
                DispatchQueue.main.async {
                    self.generatedPDFURL = pdfURL
                    self.isGeneratingPDF = false
                    self.showingPDFPreview = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isGeneratingPDF = false
                    self.errorMessage = "PDF generation failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func createPDFReport() async throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsPath.appendingPathComponent("BoloNyay_Report_\(Date().timeIntervalSince1970).pdf")
        
        try renderer.writePDF(to: pdfURL) { context in
            var currentY: CGFloat = 50
            
            // Start first page
            context.beginPage()
            
            // Header
            currentY = drawHeader(in: context, at: currentY)
            currentY += 30
            
            // Statistics Section
            currentY = drawStatistics(in: context, at: currentY)
            currentY += 30
            
            // Cases Section
            if !cases.isEmpty {
                currentY = drawCases(in: context, at: currentY)
                currentY += 30
            }
            
            // Sessions Section
            if !sessions.isEmpty {
                currentY = drawSessions(in: context, at: currentY)
            }
        }
        
        return pdfURL
    }
    
    private func drawHeader(in context: UIGraphicsPDFRendererContext, at y: CGFloat) -> CGFloat {
        var currentY = y
        
        // Title
        let titleText = "न्याय रिपोर्ट"
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let titleSize = titleText.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: (612 - titleSize.width) / 2, y: currentY, width: titleSize.width, height: titleSize.height)
        titleText.draw(in: titleRect, withAttributes: titleAttributes)
        currentY += titleSize.height + 10
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.locale = Locale(identifier: "hi_IN")
        let dateText = "रिपोर्ट दिनांक: \(dateFormatter.string(from: Date()))"
        let dateFont = UIFont.systemFont(ofSize: 12)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.gray
        ]
        
        let dateSize = dateText.size(withAttributes: dateAttributes)
        let dateRect = CGRect(x: (612 - dateSize.width) / 2, y: currentY, width: dateSize.width, height: dateSize.height)
        dateText.draw(in: dateRect, withAttributes: dateAttributes)
        currentY += dateSize.height + 20
        
        // Line separator
        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        context.cgContext.setLineWidth(1)
        context.cgContext.move(to: CGPoint(x: 50, y: currentY))
        context.cgContext.addLine(to: CGPoint(x: 562, y: currentY))
        context.cgContext.strokePath()
        
        return currentY + 10
    }
    
    private func drawStatistics(in context: UIGraphicsPDFRendererContext, at y: CGFloat) -> CGFloat {
        var currentY = y
        
        // Section title
        let sectionFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: UIColor.black
        ]
        
        "आंकड़े".draw(at: CGPoint(x: 50, y: currentY), withAttributes: sectionAttributes)
        currentY += 30
        
        // Stats grid
        let stats = [
            ("कुल मामले", "\(cases.count)"),
            ("कुल सत्र", "\(sessions.count)"),
            ("दायर मामले", "\(filedCount)"),
            ("सफलता दर", "\(successRate)%")
        ]
        
        let statFont = UIFont.systemFont(ofSize: 14)
        let statValueFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        
        for (index, (title, value)) in stats.enumerated() {
            let x = 50 + CGFloat((index % 2) * 250)
            let rowY = currentY + CGFloat((index / 2) * 50)
            
            // Title
            title.draw(at: CGPoint(x: x, y: rowY), withAttributes: [
                .font: statFont,
                .foregroundColor: UIColor.gray
            ])
            
            // Value
            value.draw(at: CGPoint(x: x, y: rowY + 20.0), withAttributes: [
                .font: statValueFont,
                .foregroundColor: UIColor.black
            ])
        }
        
        return currentY + 100
    }
    
    private func drawCases(in context: UIGraphicsPDFRendererContext, at y: CGFloat) -> CGFloat {
        var currentY = y
        
        // Section title
        let sectionFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: UIColor.black
        ]
        
        "मामलों की सूची".draw(at: CGPoint(x: 50, y: currentY), withAttributes: sectionAttributes)
        currentY += 30
        
        // Table headers
        let headerFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        let cellFont = UIFont.systemFont(ofSize: 11)
        
        let headers = ["केस नंबर", "प्रकार", "स्थिति", "दिनांक"]
        let columnWidths: [CGFloat] = [120, 150, 100, 120]
        var x: CGFloat = 50
        
        for (header, width) in zip(headers, columnWidths) {
            header.draw(at: CGPoint(x: x, y: currentY), withAttributes: [
                .font: headerFont,
                .foregroundColor: UIColor.black
            ])
            x += width
        }
        currentY += 25
        
        // Table rows
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for caseRecord in cases.prefix(20) { // Limit to 20 cases for PDF
            x = 50
            
            let rowData = [
                caseRecord.caseNumber,
                caseRecord.caseType,
                getStatusText(caseRecord.status),
                dateFormatter.string(from: caseRecord.createdAt)
            ]
            
            for (data, width) in zip(rowData, columnWidths) {
                let truncatedData = String(data.prefix(20))
                truncatedData.draw(at: CGPoint(x: x, y: currentY), withAttributes: [
                    .font: cellFont,
                    .foregroundColor: UIColor.darkGray
                ])
                x += width
            }
            currentY += 20.0
            
            // Check if we need a new page
            if currentY > 720.0 {
                context.beginPage()
                currentY = 50.0
            }
        }
        
        return currentY
    }
    
    private func drawSessions(in context: UIGraphicsPDFRendererContext, at y: CGFloat) -> CGFloat {
        var currentY = y
        
        // Section title
        let sectionFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: UIColor.black
        ]
        
        "सत्रों की सूची".draw(at: CGPoint(x: 50, y: currentY), withAttributes: sectionAttributes)
        currentY += 30.0
        
        // Sessions summary
        let sessionFont = UIFont.systemFont(ofSize: 12)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for session in sessions.prefix(10) { // Limit to 10 sessions
            let sessionText = "सत्र: \(session.id.prefix(8)) - \(session.totalMessages) संदेश - \(dateFormatter.string(from: session.startedAt))"
            sessionText.draw(at: CGPoint(x: 50, y: currentY), withAttributes: [
                .font: sessionFont,
                .foregroundColor: UIColor.darkGray
            ])
            currentY += 18.0
            
            // Check if we need a new page
            if currentY > 720.0 {
                context.beginPage()
                currentY = 50
            }
        }
        
        return currentY
    }
    
    private func getStatusText(_ status: FirebaseManager.CaseRecord.CaseStatus) -> String {
        switch status {
        case .pending: return "लंबित"
        case .filed: return "दायर"
        case .underReview: return "समीक्षाधीन"
        case .completed: return "पूर्ण"
        case .rejected: return "अस्वीकृत"
        }
    }
}

// MARK: - Minimal Stat Card

struct MinimalStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Case Row

struct CaseRow: View {
    let caseRecord: FirebaseManager.CaseRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(caseRecord.caseType)
                    .font(.body)
                        .foregroundColor(.white)
                    
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        switch caseRecord.status {
        case .pending: return .yellow
        case .filed: return .blue
        case .underReview: return .orange
        case .completed: return .green
        case .rejected: return .red
        }
    }
    
    private var statusText: String {
        switch caseRecord.status {
        case .pending: return "लंबित"
        case .filed: return "दायर"
        case .underReview: return "समीक्षाधीन"
        case .completed: return "पूर्ण"
        case .rejected: return "अस्वीकृत"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: caseRecord.createdAt)
    }
}

// MARK: - Report PDF Preview View

struct ReportPDFPreviewView: View {
    let pdfURL: URL
    @Binding var showingShareSheet: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                ReportPDFKitView(pdfURL: pdfURL)
            }
            .navigationTitle("PDF रिपोर्ट")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("बंद करें") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("शेयर") {
                        showingShareSheet = true
                    }
                }
            }
        }
    }
}

// MARK: - Report PDFKit View

struct ReportPDFKitView: UIViewRepresentable {
    let pdfURL: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: pdfURL)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Report Share Sheet

struct ReportShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiView: UIActivityViewController, context: Context) {}
}

// MARK: - Detailed Case Card

struct DetailedCaseCard: View {
    let caseRecord: FirebaseManager.CaseRecord
    let onTap: () -> Void
    let onDownloadPDF: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(caseRecord.caseNumber)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(caseRecord.caseType)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                    
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Case Details Preview
            if !caseRecord.caseDetails.isEmpty {
                Text(caseRecord.caseDetails.prefix(120) + (caseRecord.caseDetails.count > 120 ? "..." : ""))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: onTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "eye")
                            .font(.caption)
                        Text("विवरण देखें")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                Button(action: onDownloadPDF) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.badge.arrow.up")
                            .font(.caption)
                        Text("PDF")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                    )
                }
                
                Spacer()
                
                // Case Statistics
                HStack(spacing: 16) {
                    if !caseRecord.filingQuestions.isEmpty {
                        VStack(spacing: 2) {
                            Text("\(caseRecord.filingQuestions.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("सवाल")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    if !caseRecord.userResponses.isEmpty {
                        VStack(spacing: 2) {
                            Text("\(caseRecord.userResponses.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("जवाब")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        switch caseRecord.status {
        case .pending: return .yellow
        case .filed: return .blue
        case .underReview: return .orange
        case .completed: return .green
        case .rejected: return .red
        }
    }
    
    private var statusText: String {
        switch caseRecord.status {
        case .pending: return "लंबित"
        case .filed: return "दायर"
        case .underReview: return "समीक्षाधीन"
        case .completed: return "पूर्ण"
        case .rejected: return "अस्वीकृत"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: caseRecord.createdAt)
    }
}

// MARK: - Detailed Case View

struct DetailedCaseView: View {
    let caseRecord: FirebaseManager.CaseRecord
    @Environment(\.dismiss) private var dismiss
    @StateObject private var pdfManager = PDFGenerationManager.shared
    @State private var showingPDFPreview = false
    @State private var generatedPDFURL: URL?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Info
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(caseRecord.caseNumber)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(statusColor)
                                        .frame(width: 10, height: 10)
                                    
                                    Text(statusText)
                                        .font(.caption)
                                        .foregroundColor(statusColor)
                                }
                            }
                            
                            Text(caseRecord.caseType)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("दिनांक: \(formattedDate)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.bottom, 8)
                        
                        Divider().background(Color.white.opacity(0.2))
                        
                        // Case Details
                        if !caseRecord.caseDetails.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("मामले का विवरण")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(caseRecord.caseDetails)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineSpacing(4)
                            }
                        }
                        
                        // Conversation Summary
                        if !caseRecord.conversationSummary.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("बातचीत का सारांश")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(caseRecord.conversationSummary)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineSpacing(4)
                            }
                        }
                        
                        // Questions and Responses
                        if !caseRecord.filingQuestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("प्रश्न और उत्तर")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                ForEach(Array(zip(caseRecord.filingQuestions, caseRecord.userResponses).enumerated()), id: \.offset) { index, qa in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("प्रश्न \(index + 1):")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                        
                                        Text(qa.0)
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Text("उत्तर:")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.green)
                                        
                                        Text(qa.1)
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                }
                            }
                        }
                        
                        // PDF Download Section
                        VStack(spacing: 16) {
                            Divider().background(Color.white.opacity(0.2))
                            
                            Button(action: generatePDF) {
                                HStack {
                                    Image(systemName: "doc.badge.arrow.up")
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading) {
                                        Text("PDF डाउनलोड करें")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                        
                                        Text("इस मामले की विस्तृत रिपोर्ट")
                                            .font(.caption)
                                            .opacity(0.8)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.2))
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                            }
                            .disabled(pdfManager.isGeneratingPDF)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
                
                // Loading overlay for PDF generation
                if pdfManager.isGeneratingPDF {
                    ZStack {
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("PDF तैयार की जा रही है...")
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.8))
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("बंद करें") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfURL = generatedPDFURL {
                ReportPDFPreviewView(pdfURL: pdfURL, showingShareSheet: .constant(false))
            }
        }
    }
    
    private var statusColor: Color {
        switch caseRecord.status {
        case .pending: return .yellow
        case .filed: return .blue
        case .underReview: return .orange
        case .completed: return .green
        case .rejected: return .red
        }
    }
    
    private var statusText: String {
        switch caseRecord.status {
        case .pending: return "लंबित"
        case .filed: return "दायर"
        case .underReview: return "समीक्षाधीन"
        case .completed: return "पूर्ण"
        case .rejected: return "अस्वीकृत"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "hi_IN")
        return formatter.string(from: caseRecord.createdAt)
    }
    
    private func generatePDF() {
        guard let user = FirebaseManager.shared.getCurrentUser() else {
            return
        }
        
        Task {
            do {
                let pdfURL = try await pdfManager.generateLegalCasePDF(for: caseRecord, user: user)
                DispatchQueue.main.async {
                    self.generatedPDFURL = pdfURL
                    self.showingPDFPreview = true
                }
            } catch {
                print("❌ PDF generation failed: \(error)")
            }
        }
    }
}

// MARK: - Preview

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsView()
            .environmentObject(LocalizationManager())
            .preferredColorScheme(.dark)
    }
}

 