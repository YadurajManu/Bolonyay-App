//
//  EnhancedReportsComponents.swift
//  Bolonyay App
//
//  Created by Enhanced Reports System
//

import SwiftUI
import PDFKit

// MARK: - Enhanced Saved Reports View
struct EnhancedSavedReportsView: View {
    @StateObject private var reportsManager = ReportsManager.shared
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedReport: ReportsManager.SavedReport?
    @State private var showingReportPreview = false
    @State private var showingShareSheet = false
    @State private var searchText = ""
    @State private var selectedFilter: ReportFilter = .all
    @State private var isAnimated = false
    
    enum ReportFilter: String, CaseIterable {
        case all = "All Reports"
        case recent = "Recent"
        case byType = "By Type"
        case byLanguage = "By Language"
        
        var icon: String {
            switch self {
            case .all: return "doc.text.fill"
            case .recent: return "clock.fill"
            case .byType: return "folder.fill"
            case .byLanguage: return "globe"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Search and Filters
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📄 Saved Reports")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(filteredReports.count) reports • \(reportsManager.getFormattedStorageUsed())")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Storage Info Button
                    Button(action: {
                        // Show storage details
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "internaldrive.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Storage")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                }
                
                // Search Bar
                HStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        TextField("Search reports...", text: $searchText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .accentColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Filter Button
                    Menu {
                        ForEach(ReportFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                    selectedFilter = filter
                                }
                            }) {
                                HStack {
                                    Image(systemName: filter.icon)
                                    Text(filter.rawValue)
                                    if selectedFilter == filter {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: selectedFilter.icon)
                            Image(systemName: "chevron.down")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .opacity(isAnimated ? 1.0 : 0.0)
            .offset(y: isAnimated ? 0 : -20)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.1), value: isAnimated)
            
            // Reports List
            ScrollView {
                LazyVStack(spacing: 16) {
                    if filteredReports.isEmpty {
                        EmptyReportsView()
                            .padding(.top, 60)
                    } else {
                        ForEach(Array(filteredReports.enumerated()), id: \.element.id) { index, report in
                            EnhancedReportCard(
                                report: report,
                                animationDelay: 0.3 + Double(index) * 0.1,
                                onDownload: { downloadReport(report) },
                                onShare: { shareReport(report) },
                                onDelete: { deleteReport(report) },
                                onPreview: { previewReport(report) }
                            )
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                isAnimated = true
            }
        }
        .sheet(isPresented: $showingReportPreview) {
            if let report = selectedReport,
               let fileURL = reportsManager.shareReport(report) {
                PDFPreviewView(pdfURL: fileURL)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let report = selectedReport,
               let fileURL = reportsManager.shareReport(report) {
                ShareSheet(items: [fileURL])
            }
        }
    }
    
    private var filteredReports: [ReportsManager.SavedReport] {
        var reports = reportsManager.savedReports
        
        // Apply search filter
        if !searchText.isEmpty {
            reports = reportsManager.searchReports(query: searchText)
        }
        
        // Apply selected filter
        switch selectedFilter {
        case .all:
            break
        case .recent:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            reports = reports.filter { $0.createdAt >= oneWeekAgo }
        case .byType:
            reports = reports.sorted { $0.caseType < $1.caseType }
        case .byLanguage:
            reports = reports.sorted { $0.metadata.language < $1.metadata.language }
        }
        
        return reports
    }
    
    private func downloadReport(_ report: ReportsManager.SavedReport) {
        // Mark as accessed
        reportsManager.markReportAsAccessed(report)
        
        // Open with system default app
        if let fileURL = reportsManager.shareReport(report) {
            let documentController = UIDocumentInteractionController(url: fileURL)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                documentController.presentOpenInMenu(from: CGRect.zero, in: rootViewController.view, animated: true)
            }
        }
    }
    
    private func shareReport(_ report: ReportsManager.SavedReport) {
        selectedReport = report
        showingShareSheet = true
    }
    
    private func deleteReport(_ report: ReportsManager.SavedReport) {
        withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
            reportsManager.deleteReport(report)
        }
    }
    
    private func previewReport(_ report: ReportsManager.SavedReport) {
        selectedReport = report
        reportsManager.markReportAsAccessed(report)
        showingReportPreview = true
    }
}

// MARK: - Enhanced Report Card
struct EnhancedReportCard: View {
    let report: ReportsManager.SavedReport
    let animationDelay: Double
    let onDownload: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    let onPreview: () -> Void
    
    @State private var isVisible = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                // File Type Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(getTypeColor().opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: getTypeIcon())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(getTypeColor())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.reportTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(report.caseNumber)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 3, height: 3)
                        
                        Text(report.timeSinceCreation)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Status Badge
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Downloaded")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            
            // File Info
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("\(report.metadata.pageCount) pages")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(report.formattedFileSize)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(report.metadata.language.uppercased())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            // Tags
            if !report.metadata.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(report.metadata.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                // Preview Button
                Button(action: onPreview) {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 14))
                        Text("Preview")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                }
                
                // Download Button
                Button(action: onDownload) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14))
                        Text("Open")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green)
                    )
                }
                
                // More Options Menu
                Menu {
                    Button(action: onShare) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                    }
                    
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(8)
                }
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
        .offset(y: isVisible ? 0 : 20)
        .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
        .alert("Delete Report", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this report? This action cannot be undone.")
        }
    }
    
    private func getTypeColor() -> Color {
        let caseTypeLower = report.caseType.lowercased()
        if caseTypeLower.contains("criminal") {
            return .red
        } else if caseTypeLower.contains("civil") {
            return .blue
        } else if caseTypeLower.contains("family") {
            return .purple
        } else if caseTypeLower.contains("consumer") {
            return .orange
        } else if caseTypeLower.contains("labor") {
            return .green
        } else {
            return .cyan
        }
    }
    
    private func getTypeIcon() -> String {
        let caseTypeLower = report.caseType.lowercased()
        if caseTypeLower.contains("criminal") {
            return "shield.fill"
        } else if caseTypeLower.contains("civil") {
            return "scale.3d"
        } else if caseTypeLower.contains("family") {
            return "house.fill"
        } else if caseTypeLower.contains("consumer") {
            return "cart.fill"
        } else if caseTypeLower.contains("labor") {
            return "briefcase.fill"
        } else {
            return "doc.text.fill"
        }
    }
}

// MARK: - Empty Reports View
struct EmptyReportsView: View {
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .scaleEffect(isAnimated ? 1.0 : 0.8)
            .animation(.spring(duration: 1.0, bounce: 0.4).delay(0.1), value: isAnimated)
            
            VStack(spacing: 12) {
                Text("No Saved Reports")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your downloaded PDF reports will appear here.\nGenerate your first legal document to get started.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(isAnimated ? 1.0 : 0.0)
            .offset(y: isAnimated ? 0 : 20)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.3), value: isAnimated)
        }
        .onAppear {
            isAnimated = true
        }
    }
}

// MARK: - Reports Statistics View
struct ReportsStatisticsView: View {
    let statistics: ReportsStatistics
    let animationDelay: Double
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("📊 Reports Statistics")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Total Reports",
                    value: "\(statistics.totalReports)",
                    icon: "doc.text.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Storage Used",
                    value: statistics.formattedTotalStorage,
                    icon: "internaldrive.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Average Size",
                    value: statistics.formattedAverageFileSize,
                    icon: "chart.bar.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Languages",
                    value: "\(statistics.reportsByLanguage.count)",
                    icon: "globe",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
} 