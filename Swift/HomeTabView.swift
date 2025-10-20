import SwiftUI

struct HomeTabView: View {
    @StateObject private var historyManager = HistoryManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Transcription History")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your recent speech-to-text transcriptions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            // Transcriptions List
            if historyManager.transcriptions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No transcriptions yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Start recording to see your transcriptions here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(historyManager.transcriptions.prefix(20)) { transcription in
                            TranscriptionCard(transcription: transcription)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}

struct TranscriptionCard: View {
    let transcription: TranscriptionEntry
    @State private var isCopied = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Main Content
            VStack(alignment: .leading, spacing: 8) {
                // Timestamp
                Text(formattedDate(transcription.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Transcription Text
                Text(transcription.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Clipboard Icon Button
            Button(action: copyToClipboard) {
                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isCopied ? .blue : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 24, height: 24)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(transcription.text, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopied = false
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeTabView()
}


