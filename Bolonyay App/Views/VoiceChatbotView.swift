import SwiftUI
import AVFoundation

struct VoiceChatbotView: View {
    @StateObject private var voiceChatbotManager = VoiceChatbotManager()
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        ZStack {
            // Clean background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Minimal header
                headerView
                
                // Chat area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if voiceChatbotManager.conversationHistory.isEmpty {
                                welcomeView
                            } else {
                                ForEach(voiceChatbotManager.conversationHistory) { message in
                                    MessageView(message: message)
                                        .id(message.id)
                                }
                            }
                            
                            if voiceChatbotManager.isProcessing {
                                ProcessingView()
                            }
                            
                            if let errorMessage = voiceChatbotManager.errorMessage {
                                ChatErrorView(message: errorMessage)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                    .onChange(of: voiceChatbotManager.conversationHistory.count) { _ in
                        if let lastMessage = voiceChatbotManager.conversationHistory.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Voice controls
            VStack {
                Spacer()
                voiceControlsView
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.white)
                    .font(.title3)
            }
            
            Spacer()
            
            Text("न्याय")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                voiceChatbotManager.clearConversation()
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.title3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Welcome
    
    private var welcomeView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("न्")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Text("कानूनी सहायक")
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            VStack(spacing: 8) {
                Text("माइक दबाएं और सवाल पूछें")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
                
                Text("\"तलाक कैसे करें?\"")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                    .italic()
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Voice Controls
    
    private var voiceControlsView: some View {
        VStack(spacing: 16) {
            if voiceChatbotManager.isListening {
                audioVisualizerView
            }
            
            Button(action: {
                if voiceChatbotManager.isListening {
                    voiceChatbotManager.stopListening()
                } else {
                    voiceChatbotManager.startListening()
                }
            }) {
                Circle()
                    .fill(voiceChatbotManager.isListening ? Color.red : Color.white)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: voiceChatbotManager.isListening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(voiceChatbotManager.isListening ? .white : .black)
                    )
                    .scaleEffect(voiceChatbotManager.isListening ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: voiceChatbotManager.isListening)
            }
            .disabled(voiceChatbotManager.isProcessing)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 40)
    }
    
    private var audioVisualizerView: some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { index in
                let height = 20 + (voiceChatbotManager.audioLevel * 20)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.red.opacity(0.7))
                    .frame(width: 3, height: CGFloat(height))
                    .animation(.easeInOut(duration: 0.1), value: voiceChatbotManager.audioLevel)
            }
        }
        .frame(height: 40)
    }
    
    private var statusText: String {
        if voiceChatbotManager.isListening {
            return "सुन रहा हूँ..."
        } else if voiceChatbotManager.isProcessing {
            return "सोच रहा हूँ..."
        } else {
            return "पूछें"
        }
    }
}

// MARK: - Message View

struct MessageView: View {
    let message: VoiceChatbotManager.ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                userMessageView
            } else {
                assistantMessageView
                Spacer()
            }
        }
    }
    
    private var userMessageView: some View {
        Text(message.content)
            .font(.body)
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
            )
            .frame(maxWidth: 260, alignment: .trailing)
    }
    
    private var assistantMessageView: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 24, height: 24)
                .overlay(
                    Text("न्")
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            Text(message.content)
                .font(.body)
                .foregroundColor(.white)
                .lineLimit(nil)
                .frame(maxWidth: 240, alignment: .leading)
        }
    }
}

// MARK: - Processing View

struct ProcessingView: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 24, height: 24)
                .overlay(
                    Text("न्")
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            Text("सोच रहा हूँ" + String(repeating: ".", count: dotCount))
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                        dotCount = (dotCount + 1) % 4
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Chat Error View

struct ChatErrorView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.red.opacity(0.7))
                .font(.caption)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
    }
}

// MARK: - Preview

struct VoiceChatbotView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceChatbotView()
            .environmentObject(LocalizationManager())
            .preferredColorScheme(.dark)
    }
} 