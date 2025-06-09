import SwiftUI
import Combine

struct AnimatedTextView: View {
    let text: String
    let font: Font
    let color: Color
    let animationSpeed: Double
    let onAnimationComplete: () -> Void
    
    @State private var displayedText = ""
    @State private var currentWordIndex = 0
    @State private var animationTimer: Timer?
    @State private var isAnimating = false
    @State private var hasStartedAnimation = false
    
    private var words: [String] {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }
    
    init(
        text: String,
        font: Font = .system(size: 14, weight: .medium),
        color: Color = .white.opacity(0.9),
        animationSpeed: Double = 0.08,
        onAnimationComplete: @escaping () -> Void = {}
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.animationSpeed = animationSpeed
        self.onAnimationComplete = onAnimationComplete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(displayedText)
                .font(font)
                .foregroundColor(color)
                .textSelection(.enabled)
                .animation(.easeInOut(duration: 0.3), value: displayedText)
        }
        .onAppear {
            guard !hasStartedAnimation else { return }
            hasStartedAnimation = true
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        guard !isAnimating && !words.isEmpty else { return }
        
        isAnimating = true
        currentWordIndex = 0
        displayedText = ""
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: animationSpeed, repeats: true) { timer in
            guard currentWordIndex < words.count else {
                stopAnimation()
                onAnimationComplete()
                return
            }
            
            let word = words[currentWordIndex]
            
            if currentWordIndex == 0 {
                displayedText = word
            } else {
                displayedText += " " + word
            }
            
            currentWordIndex += 1
            
            // Add slight pause at end of sentences
            if word.hasSuffix(".") || word.hasSuffix("?") || word.hasSuffix("!") {
                timer.fireDate = Date().addingTimeInterval(animationSpeed * 3)
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        isAnimating = false
    }
}

struct FormattedLegalResponseView: View {
    let response: String
    @State private var animateResponse = false
    @State private var sections: [ResponseSection] = []
    @State private var hasInitialized = false
    @State private var isResponseComplete = false
    @State private var responseCheckTimer: Timer?
    
    struct ResponseSection {
        let title: String
        var content: [String]
        let icon: String
        let color: Color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
                    .scaleEffect(animateResponse ? 1.0 : 0.8)
                    .animation(.spring(duration: 0.6, bounce: 0.4), value: animateResponse)
                
                Text("AI कानूनी विशेषज्ञ विश्लेषण / AI Legal Expert Analysis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(animateResponse ? 1.0 : 0.0)
                    .offset(x: animateResponse ? 0 : -20)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: animateResponse)
                
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                    .opacity(animateResponse ? 1.0 : 0.0)
                    .scaleEffect(animateResponse ? 1.0 : 0.5)
                    .animation(.spring(duration: 0.8, bounce: 0.5).delay(0.4), value: animateResponse)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            
            // Formatted Sections
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    ResponseSectionView(
                        section: section,
                        animationDelay: Double(index) * 0.3,
                        isVisible: animateResponse
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            guard !hasInitialized else { return }
            hasInitialized = true
            
            // Wait for complete response before parsing
            waitForCompleteResponse()
        }
        .onDisappear {
            responseCheckTimer?.invalidate()
            responseCheckTimer = nil
        }
    }
    
    private func waitForCompleteResponse() {
        // Check if response appears complete (contains typical ending markers)
        let responseIndicators = [
            "आगे क्या करना है",
            "What to do next", 
            "मुझे आपसे कुछ और जानना है",
            "I need to know more from you",
            "अगले कदम",
            "next steps"
        ]
        
        let hasEndingMarkers = responseIndicators.contains { response.lowercased().contains($0.lowercased()) }
        let hasMinimumLength = response.count > 200 // Reasonable minimum for complete response
        
        if hasEndingMarkers && hasMinimumLength {
            // Response appears complete, proceed immediately
            processCompleteResponse()
        } else {
            // Start timer to check for completion
            var checkCount = 0
            responseCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                checkCount += 1
                
                let hasNewEndingMarkers = responseIndicators.contains { self.response.lowercased().contains($0.lowercased()) }
                let hasNewMinimumLength = self.response.count > 200
                
                // Consider complete if we have ending markers and minimum length, or after 5 seconds max
                if (hasNewEndingMarkers && hasNewMinimumLength) || checkCount >= 5 {
                    timer.invalidate()
                    self.responseCheckTimer = nil
                    self.processCompleteResponse()
                }
            }
        }
    }
    
