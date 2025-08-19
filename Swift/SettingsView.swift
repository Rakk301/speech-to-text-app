import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var permissionManager = PermissionManager()
    @State private var isRecordingHotkey = false
    
    let onSettingsChanged: (() -> Void)?
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
                
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            Divider()
            
            // Permissions Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Permissions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
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
            .padding(.horizontal, 20)
            
            Divider()
            
            // Whisper Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("Whisper Model")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 10) {
                    HStack {
                        Text("Model:")
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .leading)
                            .font(.system(size: 14))
                        
                        Picker("Model", selection: $settingsManager.whisperModel) {
                            ForEach(settingsManager.availableModels, id: \.self) { model in
                                Text(model.capitalized)
                                    .tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settingsManager.whisperModel) { _ in
                            settingsManager.saveSettings()
                            onSettingsChanged?()
                        }
                    }
                    
                    HStack {
                        Text("Language:")
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .leading)
                            .font(.system(size: 14))
                        
                        Picker("Language", selection: $settingsManager.whisperLanguage) {
                            ForEach(settingsManager.availableLanguages, id: \.self) { language in
                                Text(settingsManager.languageDisplayName(language))
                                    .tag(language)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settingsManager.whisperLanguage) { _ in
                            settingsManager.saveSettings()
                            onSettingsChanged?()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Divider()
            
            // Hotkey Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("Global Hotkey")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("Current:")
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .leading)
                        .font(.system(size: 14))
                    
                    Text(settingsManager.getHotkeyDisplayString())
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    Button(isRecordingHotkey ? "Press keys..." : "Change") {
                        // Hotkey recording logic would go here
                        isRecordingHotkey.toggle()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRecordingHotkey)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Permission Row View
struct PermissionRow: View {
    let icon: String
    let title: String
    let status: PermissionManager.PermissionStatus
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(title)
                .font(.system(size: 14))
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            if status != .authorized {
                Button("Grant") {
                    action()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12, weight: .medium))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
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

#Preview {
    SettingsView(onSettingsChanged: nil, onBack: nil)
}
