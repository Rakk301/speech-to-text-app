import SwiftUI

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @State private var showingClearAlert = false
    
    var onBack: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: {
                    onBack?()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(.body)
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("Transcription History")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Last \(historyManager.transcriptions.count) transcription\(historyManager.transcriptions.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    showingClearAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Clear History")
                .disabled(historyManager.transcriptions.isEmpty)
            }
            .padding()
            
            Divider()
            
            // Content
            if historyManager.transcriptions.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No transcriptions yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Start recording to see your transcription history here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // History list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(historyManager.transcriptions) { entry in
                            HistoryRowView(entry: entry) {
                                historyManager.copyToClipboard(entry)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 400, height: 300)
        .alert("Clear History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                historyManager.clearHistory()
            }
        } message: {
            Text("Are you sure you want to clear all transcription history? This action cannot be undone.")
        }
    }
}

struct HistoryRowView: View {
    let entry: TranscriptionEntry
    let onCopy: () -> Void
    
    @State private var isHovered = false
    @State private var showingCopyConfirmation = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Circle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 6, height: 6)
            }
            .frame(width: 50)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                
                if let audioFile = entry.audioFileName {
                    Text("Audio: \(audioFile)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Copy button
            Button(action: {
                onCopy()
                showCopyFeedback()
            }) {
                Image(systemName: showingCopyConfirmation ? "checkmark" : "doc.on.clipboard")
                    .foregroundColor(showingCopyConfirmation ? .green : .blue)
                    .font(.system(size: 14))
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isHovered ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .help("Copy to Clipboard")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .opacity(isHovered ? 1.0 : 0.5)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    private func showCopyFeedback() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showingCopyConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingCopyConfirmation = false
            }
        }
    }
}

#Preview {
    HistoryView()
}