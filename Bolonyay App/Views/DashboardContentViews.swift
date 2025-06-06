import SwiftUI

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
    @State private var selectedMyCasesTab: MyCasesTab = .eFiledCases
    
    var body: some View {
        VStack(spacing: 32) {
            // E-Filing Status Section
            VStack(spacing: 20) {
                SectionHeader(
                    title: "E-Filing Status",
                    subtitle: "Track your case filing progress",
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
                    title: "My Cases",
                    subtitle: "Manage your filed cases and documents",
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
                
                Text(status.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(status.description)
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
    
    var body: some View {
        VStack(spacing: 24) {
            SectionHeader(
                title: "File New Case",
                subtitle: "Start a new case filing process",
                animationDelay: 0.5,
                isAnimated: isAnimated
            )
            
            ComingSoonView(
                icon: "plus.rectangle.fill",
                title: "New Case Filing",
                message: "Case filing functionality will be available soon. You'll be able to file new cases with all required documents.",
                animationDelay: 0.7,
                isAnimated: isAnimated
            )
        }
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
        VStack(spacing: 24) {
            SectionHeader(
                title: "Reports",
                subtitle: "View and print your reports",
                animationDelay: 0.5,
                isAnimated: isAnimated
            )
            
            ComingSoonView(
                icon: "chart.bar.fill",
                title: "Reports & Analytics",
                message: "Reports functionality will be available soon. You'll be able to view and print detailed reports specific to your cases.",
                animationDelay: 0.7,
                isAnimated: isAnimated
            )
        }
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