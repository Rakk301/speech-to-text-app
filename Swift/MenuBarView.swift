import SwiftUI
import AppKit

struct MenuBarView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @StateObject private var notificationManager = NotificationManager()
    @State private var isRecording = false
    @State private var isSettingsExpanded = false
    @State private var isHistoryExpanded = false
    
    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?
    var onSettingsChanged: (() -> Void)?
    
    var body: some View {
        Group {
            if isSettingsExpanded {
                // Settings view takes over the entire popover
                SettingsView(
                    onSettingsChanged: onSettingsChanged,
                    onBack: { isSettingsExpanded = false }
                )
                .frame(width: 420)
            } else if isHistoryExpanded {
                // History view takes over the entire popover
                HistoryView(
                    onBack: { isHistoryExpanded = false }
                )
                .frame(width: 420)
            } else {
                // Default popover content
                VStack(spacing: 0) {
                    // Recording Controls Section
                    RecordingControlsSection(
                        isRecording: isRecording,
                        onStartRecording: {
                            if isRecording {
                                onStopRecording?()
                                isRecording = false
                            } else {
                                onStartRecording?()
                                isRecording = true
                            }
                        }
                    )
                    
                    Divider()
                    
                    // Settings Section
                    ExpandableSection(
                        title: "Settings",
                        subtitle: "Configure models and hotkeys",
                        icon: "gearshape.fill",
                        isExpanded: $isSettingsExpanded
                    ) {
                        // This content won't be shown since we're replacing the whole popover
                        EmptyView()
                    }
                    
                    Divider()
                    
                    // History Section
                    ExpandableSection(
                        title: "History",
                        subtitle: "\(historyManager.transcriptions.count) recent transcription\(historyManager.transcriptions.count == 1 ? "" : "s")",
                        icon: "clock.arrow.circlepath",
                        isExpanded: $isHistoryExpanded
                    ) {
                        // This content won't be shown since we're replacing the whole popover
                        EmptyView()
                    }
                    
                    Divider()
                    
                    // Quit Section
                    QuitSection()
                }
                .frame(width: 280)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .animation(.easeInOut(duration: 0.2), value: isSettingsExpanded)
        .animation(.easeInOut(duration: 0.2), value: isHistoryExpanded)
    }
    
    func updateRecordingState(_ recording: Bool) {
        isRecording = recording
    }
    
    func addTranscription(_ text: String, audioFileName: String? = nil) {
        historyManager.addTranscription(text, audioFileName: audioFileName)
    }
}

// MARK: - Recording Controls Section
struct RecordingControlsSection: View {
    let isRecording: Bool
    let onStartRecording: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Recording control button
            HStack {
                Button(action: onStartRecording) {
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
            
            Text(isRecording ? "Recording in progress..." : "Ready to record")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Expandable Section
struct ExpandableSection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isExpanded: Bool
    let content: Content
    
    init(title: String, subtitle: String, icon: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._isExpanded = isExpanded
        self.content = content()
    }
    
    var body: some View {
        Button(action: { isExpanded.toggle() }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quit Section
struct QuitSection: View {
    var body: some View {
        Button(action: { NSApplication.shared.terminate(nil) }) {
            HStack(spacing: 12) {
                Image(systemName: "power")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 20, height: 20)

                    Text("Quit Application")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MenuBarView()
}
