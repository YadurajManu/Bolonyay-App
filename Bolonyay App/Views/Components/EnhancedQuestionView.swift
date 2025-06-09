import SwiftUI

struct EnhancedQuestionView: View {
    let question: String
    let questionNumber: Int
    let totalQuestions: Int
    let isCurrentQuestion: Bool
    let onTap: () -> Void
    
    @State private var animateIn = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Question Header
                HStack(spacing: 12) {
                    // Question Number Badge
                    ZStack {
                        Circle()
                            .fill(isCurrentQuestion ? Color.orange : Color.white.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Text("\(questionNumber)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isCurrentQuestion ? .white : .white.opacity(0.7))
                    }
                    .scaleEffect(animateIn ? 1.0 : 0.8)
                    .animation(.spring(duration: 0.6, bounce: 0.4).delay(Double(questionNumber) * 0.1), value: animateIn)
                    
                    // Progress Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Question \(questionNumber) of \(totalQuestions)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isCurrentQuestion ? .orange : .white.opacity(0.6))
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isCurrentQuestion ? Color.orange : Color.green)
                                    .frame(width: geometry.size.width * (Double(questionNumber) / Double(totalQuestions)), height: 4)
                                    .animation(.easeInOut(duration: 0.8), value: animateIn)
                            }
                        }
                        .frame(height: 4)
                    }
                    
                    Spacer()
                    
                    // Status Icon
                    if isCurrentQuestion {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                            .scaleEffect(animateIn ? 1.0 : 0.5)
                            .opacity(animateIn ? 1.0 : 0.0)
                            .animation(.spring(duration: 0.8, bounce: 0.5).delay(0.3), value: animateIn)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                            .opacity(0.6)
                    }
                }
                
                // Question Text
                VStack(alignment: .leading, spacing: 12) {
                    Text(cleanedQuestion)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .opacity(animateIn ? 1.0 : 0.0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(.spring(duration: 0.8, bounce: 0.3).delay(Double(questionNumber) * 0.1 + 0.2), value: animateIn)
                    
                    // Hindi/English Translation
                    if question.contains("(") && question.contains(")") {
                        let translation = extractTranslation(from: question)
                        if !translation.isEmpty {
                            Text(translation)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .italic()
                                .opacity(animateIn ? 0.8 : 0.0)
                                .offset(y: animateIn ? 0 : 15)
                                .animation(.spring(duration: 0.8, bounce: 0.3).delay(Double(questionNumber) * 0.1 + 0.4), value: animateIn)
                        }
                    }
                    
                    // Action Hint
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange.opacity(0.7))
                        
                        Text(isCurrentQuestion ? "Tap to record your answer" : "Tap to re-record")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange.opacity(0.7))
                    }
                    .opacity(animateIn ? 0.8 : 0.0)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(Double(questionNumber) * 0.1 + 0.6), value: animateIn)
                }
                .padding(.leading, 8)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isCurrentQuestion ? 
                          Color.orange.opacity(0.1) : 
                          Color.white.opacity(0.05))
                    .stroke(isCurrentQuestion ? 
                            Color.orange.opacity(0.4) : 
                            Color.white.opacity(0.2), lineWidth: 1.5)
            )
            .scaleEffect(animateIn ? 1.0 : 0.95)
            .opacity(animateIn ? 1.0 : 0.0)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(Double(questionNumber) * 0.1), value: animateIn)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }
    
    private var cleanedQuestion: String {
        // Remove parenthetical translations for cleaner display
        let pattern = "\\s*\\([^)]*\\)"
        return question.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractTranslation(from text: String) -> String {
        let pattern = "\\(([^)]*)\\)"
        if let range = text.range(of: pattern, options: .regularExpression) {
            let match = String(text[range])
            return match.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        }
        return ""
    }
}

struct ProfessionalQuestionListView: View {
    let questions: [String]
    let currentQuestionIndex: Int
    let onQuestionTap: (Int) -> Void
    
    @State private var animateList = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    Text("Strategic Case Filing Questions")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Questions Count Badge
                    Text("\(questions.count) Questions")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.2))
                        )
                }
                
                Text("Answer each question thoroughly to build a comprehensive legal case file")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(animateList ? 1.0 : 0.0)
                    .offset(y: animateList ? 0 : 10)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.3), value: animateList)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Questions List
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                        EnhancedQuestionView(
                            question: question,
                            questionNumber: index + 1,
                            totalQuestions: questions.count,
                            isCurrentQuestion: index == currentQuestionIndex,
                            onTap: { onQuestionTap(index) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.6))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                animateList = true
            }
        }
    }
}

struct QuestionCategoryHeaderView: View {
    let title: String
    let icon: String
    let color: Color
    let animationDelay: Double
    
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            .scaleEffect(animate ? 1.0 : 0.8)
            .animation(.spring(duration: 0.6, bounce: 0.4).delay(animationDelay), value: animate)
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .opacity(animate ? 1.0 : 0.0)
                .offset(x: animate ? 0 : -20)
                .animation(.spring(duration: 0.8, bounce: 0.3).delay(animationDelay + 0.1), value: animate)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            withAnimation {
                animate = true
            }
        }
    }
} 