    private func processCompleteResponse() {
        isResponseComplete = true
        parseResponse()
        
        // Add delay to ensure parsing is complete before animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                self.animateResponse = true
            }
        }
    }
    
    private func parseResponse() {
        // Smart parsing that creates sections based on content
        let paragraphs = response.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var currentSections: [ResponseSection] = []
        
        for paragraph in paragraphs {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            // Determine section based on content patterns
            if trimmed.contains("मैं आपकी स्थिति समझ गया हूँ") || trimmed.contains("I understand your situation") {
                currentSections.append(ResponseSection(
                    title: "आपकी स्थिति की समझ / Understanding Your Situation",
                    content: [trimmed],
                    icon: "heart.fill",
                    color: .blue
                ))
            }
            else if trimmed.contains("यह कानूनी मामला है") || trimmed.contains("This appears to be a legal matter") {
                currentSections.append(ResponseSection(
                    title: "कानूनी मामले की पहचान / Legal Matter Identification",
                    content: [trimmed],
                    icon: "scale.3d",
                    color: .purple
                ))
            }
            else if trimmed.contains("आपकी मुख्य समस्याएं हैं") || trimmed.contains("Your main concerns are") {
                currentSections.append(ResponseSection(
                    title: "मुख्य समस्याएं / Key Issues Identified",
                    content: [trimmed],
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                ))
            }
            else if trimmed.contains("मेरी सलाह है") || trimmed.contains("My advice to you is") {
                currentSections.append(ResponseSection(
                    title: "विशेषज्ञ कानूनी सलाह / Expert Legal Advice",
                    content: [trimmed],
                    icon: "lightbulb.fill",
                    color: .yellow
                ))
            }
            else if trimmed.contains("आपको तुरंत ये काम करने चाहिए") || trimmed.contains("You should immediately do these things") {
                currentSections.append(ResponseSection(
                    title: "तत्काल कार्य योजना / Immediate Action Steps",
                    content: [trimmed],
                    icon: "clock.fill",
                    color: .red
                ))
            }
            else if trimmed.contains("महत्वपूर्ण बातें") || trimmed.contains("Important things to remember") {
                currentSections.append(ResponseSection(
                    title: "महत्वपूर्ण जानकारी / Critical Information",
                    content: [trimmed],
                    icon: "info.circle.fill",
                    color: .cyan
                ))
            }
            else if (trimmed.contains("मुझे आपसे कुछ और") || trimmed.contains("I need to know") || 
                     trimmed.contains("अतिरिक्त प्रश्न") || trimmed.contains("additional questions") || 
                     trimmed.contains("और जानकारी") || trimmed.contains("more information") ||
                     trimmed.contains("कुछ सवाल") || trimmed.contains("some questions")) {
                currentSections.append(ResponseSection(
                    title: "अतिरिक्त प्रश्न / Additional Questions",
                    content: [trimmed],
                    icon: "questionmark.circle.fill",
                    color: .mint
                ))
            }
            else if (trimmed.contains("आगे क्या") || trimmed.contains("What to do") || 
                     trimmed.contains("अगले कदम") || trimmed.contains("next steps") ||
                     trimmed.contains("अब क्या") || trimmed.contains("what to do") ||
                     trimmed.contains("सुझाव") || trimmed.contains("suggestion")) {
                currentSections.append(ResponseSection(
                    title: "अगले कदम / Next Steps",
                    content: [trimmed],
                    icon: "arrow.right.circle.fill",
                    color: .green
                ))
            }
            else {
                // If no specific section is matched, add as general advice
                if currentSections.isEmpty {
                    currentSections.append(ResponseSection(
                        title: "कानूनी राय / Legal Opinion",
                        content: [trimmed],
                        icon: "scale.3d",
                        color: .blue
                    ))
                } else {
                    // Add to the most appropriate existing section or create new one
                    var lastSection = currentSections.removeLast()
                    lastSection.content.append(trimmed)
                    currentSections.append(lastSection)
                }
            }
        }
        
        // If no structured parsing worked, create intelligent sections
        if currentSections.isEmpty {
            // Split response into logical sections based on content patterns
            let responseText = response.trimmingCharacters(in: .whitespacesAndNewlines)
            let sentences = responseText.components(separatedBy: CharacterSet(charactersIn: "।.!?"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0.count > 10 }
            
            if sentences.count > 3 {
                // Create multiple sections from content
                let midPoint = sentences.count / 2
                
                currentSections.append(ResponseSection(
                    title: "विशेषज्ञ विश्लेषण / Expert Analysis",
                    content: Array(sentences[0..<midPoint]),
                    icon: "brain.head.profile",
                    color: .blue
                ))
                
                if midPoint < sentences.count {
                    currentSections.append(ResponseSection(
                        title: "सुझाव व कार्य योजना / Recommendations & Action Plan",
                        content: Array(sentences[midPoint...]),
                        icon: "arrow.right.circle.fill",
                        color: .green
                    ))
                }
            } else {
                // Single comprehensive section
                currentSections.append(ResponseSection(
                    title: "कानूनी विशेषज्ञ की राय / Legal Expert Response",
                    content: [responseText],
                    icon: "scale.3d",
                    color: .green
                ))
            }
        }
        
        // Ensure all sections have content
        currentSections = currentSections.filter { !$0.content.isEmpty && !$0.content.allSatisfy { $0.isEmpty } }
        
        if currentSections.isEmpty {
            currentSections.append(ResponseSection(
                title: "कानूनी सलाह / Legal Advice",
                content: [response],
                icon: "person.fill.questionmark",
                color: .blue
            ))
        }
        
        self.sections = currentSections
    }
}

