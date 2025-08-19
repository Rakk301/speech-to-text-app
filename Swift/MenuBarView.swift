import SwiftUI
import AppKit

enum MenuView {
    case main
    case settings
    case history
}

struct MenuBarView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @StateObject private var notificationManager = NotificationManager()
    @State private var currentView: MenuView = .main
    @State private var isRecording = false
    
    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?
    var onSettingsChanged: (() -> Void)?
    
    var body: some View {
        Group {
            switch currentView {
            case .main:
                MainMenuView(
                    isRecording: isRecording,
                    historyCount: historyManager.transcriptions.count,
                    onStartRecording: {
                        if isRecording {
                            onStopRecording?()
                            isRecording = false
                        } else {
                            onStartRecording?()
                            isRecording = true
                        }
                    },
                    onShowSettings: { currentView = .settings },
                    onShowHistory: { currentView = .history },
                    onQuit: { NSApplication.shared.terminate(nil) }
                )
            case .settings:
                NavigationSettingsView(
                    onBack: { currentView = .main },
                    onSettingsChanged: onSettingsChanged
                )
            case .history:
                NavigationHistoryView(
                    onBack: { currentView = .main }
                )
            }
        }
        .frame(width: 280)
        .animation(.easeInOut(duration: 0.2), value: currentView)
    }
    
    func updateRecordingState(_ recording: Bool) {
        isRecording = recording
    }
    
    func addTranscription(_ text: String, audioFileName: String? = nil) {
        historyManager.addTranscription(text, audioFileName: audioFileName)
    }
}

// MARK: - Main Menu View
struct MainMenuView: View {
    let isRecording: Bool
    let historyCount: Int
    let onStartRecording: () -> Void
    let onShowSettings: () -> Void
    let onShowHistory: () -> Void
    let onQuit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick actions section
            VStack(spacing: 8) {
                // Recording control
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
                    onShowSettings()
                }
                
                Divider()
                    .padding(.leading, 44)
                
                // History
                MenuItemView(
                    icon: "clock.arrow.circlepath",
                    title: "History",
                    subtitle: "\(historyCount) recent transcription\(historyCount == 1 ? "" : "s")"
                ) {
                    onShowHistory()
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
                    onQuit()
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Navigation Settings View
struct NavigationSettingsView: View {
    let onBack: () -> Void
    let onSettingsChanged: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: onBack) {
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
                
                Text("Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Settings content (compact version)
            ScrollView {
                CompactSettingsView(
                    onSettingsChanged: onSettingsChanged
                )
                .padding()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Compact Settings View
struct CompactSettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var permissionManager = PermissionManager()
    @State private var isRecordingHotkey = false
    
    let onSettingsChanged: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            // Permissions Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Permissions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 6) {
                    PermissionRow(
                        icon: "mic.fill",
                        title: "Microphone",
                        status: permissionManager.microphonePermissionStatus,
                        action: { 
                            Task {
                                await permissionManager.requestMicrophonePermission()
                            }
                        }
                    )
                    
                    PermissionRow(
                        icon: "accessibility",
                        title: "Accessibility",
                        status: permissionManager.accessibilityPermissionStatus,
                        action: { permissionManager.requestAccessibilityPermission() }
                    )
                    

                }
            }
            
            Divider()
            
            // Hotkey Configuration
            VStack(alignment: .leading, spacing: 8) {
                Text("Global Hotkey")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("Current:")
                        .foregroundColor(.secondary)
                    
                    Text(settingsManager.getHotkeyDisplayString())
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Button(isRecordingHotkey ? "Press keys..." : "Change") {
                        // Hotkey recording logic would go here
                        isRecordingHotkey.toggle()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRecordingHotkey)
                }
            }
            
            Divider()
            
            // Quick Actions
            VStack(spacing: 8) {
                Button("Open Full Settings") {
                    // Open the full settings window
                    let settingsView = SettingsView(onSettingsChanged: onSettingsChanged)
                    let hostingController = NSHostingController(rootView: settingsView)
                    
                    let window = NSWindow(
                        contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                        styleMask: [.titled, .closable, .resizable],
                        backing: .buffered,
                        defer: false
                    )
                    window.title = "Settings"
                    window.contentViewController = hostingController
                    window.center()
                    window.makeKeyAndOrderFront(nil)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Permission Row View
struct PermissionRow: View {
    let icon: String
    let title: String
    let status: PermissionManager.PermissionStatus
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if status != .authorized {
                Button("Grant") {
                    action()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch status {
        case .authorized: return .green
        case .denied, .restricted: return .red
        case .notDetermined: return .orange
        }
    }
    
    private var statusText: String {
        switch status {
        case .authorized: return "Granted"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Requested"
        }
    }
}

// MARK: - Navigation History View
struct NavigationHistoryView: View {
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: onBack) {
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
                
                Text("History")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // History content
            HistoryView(onBack: onBack)
        }
        .background(Color(NSColor.windowBackgroundColor))
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