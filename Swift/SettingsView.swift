import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var folderAccessManager = FolderAccessManager()
    @StateObject private var permissionManager = PermissionManager()
    @State private var isEnabled = true
    @State private var showNotifications = true
    @State private var isRecordingHotkey = false
    @State private var showingPythonPathHelp = false
    
    var onSettingsChanged: (() -> Void)?
    var onBack: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
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
                    .onChange(of: settingsManager.whisperModel) { _ in
                        settingsManager.saveSettings()
                        settingsManager.refreshWhisperConfiguration()
                        onSettingsChanged?()
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
                    .onChange(of: settingsManager.whisperLanguage) { _ in
                        settingsManager.saveSettings()
                        settingsManager.refreshWhisperConfiguration()
                        onSettingsChanged?()
                    }
                    
                    Picker("Task", selection: $settingsManager.whisperTask) {
                        ForEach(settingsManager.availableTasks, id: \.self) { task in
                            Text(task.capitalized)
                                .tag(task)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: settingsManager.whisperTask) { _ in
                        settingsManager.saveSettings()
                        settingsManager.refreshWhisperConfiguration()
                        onSettingsChanged?()
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
                    .onChange(of: settingsManager.whisperTemperature) { _ in
                        settingsManager.saveSettings()
                        settingsManager.refreshWhisperConfiguration()
                        onSettingsChanged?()
                    }
                }
                
                Section("Hotkey Configuration") {
                    HStack {
                        Text("Global Hotkey")
                        Spacer()
                        Button(action: {
                            isRecordingHotkey.toggle()
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
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NSEventKeyDown"))) { notification in
                    guard isRecordingHotkey, let event = notification.object as? NSEvent else { return }
                    
                    // Capture the key combination
                    let keyCode = Int(event.keyCode)
                    var modifiers: [String] = []
                    
                    if event.modifierFlags.contains(.command) { modifiers.append("command") }
                    if event.modifierFlags.contains(.shift) { modifiers.append("shift") }
                    if event.modifierFlags.contains(.option) { modifiers.append("option") }
                    if event.modifierFlags.contains(.control) { modifiers.append("control") }
                    
                    // Update settings
                    settingsManager.updateHotkey(keyCode: keyCode, modifiers: modifiers)
                    settingsManager.saveSettings()
                    settingsManager.refreshHotkeyConfiguration()
                    
                    // Stop recording
                    isRecordingHotkey = false
                    
                    // Notify parent of settings change
                    onSettingsChanged?()
                }
                
                Section("App Settings") {
                    Toggle("Enable App", isOn: $isEnabled)
                    
                    Toggle("Show Notifications", isOn: $showNotifications)
                }
                
                Section("Permissions") {
                    // Microphone Permission
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Microphone")
                                .font(.body)
                            Text("Required for speech recording")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Image(systemName: permissionManager.microphonePermissionStatus.icon)
                                .foregroundColor(Color(permissionManager.microphonePermissionStatus.color))
                            
                            Text(permissionManager.microphonePermissionStatus.displayText)
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            Button(permissionManager.getActionText(for: .microphone)) {
                                if permissionManager.microphonePermissionStatus == .notDetermined {
                                    Task {
                                        await permissionManager.requestMicrophonePermission()
                                    }
                                } else {
                                    permissionManager.openSystemPreferences(for: .microphone)
                                }
                            }
                            .controlSize(.small)
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    // Accessibility Permission
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility")
                                .font(.body)
                            Text("Required for global hotkeys and paste-at-cursor")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Image(systemName: permissionManager.accessibilityPermissionStatus.icon)
                                .foregroundColor(Color(permissionManager.accessibilityPermissionStatus.color))
                            
                            Text(permissionManager.accessibilityPermissionStatus.displayText)
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            Button(permissionManager.getActionText(for: .accessibility)) {
                                if permissionManager.accessibilityPermissionStatus != .authorized {
                                    permissionManager.requestAccessibilityPermission()
                                } else {
                                    permissionManager.openSystemPreferences(for: .accessibility)
                                }
                            }
                            .controlSize(.small)
                            .buttonStyle(.bordered)
                        }
                    }
                    

                }
                
                Section("Project Configuration") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Project Folder")
                                .font(.body)
                            Text(folderAccessManager.hasProjectFolderAccess ? 
                                 folderAccessManager.projectFolderPath : "No folder selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Image(systemName: projectFolderStatus.icon)
                                .foregroundColor(projectFolderStatus.color)
                                .help(projectFolderStatus.tooltip)
                            
                            Button(folderAccessManager.hasProjectFolderAccess ? "Change" : "Select") {
                                folderAccessManager.requestProjectFolderAccess()
                                // Auto-detect and update Python settings after folder selection
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    autoDetectAndUpdatePython()
                                }
                            }
                            .controlSize(.small)
                            .buttonStyle(.bordered)
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
                
                Text("Transcribed text will be automatically pasted at cursor")
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
            permissionManager.checkAllPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Refresh permissions when app becomes active (user might have changed them in System Preferences)
            permissionManager.checkAllPermissions()
        }
        .sheet(isPresented: $showingPythonPathHelp) {
            pythonPathHelpSheet
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
    
    // MARK: - Helper Methods
    private func autoDetectAndUpdatePython() {
        guard folderAccessManager.hasProjectFolderAccess else { return }
        
        if let detectedPath = folderAccessManager.findPythonInterpreter() {
            settingsManager.pythonPath = detectedPath
            settingsManager.saveSettings()
            onSettingsChanged?()
        }
    }
    

    

    
    private var projectFolderStatus: (icon: String, color: Color, tooltip: String) {
        if !folderAccessManager.hasProjectFolderAccess {
            return ("folder.badge.questionmark", .orange, "Select a project folder to enable transcription")
        }
        
        // Check if required files exist and auto-detect Python
        let structureValidation = folderAccessManager.validateProjectStructure()
        guard structureValidation.isValid else {
            return ("xmark.circle.fill", .red, "Missing required files: \(structureValidation.missingFiles.joined(separator: ", "))")
        }
        
        // Check if Python interpreter can be found
        if folderAccessManager.findPythonInterpreter() != nil {
            return ("checkmark.circle.fill", .green, "Project folder ready with Python environment and server script")
        } else {
            return ("exclamationmark.triangle.fill", .orange, "Project structure valid but Python interpreter not found in expected locations")
        }
    }
    
    private var pythonPathHelpSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Python Environment Setup")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Close") {
                    showingPythonPathHelp = false
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("The app looks for Python in these locations (in order):")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Python/.venv/bin/python3")
                    Text("• .venv/bin/python3")
                    Text("• venv/bin/python3")
                    Text("• Python/venv/bin/python3")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
                
                Text("To set up a Python virtual environment:")
                    .font(.headline)
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("1. cd to your project folder")
                    Text("2. python3 -m venv Python/.venv")
                    Text("3. source Python/.venv/bin/activate")
                    Text("4. pip install -r Python/requirements.txt")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
                
                Text("Required project structure:")
                    .font(.headline)
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Python/transcription_server.py")
                    Text("• Config/settings.yaml")
                    Text("• Python/.venv/bin/python3")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 450, height: 400)
    }
}

#Preview {
    SettingsView()
} 