struct ResponseSectionView: View {
    let section: FormattedLegalResponseView.ResponseSection
    let animationDelay: Double
    let isVisible: Bool
    
    @State private var animateSection = false
    @State private var animateText = false
    @State private var hasTriggeredAnimation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(section.color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: section.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(section.color)
                }
                .scaleEffect(animateSection ? 1.0 : 0.8)
                .animation(.spring(duration: 0.6, bounce: 0.4).delay(animationDelay), value: animateSection)
                
                Text(section.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .opacity(animateSection ? 1.0 : 0.0)
                    .offset(x: animateSection ? 0 : -15)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay + 0.1), value: animateSection)
                
                Spacer()
            }
            
            // Section Content with word-by-word animation
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(section.content.enumerated()), id: \.offset) { contentIndex, content in
                    if animateText {
                        AnimatedTextView(
                            text: formatText(content),
                            font: .system(size: 14, weight: .medium),
                            color: .white.opacity(0.9),
                            animationSpeed: 0.06
                        )
                        .padding(.leading, 8)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.03))
                    .stroke(section.color.opacity(0.2), lineWidth: 1)
            )
            .opacity(animateSection ? 1.0 : 0.0)
            .offset(y: animateSection ? 0 : 20)
            .animation(.spring(duration: 0.8, bounce: 0.2).delay(animationDelay + 0.2), value: animateSection)
        }
        .onAppear {
            guard !hasTriggeredAnimation && isVisible else { return }
            hasTriggeredAnimation = true
            
            withAnimation {
                animateSection = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + 0.5) {
                animateText = true
            }
        }
    }
    
    private func formatText(_ text: String) -> String {
        // Clean up and format the text for better readability
        return text
            .replacingOccurrences(of: "मैं आपकी स्थिति समझ गया हूँ", with: "")
            .replacingOccurrences(of: "यह कानूनी मामला है", with: "")
            .replacingOccurrences(of: "आपकी मुख्य समस्याएं हैं", with: "")
            .replacingOccurrences(of: "मेरी सलाह है", with: "")
            .replacingOccurrences(of: "आपको तुरंत ये काम करने चाहिए", with: "")
            .replacingOccurrences(of: "महत्वपूर्ण बातें", with: "")
            .replacingOccurrences(of: "मुझे आपसे कुछ और जानना है", with: "")
            .replacingOccurrences(of: "आगे क्या करना है", with: "")
            .replacingOccurrences(of: "I understand your situation", with: "")
            .replacingOccurrences(of: "This appears to be a legal matter", with: "")
            .replacingOccurrences(of: "Your main concerns are", with: "")
            .replacingOccurrences(of: "My advice to you is", with: "")
            .replacingOccurrences(of: "You should immediately do these things", with: "")
            .replacingOccurrences(of: "Important things to remember", with: "")
            .replacingOccurrences(of: "I need to know more from you", with: "")
            .replacingOccurrences(of: "What to do next", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
} 