import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var folderAccessManager = FolderAccessManager()
    @State private var isEnabled = true
    @State private var showNotifications = true
    @State private var isRecordingHotkey = false
    
    var onSettingsChanged: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
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
            .padding(.top, 20)
            
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
                
                Section("Project Folder") {
                    VStack(alignment: .leading, spacing: 8) {
                        if folderAccessManager.hasProjectFolderAccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Project Folder Selected")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    Text(folderAccessManager.projectFolderPath)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            
                            Button("Change Folder") {
                                folderAccessManager.requestProjectFolderAccess()
                            }
                            .buttonStyle(.bordered)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Select Project Folder")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                }
                                
                                Text("Choose the folder containing your Python transcription server to enable secure access.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button("Select Folder") {
                                    folderAccessManager.requestProjectFolderAccess()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
                
                Section("Server Configuration") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Python Path")
                            .font(.headline)
                        TextField("Python/.venv/bin/python3", text: $settingsManager.pythonPath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!folderAccessManager.hasProjectFolderAccess)
                            .onChange(of: settingsManager.pythonPath) { _ in
                                settingsManager.saveSettings()
                                onSettingsChanged?()
                            }
                        Text("Relative path to Python executable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Script Path")
                            .font(.headline)
                        TextField("Python/transcription_server.py", text: $settingsManager.scriptPath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(!folderAccessManager.hasProjectFolderAccess)
                            .onChange(of: settingsManager.scriptPath) { _ in
                                settingsManager.saveSettings()
                                onSettingsChanged?()
                            }
                        Text("Relative path to transcription server script")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if folderAccessManager.hasProjectFolderAccess {
                        let validation = folderAccessManager.validatePythonPaths(
                            pythonPath: settingsManager.pythonPath,
                            scriptPath: settingsManager.scriptPath
                        )
                        
                        HStack {
                            Image(systemName: validation.pythonExists ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(validation.pythonExists ? .green : .red)
                            Text("Python executable")
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: validation.scriptExists ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(validation.scriptExists ? .green : .red)
                            Text("Server script")
                            Spacer()
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
}

#Preview {
    SettingsView()
} 