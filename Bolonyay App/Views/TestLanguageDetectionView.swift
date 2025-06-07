import SwiftUI

struct TestLanguageDetectionView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var testText = ""
    @State private var detectedLanguage = ""
    @State private var isDetecting = false
    @State private var errorMessage = ""
    
    // Sample test texts for different languages
    private let sampleTexts = [
        "Hello, how are you today?",
        "मैं आज बहुत खुश हूं।",
        "આજે હું ખુશ છું.",
        "آج میں بہت خوش ہوں۔",
        "आज मी खूप आनंदी आहे।"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Test Azure OpenAI Language Detection")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Test Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter text to test:")
                        .font(.headline)
                    
                    TextEditor(text: $testText)
                        .frame(height: 100)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Sample text buttons
                    Text("Or try these samples:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(sampleTexts, id: \.self) { sample in
                            Button(action: {
                                testText = sample
                            }) {
                                Text(sample)
                                    .font(.caption)
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                                    .lineLimit(2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Test Button
                Button(action: testLanguageDetection) {
                    HStack {
                        if isDetecting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isDetecting ? "Detecting..." : "Test Detection")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(testText.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(testText.isEmpty || isDetecting)
                
                // Results Section
                if !detectedLanguage.isEmpty || !errorMessage.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Results:")
                            .font(.headline)
                        
                        if !detectedLanguage.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Detected Language: \(detectedLanguage.capitalized)")
                                    .fontWeight(.semibold)
                            }
                            .padding(12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if !errorMessage.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Error: \(errorMessage)")
                                    .fontWeight(.medium)
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // API Info
                VStack(spacing: 8) {
                    Text("Using Azure OpenAI GPT-4.1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Endpoint: bolonyay.openai.azure.com")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func testLanguageDetection() {
        guard !testText.isEmpty else { return }
        
        isDetecting = true
        detectedLanguage = ""
        errorMessage = ""
        
        Task {
            do {
                let azureManager = AzureOpenAIManager()
                let result = try await azureManager.identifyLanguage(from: testText)
                
                DispatchQueue.main.async {
                    detectedLanguage = result
                    isDetecting = false
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    isDetecting = false
                }
            }
        }
    }
}

#Preview {
    TestLanguageDetectionView()
        .environmentObject(LocalizationManager())
} 