import SwiftUI

struct CurrentQuestionRecordingView: View {
    let question: String
    let questionNumber: Int
    let totalQuestions: Int
    let answer: String
    let onAnswerSubmit: (String) -> Void
    
    @State private var isRecording = false
    @State private var isProcessing = false
    @State private var textAnswer = ""
    @State private var recordingDuration: TimeInterval = 0.0
    @State private var recordingTimer: Timer?
    @State private var voiceError: String?
    @State private var animateIn = false
    @StateObject private var bhashiniManager = BhashiniManager()
    
    private let maxRecordingDuration: TimeInterval = 15.0
    
    var body: some View {
        VStack(spacing: 24) {
            // Question Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Text("\(questionNumber)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .scaleEffect(animateIn ? 1.0 : 0.8)
                    .animation(.spring(duration: 0.6, bounce: 0.4), value: animateIn)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Question \(questionNumber) of \(totalQuestions)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)
                        
                        Text("Answer with your voice or type")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    CircularProgressView(
                        progress: Double(questionNumber) / Double(totalQuestions),
                        color: .orange
                    )
                    .frame(width: 40, height: 40)
                }
                
                // Question Text
                Text(cleanedQuestion)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .opacity(animateIn ? 1.0 : 0.0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.2), value: animateIn)
                
                // Translation if available
                if question.contains("(") && question.contains(")") {
                    let translation = extractTranslation(from: question)
                    if !translation.isEmpty {
                        Text(translation)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .italic()
                            .opacity(animateIn ? 0.8 : 0.0)
                            .animation(.spring(duration: 0.8, bounce: 0.3).delay(0.4), value: animateIn)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.05))
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
            )
            
            // Current Answer Display
            if !answer.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        
                        Text("Your Answer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Edit") {
                            textAnswer = answer
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                    }
                    
                    Text(answer)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.05))
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        )
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            // Recording Interface
            VStack(spacing: 20) {
                // Voice Recording Button
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    ZStack {
                        // Pulse rings when recording
                        if isRecording {
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                                    .frame(width: 100 + CGFloat(index * 20), height: 100 + CGFloat(index * 20))
                                    .scaleEffect(isRecording ? 1.5 : 1.0)
                                    .opacity(isRecording ? 0.0 : 0.8)
                                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(Double(index) * 0.3), value: isRecording)
                            }
                        }
                        
                        // Main button
                        Circle()
                            .fill(isRecording ? Color.red : Color.orange)
                            .frame(width: 80, height: 80)
                            .scaleEffect(isRecording ? 1.1 : 1.0)
                            .animation(.spring(duration: 0.3), value: isRecording)
                        
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(isProcessing)
                
                // Recording Status
                VStack(spacing: 8) {
                    if isRecording {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .opacity(0.8)
                            
                            Text("Recording... \(formatDuration(recordingDuration))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    } else if isProcessing {
                        Text("Processing your answer...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                    } else {
                        Text("Tap to record your answer")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // OR separator
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("OR")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                }
                
                // Text Input
                VStack(spacing: 12) {
                    TextField("Type your answer here...", text: $textAnswer, axis: .vertical)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .lineLimit(3...6)
                    
                    Button(action: {
                        if !textAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onAnswerSubmit(textAnswer)
                            textAnswer = ""
                        }
                    }) {
                        Text("Submit Answer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(textAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                          Color.gray.opacity(0.3) : 
                                          Color.blue)
                            )
                    }
                    .disabled(textAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Error Display
            if let error = voiceError {
                Text(error)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .onAppear {
            textAnswer = answer
            withAnimation(.spring(duration: 0.8, bounce: 0.3)) {
                animateIn = true
            }
        }
        .onDisappear {
            cleanup()
        }
    }
    
    // MARK: - Helper Functions
    
    private var cleanedQuestion: String {
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
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Voice Recording
    
    private func startRecording() {
        guard !isRecording && !isProcessing else { return }
        
        isRecording = true
        recordingDuration = 0.0
        voiceError = nil
        
        // Start recording timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
            
            if recordingDuration >= maxRecordingDuration {
                stopRecording()
            }
        }
        
        // Start Bhashini recording
        Task {
            do {
                try await bhashiniManager.startRecording()
            } catch {
                DispatchQueue.main.async {
                    self.voiceError = "Failed to start recording: \(error.localizedDescription)"
                    self.isRecording = false
                    self.recordingTimer?.invalidate()
                }
            }
        }
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        isProcessing = true
        recordingTimer?.invalidate()
        
        Task {
            do {
                let transcription = try await bhashiniManager.stopRecordingAndTranscribe()
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    if !transcription.isEmpty {
                        self.onAnswerSubmit(transcription)
                    } else {
                        self.voiceError = "No speech detected. Please try again."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.voiceError = "Transcription failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func cleanup() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        if isRecording {
            Task {
                try? await bhashiniManager.stopRecordingAndTranscribe()
            }
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
        }
    }
} 