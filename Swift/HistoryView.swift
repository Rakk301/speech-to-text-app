import SwiftUI

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @State private var showingClearAlert = false
    
    let onBack: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with back button
            HStack {
                Button(action: { onBack?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                        Text("Back")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("History")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            Divider()
            
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transcription History")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Last \(historyManager.transcriptions.count) transcription\(historyManager.transcriptions.count == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingClearAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Clear History")
                .disabled(historyManager.transcriptions.isEmpty)
            }
            .padding(.horizontal, 20)
            
            // Content
            if historyManager.transcriptions.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No transcriptions yet")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    Text("Start recording to see your transcription history here")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // History list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(historyManager.transcriptions.prefix(10)) { entry in
                            HistoryRowView(entry: entry) {
                                historyManager.copyToClipboard(entry)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 300)
            }
        }
        .frame(maxWidth: .infinity)
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
    
    var body: some View {
        HStack(spacing: 10) {
            Text(entry.text)
                .font(.system(size: 14))
                .lineLimit(3)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Copy to clipboard")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    HistoryView(onBack: nil)
}
