import SwiftUI
import AppKit

struct MenuBarView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @StateObject private var notificationManager = NotificationManager()
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var isRecording = false
    
    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?
    var onSettingsChanged: (() -> Void)?
    var onAddTranscription: ((String, String?) -> Void)? // Callback for adding transcriptions
    
    // Computed property to safely access transcription count
    private var transcriptionCountText: String {
        let count = historyManager.transcriptions.count
        return "\(count) recent transcription\(count == 1 ? "" : "s")"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick actions section
            VStack(spacing: 8) {
                // Recording control
                HStack {
                    Button(action: {
                        if isRecording {
                            onStopRecording?()
                            isRecording = false
                        } else {
                            onStartRecording?()
                            isRecording = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                                .foregroundColor(isRecording ? .red : .blue)
                            
                            Text(isRecording ? "Stop Recording" : "Start Recording")
                                .font(.headline)
                                .foregroundColor(isRecording ? .red : .primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .opacity(isRecording ? 0.8 : 1.0)
                    )
                    .help(isRecording ? "Stop recording (or use hotkey)" : "Start recording (or use hotkey)")
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
                }
                
                // Status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(isRecording ? Color.red : Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text(isRecording ? "Recording in progress..." : "Ready to record")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            // Menu items
            VStack(spacing: 0) {
                // Settings
                MenuItemView(
                    icon: "gearshape.fill",
                    title: "Settings",
                    subtitle: "Configure models and hotkeys"
                ) {
                    showingSettings = true
                }
                
                Divider()
                    .padding(.leading, 44)
                
                // History
                MenuItemView(
                    icon: "clock.arrow.circlepath",
                    title: "History",
                    subtitle: transcriptionCountText
                ) {
                    showingHistory = true
                }
                
                Divider()
                    .padding(.leading, 44)
                
                // Quit
                MenuItemView(
                    icon: "power",
                    title: "Quit",
                    subtitle: "Exit application",
                    destructive: true,
                    showArrow: false
                ) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .frame(width: 280)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .onDisappear {
                    // Handle settings view dismissal
                    showingSettings = false
                }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(onBack: {
                showingHistory = false
            })
        }
    }
    
    func updateRecordingState(_ recording: Bool) {
        isRecording = recording
    }
    
    // Function to add transcription via callback
    func addTranscription(_ text: String, audioFileName: String? = nil) {
        onAddTranscription?(text, audioFileName)
    }
}

struct MenuItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    var destructive: Bool = false
    let action: () -> Void
    var showArrow: Bool = true
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(destructive ? .red : .blue)
                    .frame(width: 20, height: 20)
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(destructive ? .red : .primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow indicator
                if showArrow {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(isHovered ? 1.0 : 0.6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(isHovered ? Color(NSColor.selectedControlColor).opacity(0.3) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    MenuBarView()
}