import Foundation
import PDFKit
import UIKit
import SwiftUI

// MARK: - PDF Generation Manager
class PDFGenerationManager: ObservableObject {
    static let shared = PDFGenerationManager()
    
    private let azureOpenAIManager = AzureOpenAIManager()
    private let firebaseManager = FirebaseManager.shared
    
    @Published var isGeneratingPDF = false
    @Published var pdfGenerationProgress: Double = 0.0
    @Published var generatedPDFURL: URL?
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Main PDF Generation Function
    
    func generateLegalCasePDF(
        for caseRecord: FirebaseManager.CaseRecord,
        user: FirebaseManager.BoloNyayUser
    ) async throws -> URL {
        
        print("📄 Starting PDF generation for case: \(caseRecord.caseNumber)")
        
        DispatchQueue.main.async {
            self.isGeneratingPDF = true
            self.pdfGenerationProgress = 0.1
            self.errorMessage = nil
        }
        
        do {
            // Step 1: Process content with Azure OpenAI for legal document format
            let structuredContent = try await processContentForPDF(caseRecord: caseRecord)
            
            DispatchQueue.main.async {
                self.pdfGenerationProgress = 0.4
            }
            
            // Step 2: Determine case type and select appropriate template
            let caseTemplate = determineCaseTemplate(from: caseRecord.caseType)
            
            DispatchQueue.main.async {
                self.pdfGenerationProgress = 0.6
            }
            
            // Step 3: Generate PDF using the appropriate template
            let pdfURL = try await generatePDFDocument(
                template: caseTemplate,
                content: structuredContent,
                caseRecord: caseRecord,
                user: user
            )
            
            DispatchQueue.main.async {
                self.pdfGenerationProgress = 1.0
                self.generatedPDFURL = pdfURL
                self.isGeneratingPDF = false
            }
            
            // Save PDF to ReportsManager for future downloads
            Task {
                do {
                    let template = caseTemplate.displayName
                    let savedReport = try await ReportsManager.shared.savePDFReport(
                        pdfURL: pdfURL,
                        caseRecord: caseRecord,
                        template: template,
                        pageCount: estimatePageCount(content: structuredContent)
                    )
                    print("✅ PDF saved to reports: \(savedReport.reportTitle)")
                } catch {
                    print("⚠️ Failed to save PDF to reports: \(error)")
                }
            }
            
            print("✅ PDF generated successfully: \(pdfURL.lastPathComponent)")
            return pdfURL
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "PDF generation failed: \(error.localizedDescription)"
                self.isGeneratingPDF = false
                self.pdfGenerationProgress = 0.0
            }
            throw error
        }
    }
    
    // MARK: - Azure OpenAI Content Processing
    
    private func processContentForPDF(caseRecord: FirebaseManager.CaseRecord) async throws -> StructuredLegalContent {
        
        print("🤖 Processing content with Azure OpenAI for PDF generation...")
        
        // Extract detailed case information first
        let detailedInfo = try await azureOpenAIManager.extractDetailedCaseInformation(
            caseRecord: caseRecord
        )
        
        let processedContent = try await azureOpenAIManager.processContentForLegalPDF(
            caseRecord: caseRecord
        )
        
        var structuredContent = parseStructuredContent(processedContent)
        
        // Enhance with detailed information
        structuredContent.detailedCaseInfo = detailedInfo
        
        return structuredContent
    }
    
    private func parseStructuredContent(_ content: String) -> StructuredLegalContent {
        // Parse Azure OpenAI response into structured format
        var structuredContent = StructuredLegalContent()
        
        let lines = content.components(separatedBy: .newlines)
        var currentSection = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.hasPrefix("CASE SUMMARY:") {
                currentSection = "summary"
                structuredContent.caseSummary = String(trimmedLine.dropFirst(13)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("KEY FACTS:") {
                currentSection = "facts"
            } else if trimmedLine.hasPrefix("LEGAL ISSUES:") {
                currentSection = "issues"
            } else if trimmedLine.hasPrefix("RELIEF SOUGHT:") {
                currentSection = "relief"
            } else if trimmedLine.hasPrefix("NEXT STEPS:") {
                currentSection = "steps"
            } else if !trimmedLine.isEmpty && trimmedLine.hasPrefix("- ") {
                let bulletPoint = String(trimmedLine.dropFirst(2))
                
                switch currentSection {
                case "facts":
                    structuredContent.keyFacts.append(bulletPoint)
                case "issues":
                    structuredContent.legalIssues.append(bulletPoint)
                case "relief":
                    structuredContent.reliefSought.append(bulletPoint)
                case "steps":
                    structuredContent.nextSteps.append(bulletPoint)
                default:
                    break
                }
            } else if !trimmedLine.isEmpty && !trimmedLine.hasSuffix(":") {
                // Continuation of previous section
                switch currentSection {
                case "summary":
                    structuredContent.caseSummary += " " + trimmedLine
                default:
                    break
                }
            }
        }
        
        return structuredContent
    }
    
    // MARK: - Case Template Selection
    
    private func determineCaseTemplate(from caseType: String) -> CaseTemplate {
        let lowercaseType = caseType.lowercased()
        
        if lowercaseType.contains("civil") || lowercaseType.contains("property") || lowercaseType.contains("contract") {
            return .civil
        } else if lowercaseType.contains("criminal") || lowercaseType.contains("fir") || lowercaseType.contains("fraud") {
            return .criminal
        } else if lowercaseType.contains("family") || lowercaseType.contains("divorce") || lowercaseType.contains("custody") {
            return .family
        } else if lowercaseType.contains("consumer") || lowercaseType.contains("service") || lowercaseType.contains("product") {
            return .consumer
        } else if lowercaseType.contains("labor") || lowercaseType.contains("employment") || lowercaseType.contains("salary") {
            return .labor
        } else if lowercaseType.contains("writ") || lowercaseType.contains("constitutional") || lowercaseType.contains("government") {
            return .writ
        } else {
            return .civil // Default template
        }
    }
    
    // MARK: - PDF Document Generation
    
    private func generatePDFDocument(
        template: CaseTemplate,
        content: StructuredLegalContent,
        caseRecord: FirebaseManager.CaseRecord,
        user: FirebaseManager.BoloNyayUser
    ) async throws -> URL {
        
        print("📝 Generating PDF document using \(template.rawValue) template...")
        
        // Create PDF renderer
        let pageSize = CGSize(width: 595, height: 842) // A4 size in points
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        // Generate filename
        let filename = "BoloNyay_\(caseRecord.caseNumber)_\(template.rawValue)_\(formatDateForFilename(Date())).pdf"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsPath.appendingPathComponent(filename)
        
        // Generate PDF data
        let pdfData = renderer.pdfData { context in
            // Start first page
            context.beginPage()
            
            // Draw PDF content based on template
            switch template {
            case .civil:
                drawCivilCasePDF(context: context, content: content, caseRecord: caseRecord, user: user, pageSize: pageSize)
            case .criminal:
                drawCriminalCasePDF(context: context, content: content, caseRecord: caseRecord, user: user, pageSize: pageSize)
            case .family:
                drawFamilyCasePDF(context: context, content: content, caseRecord: caseRecord, user: user, pageSize: pageSize)
            case .consumer:
                drawConsumerCasePDF(context: context, content: content, caseRecord: caseRecord, user: user, pageSize: pageSize)
            case .labor:
                drawLaborCasePDF(context: context, content: content, caseRecord: caseRecord, user: user, pageSize: pageSize)
            case .writ:
                drawWritPetitionPDF(context: context, content: content, caseRecord: caseRecord, user: user, pageSize: pageSize)
            }
        }
        
        // Save PDF to file
        try pdfData.write(to: pdfURL)
        
        print("✅ PDF saved to: \(pdfURL.lastPathComponent)")
        return pdfURL
    }
    
    // MARK: - PDF Drawing Functions with Multi-Page Support
    
    private func drawCivilCasePDF(
        context: UIGraphicsPDFRendererContext,
        content: StructuredLegalContent,
        caseRecord: FirebaseManager.CaseRecord,
        user: FirebaseManager.BoloNyayUser,
        pageSize: CGSize
    ) {
        let margin: CGFloat = 50
        let footerHeight: CGFloat = 200
        let maxContentHeight = pageSize.height - margin - footerHeight
        var currentY: CGFloat = margin
        var currentPage = 1
        
        // Header on first page
        currentY = drawCourtHeader(context: context, pageSize: pageSize, currentY: currentY, caseType: "CIVIL SUIT")
        
        // Case number and parties
        currentY = drawCaseNumber(context: context, caseNumber: caseRecord.caseNumber, currentY: currentY, margin: margin)
        currentY = drawParties(context: context, user: user, currentY: currentY, margin: margin, caseType: "CIVIL", detailedInfo: content.detailedCaseInfo)
        
        // Main content with page break handling
        let contentSections = prepareContentSections(content: content)
        
        for section in contentSections {
            let sectionHeight = estimateSectionHeight(section: section, maxWidth: pageSize.width - (margin * 2))
            
            // Check if we need a new page
            if currentY + sectionHeight > maxContentHeight {
                // Draw page number on current page
                drawPageNumber(context: context, pageNumber: currentPage, pageSize: pageSize)
                
                // Start new page
                context.beginPage()
                currentPage += 1
                currentY = margin + 30 // Space for header on continuation pages
                
                // Mini header for continuation pages
                drawContinuationHeader(context: context, pageSize: pageSize, caseNumber: caseRecord.caseNumber, caseType: "CIVIL SUIT")
            }
            
            // Draw section content
            currentY = drawContentSection(context: context, section: section, currentY: currentY, margin: margin, pageSize: pageSize)
            currentY += 20 // Space between sections
        }
        
        // Check if footer fits on current page
        if currentY + footerHeight > pageSize.height - margin {
            // Draw page number on current page
            drawPageNumber(context: context, pageNumber: currentPage, pageSize: pageSize)
            
            // Start new page for footer
            context.beginPage()
            currentPage += 1
            currentY = margin + 50
        }
        
        // Footer on last page
        drawMultiPageFooter(context: context, pageSize: pageSize, caseRecord: caseRecord, user: user, currentY: currentY)
        
        // Final page number
        drawPageNumber(context: context, pageNumber: currentPage, pageSize: pageSize)
    }
    
    private func drawCriminalCasePDF(
        context: UIGraphicsPDFRendererContext,
        content: StructuredLegalContent,
        caseRecord: FirebaseManager.CaseRecord,
        user: FirebaseManager.BoloNyayUser,
        pageSize: CGSize
    ) {
        drawMultiPageDocument(context: context, content: content, caseRecord: caseRecord, user: user, pageSize: pageSize, caseType: "CRIMINAL COMPLAINT")
    }
    
    private func drawFamilyCasePDF(
        context: UIGraphicsPDFRendererContext,
        content: StructuredLegalContent,
        caseRecord: FirebaseManager.CaseRecord,
        user: FirebaseManager.BoloNyayUser,
        pageSize: CGSize
    ) {
        drawMultiPageDocument(context: context, content: content, caseRecord: caseRecord, user: user, pageSize: pageSize, caseType: "FAMILY PETITION")
    }
    
    private func drawConsumerCasePDF(
        context: UIGraphicsPDFRendererContext,
        content: StructuredLegalContent,
        caseRecord: FirebaseManager.CaseRecord,
        user: FirebaseManager.BoloNyayUser,
        pageSize: CGSize
    ) {
        drawMultiPageDocument(context: context, content: content, caseRecord: caseRecord, user: user, pageSize: pageSize, caseType: "CONSUMER COMPLAINT")
    }
    
    private func drawLaborCasePDF(
        context: UIGraphicsPDFRendererContext,
        content: StructuredLegalContent,
        caseRecord: FirebaseManager.CaseRecord,
        user: FirebaseManager.BoloNyayUser,
        pageSize: CGSize
    ) {
        drawMultiPageDocument(context: context, content: content, caseRecord: caseRecord, user: user, pageSize: pageSize, caseType: "LABOR PETITION")
    }
    
    private func drawWritPetitionPDF(
        context: UIGraphicsPDFRendererContext,
        content: StructuredLegalContent,
        caseRecord: FirebaseManager.CaseRecord,
        user: FirebaseManager.BoloNyayUser,
        pageSize: CGSize
    ) {
        drawMultiPageDocument(context: context, content: content, caseRecord: caseRecord, user: user, pageSize: pageSize, caseType: "WRIT PETITION")
    }
    
    // MARK: - Multi-Page Document Generator
    
    private func drawMultiPageDocument(
        context: UIGraphicsPDFRendererContext,
        content: StructuredLegalContent,
        caseRecord: FirebaseManager.CaseRecord,
        user: FirebaseManager.BoloNyayUser,
        pageSize: CGSize,
        caseType: String
    ) {
        let margin: CGFloat = 50
        let footerHeight: CGFloat = 200
        let maxContentHeight = pageSize.height - margin - footerHeight
        var currentY: CGFloat = margin
        var currentPage = 1
        
        // Header on first page
        currentY = drawCourtHeader(context: context, pageSize: pageSize, currentY: currentY, caseType: caseType)
        
        // Case number and parties
        currentY = drawCaseNumber(context: context, caseNumber: caseRecord.caseNumber, currentY: currentY, margin: margin)
        currentY = drawParties(context: context, user: user, currentY: currentY, margin: margin, caseType: extractCaseTypeForParties(caseType), detailedInfo: content.detailedCaseInfo)
        
        // Main content with page break handling
        let contentSections = prepareContentSections(content: content)
        
        for section in contentSections {
            let sectionHeight = estimateSectionHeight(section: section, maxWidth: pageSize.width - (margin * 2))
            
            // Check if we need a new page
            if currentY + sectionHeight > maxContentHeight {
                // Draw page number on current page
                drawPageNumber(context: context, pageNumber: currentPage, pageSize: pageSize)
                
                // Start new page
                context.beginPage()
                currentPage += 1
                currentY = margin + 30 // Space for header on continuation pages
                
                // Mini header for continuation pages
                drawContinuationHeader(context: context, pageSize: pageSize, caseNumber: caseRecord.caseNumber, caseType: caseType)
            }
            
            // Draw section content
            currentY = drawContentSection(context: context, section: section, currentY: currentY, margin: margin, pageSize: pageSize)
            currentY += 20 // Space between sections
        }
        
        // Check if footer fits on current page
        if currentY + footerHeight > pageSize.height - margin {
            // Draw page number on current page
            drawPageNumber(context: context, pageNumber: currentPage, pageSize: pageSize)
            
            // Start new page for footer
            context.beginPage()
            currentPage += 1
            currentY = margin + 50
        }
        
        // Footer on last page
        drawMultiPageFooter(context: context, pageSize: pageSize, caseRecord: caseRecord, user: user, currentY: currentY)
        
        // Final page number
        drawPageNumber(context: context, pageNumber: currentPage, pageSize: pageSize)
    }
    
    // MARK: - Common PDF Drawing Components
    
    private func drawCourtHeader(
        context: UIGraphicsPDFRendererContext,
        pageSize: CGSize,
        currentY: CGFloat,
        caseType: String
    ) -> CGFloat {
        var y = currentY
        let margin: CGFloat = 50
        
        // State emblem/logo area (placeholder)
        let logoRect = CGRect(x: (pageSize.width - 60) / 2, y: y, width: 60, height: 60)
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(2.0)
        context.cgContext.addEllipse(in: logoRect)
        context.cgContext.strokePath()
        
        // "GOVERNMENT SEAL" text
        let sealText = "⚖️"
        let sealAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 30),
            .foregroundColor: UIColor.black
        ]
        let sealSize = sealText.size(withAttributes: sealAttributes)
        sealText.draw(at: CGPoint(x: (pageSize.width - sealSize.width) / 2, y: y + 15), withAttributes: sealAttributes)
        y += 80
        
        // Court title with better formatting
        let courtTitle = "IN THE HON'BLE COURT OF COMPETENT JURISDICTION"
        let courtSubtitle = "AT [CITY NAME]"
        
        let courtTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ]
        
        let courtSubtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        
        let courtTitleSize = courtTitle.size(withAttributes: courtTitleAttributes)
        let courtX = (pageSize.width - courtTitleSize.width) / 2
        courtTitle.draw(at: CGPoint(x: courtX, y: y), withAttributes: courtTitleAttributes)
        y += courtTitleSize.height + 8
        
        let courtSubtitleSize = courtSubtitle.size(withAttributes: courtSubtitleAttributes)
        let courtSubX = (pageSize.width - courtSubtitleSize.width) / 2
        courtSubtitle.draw(at: CGPoint(x: courtSubX, y: y), withAttributes: courtSubtitleAttributes)
        y += courtSubtitleSize.height + 20
        
        // Case type with enhanced formatting
        let caseTypeHeader = caseType + " NO. _____ OF " + String(Calendar.current.component(.year, from: Date()))
        let caseTypeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        let caseTypeSize = caseTypeHeader.size(withAttributes: caseTypeAttributes)
        let caseTypeX = (pageSize.width - caseTypeSize.width) / 2
        caseTypeHeader.draw(at: CGPoint(x: caseTypeX, y: y), withAttributes: caseTypeAttributes)
        y += caseTypeSize.height + 25
        
        // Decorative separator
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(2.0)
        context.cgContext.move(to: CGPoint(x: margin, y: y))
        context.cgContext.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
        context.cgContext.strokePath()
        
        // Thin line below
        y += 3
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: CGPoint(x: margin + 20, y: y))
        context.cgContext.addLine(to: CGPoint(x: pageSize.width - margin - 20, y: y))
        context.cgContext.strokePath()
        y += 25
        
        return y
    }
    
    private func drawCaseNumber(
        context: UIGraphicsPDFRendererContext,
        caseNumber: String,
        currentY: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = currentY
        
        // Generate formatted case number
        let formattedCaseNumber = caseNumber.isEmpty ? "BN\(String(format: "%010d", Int.random(in: 1000000000...9999999999)))" : caseNumber
        let caseNumText = "CASE NO: \(formattedCaseNumber) OF \(Calendar.current.component(.year, from: Date()))"
        
        let caseNumAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        // Center the case number
        let caseNumSize = caseNumText.size(withAttributes: caseNumAttributes)
        let pageWidth = context.pdfContextBounds.width
        let centeredX = (pageWidth - caseNumSize.width) / 2
        
        caseNumText.draw(at: CGPoint(x: centeredX, y: y), withAttributes: caseNumAttributes)
        y += caseNumSize.height + 25
        
        return y
    }
    
    private func drawParties(
        context: UIGraphicsPDFRendererContext,
        user: FirebaseManager.BoloNyayUser,
        currentY: CGFloat,
        margin: CGFloat,
        caseType: String,
        detailedInfo: DetailedCaseInfo? = nil
    ) -> CGFloat {
        var y = currentY
        
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        
        let italicAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 9),
            .foregroundColor: UIColor.darkGray
        ]
        
        // Between section with proper formatting
        "BETWEEN:".draw(at: CGPoint(x: margin, y: y), withAttributes: boldAttributes)
        y += 30
        
        // Petitioner/Complainant box  
        let petitionerTitle = caseType == "CRIMINAL" ? "COMPLAINANT" : "PETITIONER"
        
        // Use detailed case info if available
        let petitionerName = detailedInfo?.petitioner.name ?? 
                            (user.name.isEmpty || user.name == "iPhone" ? "[PETITIONER NAME]" : user.name.uppercased())
        let petitionerAge = detailedInfo?.petitioner.age ?? "Age to be filled"
        let petitionerOccupation = detailedInfo?.petitioner.occupation ?? "Occupation to be filled"
        let petitionerAddress = detailedInfo?.petitioner.address ?? "Address to be filled"
        
        // Draw petitioner box with improved spacing
        let partyBoxWidth: CGFloat = 480
        let partyBoxHeight: CGFloat = 85
        let partyBox = CGRect(x: margin, y: y, width: partyBoxWidth, height: partyBoxHeight)
        
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(1.0)
        context.cgContext.stroke(partyBox)
        
        // Petitioner details inside box with better formatting
        petitionerName.draw(at: CGPoint(x: margin + 8, y: y + 8), withAttributes: boldAttributes)
        "... \(petitionerTitle)".draw(at: CGPoint(x: partyBoxWidth - 110, y: y + 8), withAttributes: boldAttributes)
        
        "Age: \(petitionerAge)".draw(at: CGPoint(x: margin + 8, y: y + 25), withAttributes: regularAttributes)
        "Occupation: \(petitionerOccupation)".draw(at: CGPoint(x: margin + 8, y: y + 40), withAttributes: regularAttributes)
        "Address: \(petitionerAddress)".draw(at: CGPoint(x: margin + 8, y: y + 55), withAttributes: regularAttributes)
        
        y += partyBoxHeight + 20
        
        // Center "AND" with decorative formatting
        let andText = "AND"
        let andSize = andText.size(withAttributes: boldAttributes)
        let pageWidth = context.pdfContextBounds.width
        let andX = (pageWidth - andSize.width) / 2
        
        // Draw decorative lines around "AND"
        let lineY = y + (andSize.height / 2)
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(1.0)
        context.cgContext.move(to: CGPoint(x: margin, y: lineY))
        context.cgContext.addLine(to: CGPoint(x: andX - 10, y: lineY))
        context.cgContext.move(to: CGPoint(x: andX + andSize.width + 10, y: lineY))
        context.cgContext.addLine(to: CGPoint(x: margin + partyBoxWidth, y: lineY))
        context.cgContext.strokePath()
        
        andText.draw(at: CGPoint(x: andX, y: y), withAttributes: boldAttributes)
        y += andSize.height + 20
        
        // Respondent box with detailed information
        let respondentTitle = caseType == "CRIMINAL" ? "ACCUSED" : "RESPONDENT"
        
        // Use detailed case info for respondent
        let respondentName = detailedInfo?.respondent.name ?? "Respondent name to be filled"
        let respondentAge = detailedInfo?.respondent.age ?? "Age to be filled"
        let respondentOccupation = detailedInfo?.respondent.occupation ?? "Occupation to be filled"
        let respondentAddress = detailedInfo?.respondent.address ?? "Address to be filled"
        
        let respondentBox = CGRect(x: margin, y: y, width: partyBoxWidth, height: partyBoxHeight)
        
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(1.0)
        context.cgContext.stroke(respondentBox)
        
        // Respondent details inside box with actual information
        respondentName.draw(at: CGPoint(x: margin + 8, y: y + 8), withAttributes: boldAttributes)
        "... \(respondentTitle)".draw(at: CGPoint(x: partyBoxWidth - 110, y: y + 8), withAttributes: boldAttributes)
        
        "Age: \(respondentAge)".draw(at: CGPoint(x: margin + 8, y: y + 25), withAttributes: regularAttributes)
        "Occupation: \(respondentOccupation)".draw(at: CGPoint(x: margin + 8, y: y + 40), withAttributes: regularAttributes)
        "Address: \(respondentAddress)".draw(at: CGPoint(x: margin + 8, y: y + 55), withAttributes: regularAttributes)
        
        y += partyBoxHeight + 30
        
        // Professional separator line
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(2.0)
        context.cgContext.move(to: CGPoint(x: margin, y: y))
        context.cgContext.addLine(to: CGPoint(x: margin + partyBoxWidth, y: y))
        context.cgContext.strokePath()
        y += 25
        
        return y
    }
    
    private func drawMainContent(
        context: UIGraphicsPDFRendererContext,
        content: StructuredLegalContent,
        currentY: CGFloat,
        margin: CGFloat,
        pageSize: CGSize
    ) -> CGFloat {
        var y = currentY
        
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        
        let sectionHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        let maxWidth = pageSize.width - (margin * 2)
        
        // Petition heading with better formatting
        let petitionHeading = "THE HUMBLE PETITION OF THE PETITIONER ABOVE NAMED"
        let headingSize = petitionHeading.size(withAttributes: boldAttributes)
        let headingX = (pageSize.width - headingSize.width) / 2
        petitionHeading.draw(at: CGPoint(x: headingX, y: y), withAttributes: boldAttributes)
        y += headingSize.height + 15
        
        let showethText = "MOST RESPECTFULLY SHOWETH:"
        let showethSize = showethText.size(withAttributes: boldAttributes)
        let showethX = (pageSize.width - showethSize.width) / 2
        showethText.draw(at: CGPoint(x: showethX, y: y), withAttributes: boldAttributes)
        y += showethSize.height + 25
        
        // Section 1: Facts of the case with enhanced formatting and incident details
        let section1Title = "1. FACTS OF THE CASE:"
        section1Title.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionHeaderAttributes)
        y += 20
        
        // Include incident details if available
        if let incident = content.detailedCaseInfo?.incident {
            let incidentSummary = "On \(incident.date) at \(incident.time), at \(incident.place), the following incident occurred: \(incident.description)"
            y = drawWrappedText(text: incidentSummary, startY: y, margin: margin + 10, maxWidth: maxWidth - 10, attributes: regularAttributes)
            y += 15
        }
        
        let caseSummary = content.caseSummary.isEmpty ? 
            "This matter pertains to the case as described above. The petitioner seeks appropriate relief from this Hon'ble Court." : 
            content.caseSummary
        
        y = drawWrappedText(text: caseSummary, startY: y, margin: margin + 10, maxWidth: maxWidth - 10, attributes: regularAttributes)
        y += 20
        
        // Section 2: Cause of action
        let section2Title = "2. CAUSE OF ACTION:"
        section2Title.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionHeaderAttributes)
        y += 18
        
        if content.legalIssues.isEmpty {
            let defaultText = "a. Whether the act complained of constitutes a violation of the petitioner's rights.\nb. Whether the petitioner is entitled to the relief sought.\nc. Whether there has been any procedural irregularity.\nd. Whether the matter falls within the jurisdiction of this Hon'ble Court."
            y = drawWrappedText(text: defaultText, startY: y, margin: margin + 10, maxWidth: maxWidth - 10, attributes: regularAttributes)
        } else {
            for (index, issue) in content.legalIssues.enumerated() {
                let bulletPoint = String(UnicodeScalar(97 + index)!) // a, b, c, etc.
                let text = "\(bulletPoint). \(issue)"
                y = drawWrappedText(text: text, startY: y, margin: margin + 10, maxWidth: maxWidth - 10, attributes: regularAttributes)
                y += 12
            }
        }
        y += 18
        
        // Section 3: Detailed grounds
        let section3Title = "3. GROUNDS AND SUBMISSIONS:"
        section3Title.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionHeaderAttributes)
        y += 25
        
        if content.keyFacts.isEmpty {
            let defaultText = "i. The petitioner submits that all material facts have been disclosed.\nii. The case involves issues of law and fact that require judicial determination.\niii. The petitioner has no adequate alternative remedy.\niv. The matter is urgent and requires immediate attention of this Hon'ble Court."
            y = drawWrappedText(text: defaultText, startY: y, margin: margin + 15, maxWidth: maxWidth - 15, attributes: regularAttributes)
        } else {
            for (index, fact) in content.keyFacts.enumerated() {
                let romanNumeral = convertToRoman(index + 1)
                let text = "\(romanNumeral). \(fact)"
                y = drawWrappedText(text: text, startY: y, margin: margin + 15, maxWidth: maxWidth - 15, attributes: regularAttributes)
                y += 15
            }
        }
        y += 25
        
        // Section 4: Relief sought
        let section4Title = "4. PRAYER/RELIEF SOUGHT:"
        section4Title.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionHeaderAttributes)
        y += 25
        
        let prayerIntro = "In the premises aforesaid, the Petitioner most respectfully prays that this Hon'ble Court may graciously be pleased to:"
        y = drawWrappedText(text: prayerIntro, startY: y, margin: margin + 15, maxWidth: maxWidth - 15, attributes: regularAttributes)
        y += 15
        
        if content.reliefSought.isEmpty {
            let defaultReliefs = [
                "Grant the relief as prayed for in the petition",
                "Pass appropriate orders and directions as this Hon'ble Court deems fit",
                "Award costs of this petition to the petitioner",
                "Pass such other and further orders as this Hon'ble Court may deem fit and proper in the circumstances of the case"
            ]
            for (index, relief) in defaultReliefs.enumerated() {
                let text = "(\(index + 1)) \(relief);"
                y = drawWrappedText(text: text, startY: y, margin: margin + 25, maxWidth: maxWidth - 25, attributes: regularAttributes)
                y += 15
            }
        } else {
            for (index, relief) in content.reliefSought.enumerated() {
                let text = "(\(index + 1)) \(relief);"
                y = drawWrappedText(text: text, startY: y, margin: margin + 25, maxWidth: maxWidth - 25, attributes: regularAttributes)
                y += 15
            }
        }
        
        // Final declaration
        y += 15
        let declarationText = "AND FOR SUCH OTHER AND FURTHER RELIEF AS THIS HON'BLE COURT MAY DEEM FIT AND PROPER IN THE CIRCUMSTANCES OF THE CASE."
        y = drawWrappedText(text: declarationText, startY: y, margin: margin + 15, maxWidth: maxWidth - 15, attributes: boldAttributes)
        
        return y
    }
    
    private func drawWrappedText(
        text: String,
        startY: CGFloat,
        margin: CGFloat,
        maxWidth: CGFloat,
        attributes: [NSAttributedString.Key: Any]
    ) -> CGFloat {
        let boundingRect = CGRect(x: margin, y: startY, width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textRect = attributedString.boundingRect(
            with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        attributedString.draw(in: boundingRect)
        
        return startY + textRect.height + 5
    }
    
    private func drawFooter(
        context: UIGraphicsPDFRendererContext,
        pageSize: CGSize,
        caseRecord: FirebaseManager.CaseRecord,
        user: FirebaseManager.BoloNyayUser
    ) {
        let margin: CGFloat = 50
        let footerY = pageSize.height - 180
        
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]
        
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]
        
        // Horizontal separator line before footer
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(1.5)
        context.cgContext.move(to: CGPoint(x: margin, y: footerY - 20))
        context.cgContext.addLine(to: CGPoint(x: pageSize.width - margin, y: footerY - 20))
        context.cgContext.strokePath()
        
        // Verification section with better formatting
        "VERIFICATION:".draw(at: CGPoint(x: margin, y: footerY), withAttributes: boldAttributes)
        
        let petitionerName = user.name.isEmpty || user.name == "iPhone" ? "[PETITIONER NAME]" : user.name
        let verificationText = "I, \(petitionerName), the Petitioner above named, do hereby verify that the contents of the above petition are true and correct to the best of my knowledge and belief and that nothing material has been concealed therein."
        _ = drawWrappedText(text: verificationText, startY: footerY + 20, margin: margin, maxWidth: pageSize.width - (margin * 2), attributes: regularAttributes)
        
        // Date and signature section with boxes
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dateString = dateFormatter.string(from: Date())
        
        // Left side - Date and Place
        let leftBoxX: CGFloat = margin
        let rightBoxX: CGFloat = pageSize.width - margin - 200
        let boxY: CGFloat = footerY + 90
        
        "Place: _________________".draw(at: CGPoint(x: leftBoxX, y: boxY), withAttributes: regularAttributes)
        "Date: \(dateString)".draw(at: CGPoint(x: leftBoxX, y: boxY + 20), withAttributes: regularAttributes)
        
        // Right side - Signature box with border
        let signatureBoxWidth: CGFloat = 180
        let signatureBoxHeight: CGFloat = 60
        let signatureBox = CGRect(x: rightBoxX, y: boxY, width: signatureBoxWidth, height: signatureBoxHeight)
        
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(1.0)
        context.cgContext.stroke(signatureBox)
        
        "SIGNATURE OF PETITIONER".draw(at: CGPoint(x: rightBoxX + 10, y: boxY + signatureBoxHeight + 5), withAttributes: boldAttributes)
        
        // BoloNyay professional branding
        let brandingY = pageSize.height - 40
        let brandingText = "📋 Generated by BoloNyay Legal Assistant | AI-Powered Legal Document Creation"
        let brandingAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.darkGray
        ]
        
        let brandingSize = brandingText.size(withAttributes: brandingAttributes)
        let brandingX = (pageSize.width - brandingSize.width) / 2
        brandingText.draw(at: CGPoint(x: brandingX, y: brandingY), withAttributes: brandingAttributes)
        
        // Professional disclaimer
        let disclaimerText = "This document is AI-generated and should be reviewed by a qualified legal professional before filing."
        let disclaimerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 8),
            .foregroundColor: UIColor.gray
        ]
        
        let disclaimerSize = disclaimerText.size(withAttributes: disclaimerAttributes)
        let disclaimerX = (pageSize.width - disclaimerSize.width) / 2
        disclaimerText.draw(at: CGPoint(x: disclaimerX, y: brandingY + 15), withAttributes: disclaimerAttributes)
    }
    
    // MARK: - Helper Functions
    
    private func convertToRoman(_ number: Int) -> String {
        let values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
        let numerals = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
        
        var result = ""
        var num = number
        
        for i in 0..<values.count {
            while num >= values[i] {
                result += numerals[i]
                num -= values[i]
            }
        }
        
        return result.lowercased()
    }
    
    // MARK: - Multi-Page Helper Functions
    
    private func extractCaseTypeForParties(_ fullCaseType: String) -> String {
        if fullCaseType.contains("CRIMINAL") { return "CRIMINAL" }
        if fullCaseType.contains("FAMILY") { return "FAMILY" }
        if fullCaseType.contains("CONSUMER") { return "CONSUMER" }
        if fullCaseType.contains("LABOR") { return "LABOR" }
        if fullCaseType.contains("WRIT") { return "WRIT" }
        return "CIVIL"
    }
    
    private func prepareContentSections(content: StructuredLegalContent) -> [ContentSection] {
        var sections: [ContentSection] = []
        
        // Add petition heading
        sections.append(ContentSection(
            type: .heading,
            title: "THE HUMBLE PETITION OF THE PETITIONER ABOVE NAMED",
            content: ["MOST RESPECTFULLY SHOWETH:"],
            isFullWidth: true
        ))
        
        // Section 1: Facts of the case
        var factsContent: [String] = []
        if let incident = content.detailedCaseInfo?.incident {
            factsContent.append("On \(incident.date) at \(incident.time), at \(incident.place), the following incident occurred: \(incident.description)")
        }
        
        let caseSummary = content.caseSummary.isEmpty ? 
            "This matter pertains to the case as described above. The petitioner seeks appropriate relief from this Hon'ble Court." : 
            content.caseSummary
        factsContent.append(caseSummary)
        
        sections.append(ContentSection(
            type: .section,
            title: "1. FACTS OF THE CASE:",
            content: factsContent,
            isFullWidth: false
        ))
        
        // Section 2: Cause of action
        let legalIssues = content.legalIssues.isEmpty ? [
            "Whether the act complained of constitutes a violation of the petitioner's rights.",
            "Whether the petitioner is entitled to the relief sought.",
            "Whether there has been any procedural irregularity.",
            "Whether the matter falls within the jurisdiction of this Hon'ble Court."
        ] : content.legalIssues
        
        sections.append(ContentSection(
            type: .section,
            title: "2. CAUSE OF ACTION:",
            content: legalIssues,
            isFullWidth: false
        ))
        
        // Section 3: Detailed grounds
        let grounds = content.keyFacts.isEmpty ? [
            "The petitioner submits that all material facts have been disclosed.",
            "The case involves issues of law and fact that require judicial determination.",
            "The petitioner has no adequate alternative remedy.",
            "The matter is urgent and requires immediate attention of this Hon'ble Court."
        ] : content.keyFacts
        
        sections.append(ContentSection(
            type: .section,
            title: "3. GROUNDS AND SUBMISSIONS:",
            content: grounds,
            isFullWidth: false
        ))
        
        // Section 4: Relief sought
        let reliefs = content.reliefSought.isEmpty ? [
            "Grant the relief as prayed for in the petition",
            "Pass appropriate orders and directions as this Hon'ble Court deems fit",
            "Award costs of this petition to the petitioner",
            "Pass such other and further orders as this Hon'ble Court may deem fit and proper in the circumstances of the case"
        ] : content.reliefSought
        
        sections.append(ContentSection(
            type: .prayer,
            title: "4. PRAYER/RELIEF SOUGHT:",
            content: ["In the premises aforesaid, the Petitioner most respectfully prays that this Hon'ble Court may graciously be pleased to:"] + reliefs,
            isFullWidth: false
        ))
        
        // Final declaration
        sections.append(ContentSection(
            type: .declaration,
            title: "",
            content: ["AND FOR SUCH OTHER AND FURTHER RELIEF AS THIS HON'BLE COURT MAY DEEM FIT AND PROPER IN THE CIRCUMSTANCES OF THE CASE."],
            isFullWidth: false
        ))
        
        return sections
    }
    
    private func estimateSectionHeight(section: ContentSection, maxWidth: CGFloat) -> CGFloat {
        let titleHeight: CGFloat = section.title.isEmpty ? 0 : 25
        let contentHeight = section.content.reduce(0) { total, text in
            let estimatedLines = max(1, text.count / 80) // Rough estimation
            return total + CGFloat(estimatedLines * 15) + 10
        }
        return titleHeight + contentHeight + 30 // Extra padding
    }
    
    private func drawContentSection(
        context: UIGraphicsPDFRendererContext,
        section: ContentSection,
        currentY: CGFloat,
        margin: CGFloat,
        pageSize: CGSize
    ) -> CGFloat {
        var y = currentY
        let maxWidth = pageSize.width - (margin * 2)
        
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        
        let sectionHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        switch section.type {
        case .heading:
            // Draw petition heading
            if !section.title.isEmpty {
                let headingSize = section.title.size(withAttributes: boldAttributes)
                let headingX = (pageSize.width - headingSize.width) / 2
                section.title.draw(at: CGPoint(x: headingX, y: y), withAttributes: boldAttributes)
                y += headingSize.height + 15
            }
            
            for content in section.content {
                let showethSize = content.size(withAttributes: boldAttributes)
                let showethX = (pageSize.width - showethSize.width) / 2
                content.draw(at: CGPoint(x: showethX, y: y), withAttributes: boldAttributes)
                y += showethSize.height + 25
            }
            
        case .section:
            // Draw section title
            if !section.title.isEmpty {
                section.title.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionHeaderAttributes)
                y += 20
            }
            
            // Draw content with appropriate formatting
            for (index, content) in section.content.enumerated() {
                if section.title.contains("CAUSE OF ACTION") {
                    let bulletPoint = String(UnicodeScalar(97 + index)!) // a, b, c, etc.
                    let text = "\(bulletPoint). \(content)"
                    y = drawWrappedText(text: text, startY: y, margin: margin + 10, maxWidth: maxWidth - 10, attributes: regularAttributes)
                    y += 12
                } else if section.title.contains("GROUNDS") {
                    let romanNumeral = convertToRoman(index + 1)
                    let text = "\(romanNumeral). \(content)"
                    y = drawWrappedText(text: text, startY: y, margin: margin + 15, maxWidth: maxWidth - 15, attributes: regularAttributes)
                    y += 15
                } else {
                    y = drawWrappedText(text: content, startY: y, margin: margin + 10, maxWidth: maxWidth - 10, attributes: regularAttributes)
                    y += 15
                }
            }
            
        case .prayer:
            // Draw prayer title
            if !section.title.isEmpty {
                section.title.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionHeaderAttributes)
                y += 25
            }
            
            // Draw introduction
            if let intro = section.content.first {
                y = drawWrappedText(text: intro, startY: y, margin: margin + 15, maxWidth: maxWidth - 15, attributes: regularAttributes)
                y += 15
            }
            
            // Draw numbered reliefs
            for (index, relief) in section.content.dropFirst().enumerated() {
                let text = "(\(index + 1)) \(relief);"
                y = drawWrappedText(text: text, startY: y, margin: margin + 25, maxWidth: maxWidth - 25, attributes: regularAttributes)
                y += 15
            }
            
        case .declaration:
            // Draw final declaration
            for content in section.content {
                y += 15
                y = drawWrappedText(text: content, startY: y, margin: margin + 15, maxWidth: maxWidth - 15, attributes: boldAttributes)
            }
        }
        
        return y
    }
    
    private func drawPageNumber(context: UIGraphicsPDFRendererContext, pageNumber: Int, pageSize: CGSize) {
        let pageNumberText = "Page \(pageNumber)"
        let pageNumberAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        
        let pageNumberSize = pageNumberText.size(withAttributes: pageNumberAttributes)
        let pageNumberX = (pageSize.width - pageNumberSize.width) / 2
        let pageNumberY = pageSize.height - 30
        
        pageNumberText.draw(at: CGPoint(x: pageNumberX, y: pageNumberY), withAttributes: pageNumberAttributes)
    }
    
    private func drawContinuationHeader(context: UIGraphicsPDFRendererContext, pageSize: CGSize, caseNumber: String, caseType: String) {
        let margin: CGFloat = 50
        var y: CGFloat = margin
        
        // Mini header for continuation pages
        let headerText = "\(caseType) - CASE NO: \(caseNumber) (Continued)"
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let headerSize = headerText.size(withAttributes: headerAttributes)
        let headerX = (pageSize.width - headerSize.width) / 2
        headerText.draw(at: CGPoint(x: headerX, y: y), withAttributes: headerAttributes)
        
        // Underline
        y += headerSize.height + 5
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(1.0)
        context.cgContext.move(to: CGPoint(x: margin, y: y))
        context.cgContext.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
        context.cgContext.strokePath()
    }
    
    private func drawMultiPageFooter(
        context: UIGraphicsPDFRendererContext,
        pageSize: CGSize,
        caseRecord: FirebaseManager.CaseRecord,
        user: FirebaseManager.BoloNyayUser,
        currentY: CGFloat
    ) {
        let margin: CGFloat = 50
        var footerY = currentY + 30
        
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]
        
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]
        
        // Horizontal separator line before footer
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(1.5)
        context.cgContext.move(to: CGPoint(x: margin, y: footerY - 20))
        context.cgContext.addLine(to: CGPoint(x: pageSize.width - margin, y: footerY - 20))
        context.cgContext.strokePath()
        
        // Verification section
        "VERIFICATION:".draw(at: CGPoint(x: margin, y: footerY), withAttributes: boldAttributes)
        
        let petitionerName = user.name.isEmpty || user.name == "iPhone" ? "[PETITIONER NAME]" : user.name
        let verificationText = "I, \(petitionerName), the Petitioner above named, do hereby verify that the contents of the above petition are true and correct to the best of my knowledge and belief and that nothing material has been concealed therein."
        footerY = drawWrappedText(text: verificationText, startY: footerY + 20, margin: margin, maxWidth: pageSize.width - (margin * 2), attributes: regularAttributes)
        
        // Date and signature section
        footerY += 20
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dateString = dateFormatter.string(from: Date())
        
        let leftBoxX: CGFloat = margin
        let rightBoxX: CGFloat = pageSize.width - margin - 200
        
        "Place: _________________".draw(at: CGPoint(x: leftBoxX, y: footerY), withAttributes: regularAttributes)
        "Date: \(dateString)".draw(at: CGPoint(x: leftBoxX, y: footerY + 20), withAttributes: regularAttributes)
        
        // Signature box
        let signatureBoxWidth: CGFloat = 180
        let signatureBoxHeight: CGFloat = 60
        let signatureBox = CGRect(x: rightBoxX, y: footerY, width: signatureBoxWidth, height: signatureBoxHeight)
        
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(1.0)
        context.cgContext.stroke(signatureBox)
        
        "SIGNATURE OF PETITIONER".draw(at: CGPoint(x: rightBoxX + 10, y: footerY + signatureBoxHeight + 5), withAttributes: boldAttributes)
        
        // BoloNyay professional branding
        let brandingY = pageSize.height - 40
        let brandingText = "📋 Generated by BoloNyay Legal Assistant | AI-Powered Legal Document Creation"
        let brandingAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.darkGray
        ]
        
        let brandingSize = brandingText.size(withAttributes: brandingAttributes)
        let brandingX = (pageSize.width - brandingSize.width) / 2
        brandingText.draw(at: CGPoint(x: brandingX, y: brandingY), withAttributes: brandingAttributes)
        
        // Professional disclaimer
        let disclaimerText = "This document is AI-generated and should be reviewed by a qualified legal professional before filing."
        let disclaimerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 8),
            .foregroundColor: UIColor.gray
        ]
        
        let disclaimerSize = disclaimerText.size(withAttributes: disclaimerAttributes)
        let disclaimerX = (pageSize.width - disclaimerSize.width) / 2
        disclaimerText.draw(at: CGPoint(x: disclaimerX, y: brandingY + 15), withAttributes: disclaimerAttributes)
    }
    
    // MARK: - Utility Functions
    
    private func formatDateForFilename(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }
    
    private func estimatePageCount(content: StructuredLegalContent) -> Int {
        // Estimate pages based on content length
        let totalContent = content.caseSummary + content.keyFacts.joined() + 
                          content.legalIssues.joined() + content.reliefSought.joined()
        let charactersPerPage = 2500 // Rough estimate
        let estimatedPages = max(1, totalContent.count / charactersPerPage)
        return min(estimatedPages, 10) // Cap at 10 pages for safety
    }
}

