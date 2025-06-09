import Foundation
import PDFKit
import UIKit
import SwiftUI

// MARK: - Reports Manager
class ReportsManager: ObservableObject {
    static let shared = ReportsManager()
    
    private let firebaseManager = FirebaseManager.shared
    private let pdfGenerationManager = PDFGenerationManager.shared
    
    @Published var savedReports: [SavedReport] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        loadSavedReports()
    }
    
    // MARK: - Data Models
    
    struct SavedReport: Identifiable, Codable {
        let id: String
        let caseId: String
        let caseNumber: String
        let caseType: String
        let reportTitle: String
        let fileName: String
        let filePath: String
        let fileSize: Int64
        let createdAt: Date
        let lastAccessedAt: Date
        var isDownloaded: Bool
        var downloadProgress: Double
        let metadata: ReportMetadata
        
        var formattedFileSize: String {
            ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        }
        
        var timeSinceCreation: String {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: createdAt, relativeTo: Date())
        }
    }
    
    struct ReportMetadata: Codable {
        let template: String
        let language: String
        let pageCount: Int
        let isOfficialDocument: Bool
        let tags: [String]
        let summary: String
    }
    
    // MARK: - Save PDF Report
    
    func savePDFReport(
        pdfURL: URL,
        caseRecord: FirebaseManager.CaseRecord,
        template: String,
        pageCount: Int = 1
    ) async throws -> SavedReport {
        
        print("💾 Saving PDF report for case: \(caseRecord.caseNumber)")
        
        let reportId = UUID().uuidString
        let fileManager = FileManager.default
        
        // Create reports directory if it doesn't exist
        let reportsDirectory = getReportsDirectory()
        try fileManager.createDirectory(at: reportsDirectory, withIntermediateDirectories: true)
        
        // Generate unique filename
        let originalFileName = pdfURL.lastPathComponent
        let fileExtension = pdfURL.pathExtension
        let baseFileName = originalFileName.replacingOccurrences(of: ".\(fileExtension)", with: "")
        let newFileName = "\(reportId)_\(baseFileName).\(fileExtension)"
        let destinationURL = reportsDirectory.appendingPathComponent(newFileName)
        
        // Copy PDF to reports directory
        try fileManager.copyItem(at: pdfURL, to: destinationURL)
        
        // Get file size
        let fileAttributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0
        
        // Create report metadata
        let metadata = ReportMetadata(
            template: template,
            language: caseRecord.language,
            pageCount: pageCount,
            isOfficialDocument: true,
            tags: generateTags(for: caseRecord),
            summary: generateSummary(for: caseRecord)
        )
        
        // Create saved report
        let savedReport = SavedReport(
            id: reportId,
            caseId: caseRecord.id,
            caseNumber: caseRecord.caseNumber,
            caseType: caseRecord.caseType,
            reportTitle: generateReportTitle(for: caseRecord, template: template),
            fileName: newFileName,
            filePath: destinationURL.path,
            fileSize: fileSize,
            createdAt: Date(),
            lastAccessedAt: Date(),
            isDownloaded: true,
            downloadProgress: 1.0,
            metadata: metadata
        )
        
        // Add to saved reports
        DispatchQueue.main.async {
            self.savedReports.append(savedReport)
            self.savedReports.sort { $0.createdAt > $1.createdAt }
        }
        
        // Persist to UserDefaults
        persistReports()
        
        print("✅ PDF report saved successfully: \(newFileName)")
        return savedReport
    }
    
    // MARK: - Report Management
    
    func deleteReport(_ report: SavedReport) {
        do {
            let fileURL = URL(fileURLWithPath: report.filePath)
            if FileManager.default.fileExists(atPath: report.filePath) {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            DispatchQueue.main.async {
                self.savedReports.removeAll { $0.id == report.id }
            }
            
            persistReports()
            print("✅ Report deleted: \(report.fileName)")
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to delete report: \(error.localizedDescription)"
            }
            print("❌ Failed to delete report: \(error)")
        }
    }
    
    func shareReport(_ report: SavedReport) -> URL? {
        let fileURL = URL(fileURLWithPath: report.filePath)
        return FileManager.default.fileExists(atPath: report.filePath) ? fileURL : nil
    }
    
    func markReportAsAccessed(_ report: SavedReport) {
        DispatchQueue.main.async {
            if let index = self.savedReports.firstIndex(where: { $0.id == report.id }) {
                var updatedReport = self.savedReports[index]
                updatedReport = SavedReport(
                    id: updatedReport.id,
                    caseId: updatedReport.caseId,
                    caseNumber: updatedReport.caseNumber,
                    caseType: updatedReport.caseType,
                    reportTitle: updatedReport.reportTitle,
                    fileName: updatedReport.fileName,
                    filePath: updatedReport.filePath,
                    fileSize: updatedReport.fileSize,
                    createdAt: updatedReport.createdAt,
                    lastAccessedAt: Date(),
                    isDownloaded: updatedReport.isDownloaded,
                    downloadProgress: updatedReport.downloadProgress,
                    metadata: updatedReport.metadata
                )
                self.savedReports[index] = updatedReport
            }
        }
        persistReports()
    }
    
    // MARK: - Bulk Operations
    
    func exportAllReports() -> [URL] {
        return savedReports.compactMap { report in
            let fileURL = URL(fileURLWithPath: report.filePath)
            return FileManager.default.fileExists(atPath: report.filePath) ? fileURL : nil
        }
    }
    
    func getReportsForCase(_ caseId: String) -> [SavedReport] {
        return savedReports.filter { $0.caseId == caseId }
    }
    
    func searchReports(query: String) -> [SavedReport] {
        let lowercaseQuery = query.lowercased()
        return savedReports.filter { report in
            report.reportTitle.lowercased().contains(lowercaseQuery) ||
            report.caseNumber.lowercased().contains(lowercaseQuery) ||
            report.caseType.lowercased().contains(lowercaseQuery) ||
            report.metadata.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    // MARK: - Storage Management
    
    func getTotalStorageUsed() -> Int64 {
        return savedReports.reduce(0) { $0 + $1.fileSize }
    }
    
    func getFormattedStorageUsed() -> String {
        let totalBytes = getTotalStorageUsed()
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    func cleanupOldReports(olderThan days: Int = 90) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let reportsToDelete = savedReports.filter { $0.createdAt < cutoffDate }
        
        for report in reportsToDelete {
            deleteReport(report)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getReportsDirectory() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("BoloNyayReports")
    }
    
    private func generateReportTitle(for caseRecord: FirebaseManager.CaseRecord, template: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Date())
        
        return "\(template) Report - \(caseRecord.caseNumber) - \(dateString)"
    }
    
    private func generateTags(for caseRecord: FirebaseManager.CaseRecord) -> [String] {
        var tags = [caseRecord.caseType, caseRecord.language]
        
        // Add case-specific tags based on case type
        let caseTypeLower = caseRecord.caseType.lowercased()
        if caseTypeLower.contains("criminal") {
            tags.append("Criminal Law")
        } else if caseTypeLower.contains("civil") {
            tags.append("Civil Law")
        } else if caseTypeLower.contains("family") {
            tags.append("Family Law")
        } else if caseTypeLower.contains("consumer") {
            tags.append("Consumer Protection")
        } else if caseTypeLower.contains("labor") {
            tags.append("Labor Law")
        }
        
        // Add status tag
        tags.append(caseRecord.status.displayName)
        
        return Array(Set(tags)) // Remove duplicates
    }
    
    private func generateSummary(for caseRecord: FirebaseManager.CaseRecord) -> String {
        let summary = caseRecord.conversationSummary.prefix(200)
        return String(summary) + (summary.count == 200 ? "..." : "")
    }
    
    // MARK: - Persistence
    
    private func persistReports() {
        do {
            let data = try JSONEncoder().encode(savedReports)
            UserDefaults.standard.set(data, forKey: "BoloNyay_SavedReports")
        } catch {
            print("❌ Failed to persist reports: \(error)")
        }
    }
    
    private func loadSavedReports() {
        guard let data = UserDefaults.standard.data(forKey: "BoloNyay_SavedReports") else {
            return
        }
        
        do {
            let reports = try JSONDecoder().decode([SavedReport].self, from: data)
            
            // Verify files still exist and update accordingly
            let validReports = reports.filter { report in
                FileManager.default.fileExists(atPath: report.filePath)
            }
            
            DispatchQueue.main.async {
                self.savedReports = validReports.sorted { $0.createdAt > $1.createdAt }
            }
            
            // Clean up UserDefaults if some files were missing
            if validReports.count != reports.count {
                persistReports()
            }
            
            print("✅ Loaded \(validReports.count) saved reports")
            
        } catch {
            print("❌ Failed to load saved reports: \(error)")
        }
    }
}

// MARK: - Extensions

extension ReportsManager {
    func getReportsStatistics() -> ReportsStatistics {
        let totalReports = savedReports.count
        let totalSize = getTotalStorageUsed()
        
        var reportsByType: [String: Int] = [:]
        var reportsByLanguage: [String: Int] = [:]
        var reportsByTemplate: [String: Int] = [:]
        
        for report in savedReports {
            reportsByType[report.caseType, default: 0] += 1
            reportsByLanguage[report.metadata.language, default: 0] += 1
            reportsByTemplate[report.metadata.template, default: 0] += 1
        }
        
        return ReportsStatistics(
            totalReports: totalReports,
            totalStorageUsed: totalSize,
            reportsByType: reportsByType,
            reportsByLanguage: reportsByLanguage,
            reportsByTemplate: reportsByTemplate,
            averageFileSize: totalReports > 0 ? totalSize / Int64(totalReports) : 0
        )
    }
}

// MARK: - Supporting Types

struct ReportsStatistics {
    let totalReports: Int
    let totalStorageUsed: Int64
    let reportsByType: [String: Int]
    let reportsByLanguage: [String: Int]
    let reportsByTemplate: [String: Int]
    let averageFileSize: Int64
    
    var formattedTotalStorage: String {
        ByteCountFormatter.string(fromByteCount: totalStorageUsed, countStyle: .file)
    }
    
    var formattedAverageFileSize: String {
        ByteCountFormatter.string(fromByteCount: averageFileSize, countStyle: .file)
    }
} 