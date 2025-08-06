import SwiftUI
import AppKit

struct MenuBarView: View {
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var notificationManager = NotificationManager()
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var isRecording = false
    
    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?
    var onSettingsChanged: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick actions section
            VStack(spacing: 8) {
                // Recording control
                HStack {
                    Button(action: {
                        if isRecording {
                            onStopRecording?()
                        } else {
                            onStartRecording?()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.title2)
                                .foregroundColor(isRecording ? .red : .blue)
                            
                            Text(isRecording ? "Stop Recording" : "Start Recording")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .help(isRecording ? "Stop recording (or use hotkey)" : "Start recording (or use hotkey)")
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
                    subtitle: "\(historyManager.transcriptions.count) recent transcriptions"
                ) {
                    showingHistory = true
                }
                
                Divider()
                    .padding(.leading, 44)
                
                // Test notification
                MenuItemView(
                    icon: "speaker.wave.3.fill",
                    title: "Test Notification",
                    subtitle: "Play success sound"
                ) {
                    notificationManager.showTranscriptionSuccess()
                }
                
                Divider()
                    .padding(.leading, 44)
                
                // Quit
                MenuItemView(
                    icon: "power",
                    title: "Quit",
                    subtitle: "Exit application",
                    destructive: true
                ) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .frame(width: 280)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingSettings) {
            SettingsView(onSettingsChanged: onSettingsChanged)
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
    }
    
    func updateRecordingState(_ recording: Bool) {
        isRecording = recording
    }
    
    func addTranscription(_ text: String, audioFileName: String? = nil) {
        historyManager.addTranscription(text, audioFileName: audioFileName)
    }
}

struct MenuItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    var destructive: Bool = false
    let action: () -> Void
    
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
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1.0 : 0.6)
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