// MARK: - Supporting Types

enum CaseTemplate: String, CaseIterable {
    case civil = "Civil"
    case criminal = "Criminal"
    case family = "Family"
    case consumer = "Consumer"
    case labor = "Labor"
    case writ = "Writ"
    
    var displayName: String {
        switch self {
        case .civil: return "Civil Case"
        case .criminal: return "Criminal Complaint"
        case .family: return "Family Petition"
        case .consumer: return "Consumer Complaint"
        case .labor: return "Labor Dispute"
        case .writ: return "Writ Petition"
        }
    }
    
    var legalFormat: String {
        switch self {
        case .civil: return "CIVIL SUIT NO. _____ OF 2024"
        case .criminal: return "CRIMINAL COMPLAINT NO. _____ OF 2024"
        case .family: return "FAMILY PETITION NO. _____ OF 2024"
        case .consumer: return "CONSUMER COMPLAINT NO. _____ OF 2024"
        case .labor: return "LABOR PETITION NO. _____ OF 2024"
        case .writ: return "WRIT PETITION NO. _____ OF 2024"
        }
    }
}

struct StructuredLegalContent {
    var caseSummary: String = ""
    var keyFacts: [String] = []
    var legalIssues: [String] = []
    var reliefSought: [String] = []
    var nextSteps: [String] = []
    var relevantLaws: [String] = []
    var urgencyFactors: [String] = []
    var evidenceRequired: [String] = []
    var detailedCaseInfo: DetailedCaseInfo?
}

// MARK: - Multi-Page Content Structure

struct ContentSection {
    let type: SectionType
    let title: String
    let content: [String]
    let isFullWidth: Bool
}

enum SectionType {
    case heading
    case section
    case prayer
    case declaration
} 