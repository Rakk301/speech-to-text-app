import SwiftUI

struct SettingsView: View {
    @StateObject private var folderAccessManager = FolderAccessManager()
    @StateObject private var settingsManager: SettingsManager
    @State private var isEnabled = true
    @State private var showNotifications = true
    @State private var isRecordingHotkey = false
    @State private var localKeyMonitor: Any?
    @Environment(\.dismiss) private var dismiss
    
    var onSettingsChanged: (() -> Void)?
    
    init() {
        let folderManager = FolderAccessManager()
        self._folderAccessManager = StateObject(wrappedValue: folderManager)
        self._settingsManager = StateObject(wrappedValue: SettingsManager(folderAccessManager: folderManager))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with back button
            HStack {
                Button(action: {
                    dismiss()
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
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Header
            VStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Speech to Text")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Global hotkey utility for real-time transcription")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)
            
            // Settings Form
            Form {
                Section("Speech-to-Text Provider") {
                    HStack {
                        Text("Provider")
                        Spacer()
                        Text("Whisper")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Model", selection: $settingsManager.whisperModel) {
                        ForEach(settingsManager.availableModels, id: \.self) { model in
                            Text(model.capitalized)
                                .tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: settingsManager.whisperModel) { newValue in
                        let success = settingsManager.updateWhisperModel(newValue)
                        if success {
                            onSettingsChanged?()
                        }
                    }
                    
                    HStack {
                        Text("Model Size")
                        Spacer()
                        Text(modelSizeDescription)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    Picker("Language", selection: $settingsManager.whisperLanguage) {
                        ForEach(settingsManager.availableLanguages, id: \.self) { language in
                            Text(languageDisplayName(language))
                                .tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: settingsManager.whisperLanguage) { newValue in
                        let success = settingsManager.updateWhisperLanguage(newValue)
                        if success {
                            onSettingsChanged?()
                        }
                    }
                    
                    Picker("Task", selection: $settingsManager.whisperTask) {
                        ForEach(settingsManager.availableTasks, id: \.self) { task in
                            Text(task.capitalized)
                                .tag(task)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: settingsManager.whisperTask) { newValue in
                        let success = settingsManager.updateWhisperTask(newValue)
                        if success {
                            onSettingsChanged?()
                        }
                    }
                    
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Slider(value: $settingsManager.whisperTemperature, in: 0...1, step: 0.1)
                            .frame(width: 100)
                        Text(String(format: "%.1f", settingsManager.whisperTemperature))
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .frame(width: 30)
                    }
                    .onChange(of: settingsManager.whisperTemperature) { newValue in
                        let success = settingsManager.updateWhisperTemperature(newValue)
                        if success {
                            onSettingsChanged?()
                        }
                    }
                }
                
                Section("Hotkey Configuration") {
                    HStack {
                        Text("Global Hotkey")
                        Spacer()
                        Button(action: {
                            if isRecordingHotkey {
                                stopHotkeyRecording()
                            } else {
                                startHotkeyRecording()
                            }
                        }) {
                            Text(isRecordingHotkey ? "Press keys..." : settingsManager.getHotkeyDisplayString())
                                .foregroundColor(isRecordingHotkey ? .orange : .secondary)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if isRecordingHotkey {
                        Text("Press the desired key combination")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Section("App Settings") {
                    Toggle("Enable App", isOn: $isEnabled)
                    
                    Toggle("Show Notifications", isOn: $showNotifications)
                }
                
                Section("Status") {
                    HStack {
                        Text("Status")
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isEnabled ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(isEnabled ? "Active" : "Inactive")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Microphone")
                        Spacer()
                        Text("Granted")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Project Folder")
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: projectFolderStatus.icon)
                                .foregroundColor(projectFolderStatus.color)
                                .help(projectFolderStatus.tooltip)
                            if folderAccessManager.hasProjectFolderAccess {
                                Button("Change") {
                                    folderAccessManager.requestProjectFolderAccess()
                                }
                                .controlSize(.small)
                                .buttonStyle(.plain)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                            } else {
                                Button("Select") {
                                    folderAccessManager.requestProjectFolderAccess()
                                }
                                .controlSize(.small)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .cornerRadius(4)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Server URL")
                        Spacer()
                        Text(settingsManager.getServerURL())
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .formStyle(GroupedFormStyle())
            
            // Footer
            VStack(spacing: 8) {
                Text("Press \(settingsManager.getHotkeyDisplayString()) to start recording")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Recording will automatically stop when you release the hotkey")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 700)
        .padding()
        .onAppear {
            settingsManager.loadSettings()
        }
        .onDisappear {
            stopHotkeyRecording()
        }
    }
    
    // MARK: - Hotkey Recording Methods
    private func startHotkeyRecording() {
        isRecordingHotkey = true
        
        // Set up local key monitor for capturing hotkeys
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            guard isRecordingHotkey else { return event }
            
            // Capture the key combination
            let keyCode = Int(event.keyCode)
            var modifiers: [String] = []
            
            if event.modifierFlags.contains(.command) { modifiers.append("command") }
            if event.modifierFlags.contains(.shift) { modifiers.append("shift") }
            if event.modifierFlags.contains(.option) { modifiers.append("option") }
            if event.modifierFlags.contains(.control) { modifiers.append("control") }
            
            // Update settings using the new method
            let success = settingsManager.updateHotkey(keyCode: keyCode, modifiers: modifiers)
            if success {
                // Stop recording
                stopHotkeyRecording()
                
                // Notify parent of settings change
                onSettingsChanged?()
            }
            
            return nil // Swallow the keystroke
        }
    }
    
    private func stopHotkeyRecording() {
        isRecordingHotkey = false
        
        // Remove the key monitor
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }
    
    private var modelSizeDescription: String {
        switch settingsManager.whisperModel {
        case "tiny":
            return "Fastest, least accurate (~39 MB)"
        case "base":
            return "Good balance (~74 MB)"
        case "small":
            return "Better accuracy (~244 MB)"
        case "medium":
            return "High accuracy (~769 MB)"
        case "large":
            return "Best accuracy, slowest (~1550 MB)"
        default:
            return "Good balance"
        }
    }
    
    private func languageDisplayName(_ code: String) -> String {
        switch code {
        case "en": return "English"
        case "es": return "Spanish"
        case "fr": return "French"
        case "de": return "German"
        case "it": return "Italian"
        case "pt": return "Portuguese"
        case "ru": return "Russian"
        case "ja": return "Japanese"
        case "zh": return "Chinese"
        default: return code.uppercased()
        }
    }
    
    private var projectFolderStatus: (icon: String, color: Color, tooltip: String) {
        // Check all three conditions
        if !folderAccessManager.hasProjectFolderAccess {
            return ("folder.badge.questionmark", .orange, "Select a project folder to enable transcription")
        }
        
        let validation = folderAccessManager.validatePythonPaths(
            pythonPath: settingsManager.pythonPath,
            scriptPath: settingsManager.scriptPath
        )
        
        if validation.pythonExists && validation.scriptExists {
            return ("checkmark.circle.fill", .green, "Project folder configured with valid Python executable and server script")
        } else {
            let issues = [
                validation.pythonExists ? nil : "Python executable not found",
                validation.scriptExists ? nil : "Server script not found"
            ].compactMap { $0 }.joined(separator: ", ")
            return ("xmark.circle.fill", .red, "Configuration issues found: \(issues)")
        }
    }
}

#Preview {
    SettingsView()
} 