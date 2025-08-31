import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var hotkeyRecorder = HotkeyRecorder()
    @State private var isReloadingModel = false
    
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
                        .onChange(of: settingsManager.whisperModel) { newValue in
                            settingsManager.updateWhisperSettings(
                                model: newValue,
                                language: settingsManager.whisperLanguage,
                                task: settingsManager.whisperTask,
                                temperature: settingsManager.whisperTemperature
                            )
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
                        .onChange(of: settingsManager.whisperLanguage) { newValue in
                            settingsManager.updateWhisperSettings(
                                model: settingsManager.whisperModel,
                                language: newValue,
                                task: settingsManager.whisperTask,
                                temperature: settingsManager.whisperTemperature
                            )
                            onSettingsChanged?()
                        }
                    }
                    
                    HStack {
                        Text("Task:")
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .leading)
                            .font(.system(size: 14))
                        
                        Picker("Task", selection: $settingsManager.whisperTask) {
                            ForEach(settingsManager.availableTasks, id: \.self) { task in
                                Text(task.capitalized)
                                    .tag(task)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settingsManager.whisperTask) { newValue in
                            settingsManager.updateWhisperSettings(
                                model: settingsManager.whisperModel,
                                language: settingsManager.whisperLanguage,
                                task: newValue,
                                temperature: settingsManager.whisperTemperature
                            )
                            onSettingsChanged?()
                        }
                    }
                    
                    HStack {
                        Text("Temperature:")
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .leading)
                            .font(.system(size: 14))
                        
                        Slider(value: $settingsManager.whisperTemperature, in: 0.0...1.0, step: 0.1)
                            .onChange(of: settingsManager.whisperTemperature) { newValue in
                                settingsManager.updateWhisperSettings(
                                    model: settingsManager.whisperModel,
                                    language: settingsManager.whisperLanguage,
                                    task: settingsManager.whisperTask,
                                    temperature: newValue
                                )
                                onSettingsChanged?()
                            }
                        
                        Text(String(format: "%.1f", settingsManager.whisperTemperature))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 30)
                    }
                    
                    HStack {
                        Text("")
                            .frame(width: 70, alignment: .leading)
                        
                        Button("Reset to Defaults") {
                            settingsManager.updateWhisperSettings(
                                model: "small",
                                language: "en",
                                task: "transcribe",
                                temperature: 0.0
                            )
                            onSettingsChanged?()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                        
                        Button(isReloadingModel ? "Reloading..." : "Reload Model") {
                            isReloadingModel = true
                            settingsManager.manuallyReloadWhisperModel()
                            onSettingsChanged?()
                            
                            // Reset loading state after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                isReloadingModel = false
                            }
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(isReloadingModel ? .secondary : .blue)
                        .font(.system(size: 12))
                        .disabled(isReloadingModel)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Divider()
            
            // Server Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("Server Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 10) {
                    HStack {
                        Text("Host:")
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .leading)
                            .font(.system(size: 14))
                        
                        TextField("localhost", text: $settingsManager.serverHost)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: settingsManager.serverHost) { newValue in
                                settingsManager.updateServerSettings(
                                    host: newValue,
                                    port: settingsManager.serverPort,
                                    pythonPath: settingsManager.pythonPath,
                                    scriptPath: settingsManager.scriptPath
                                )
                                onSettingsChanged?()
                            }
                    }
                    
                    HStack {
                        Text("Port:")
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .leading)
                            .font(.system(size: 14))
                        
                        TextField("Port", value: $settingsManager.serverPort, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: settingsManager.serverPort) { newValue in
                                settingsManager.updateServerSettings(
                                    host: settingsManager.serverHost,
                                    port: newValue,
                                    pythonPath: settingsManager.pythonPath,
                                    scriptPath: settingsManager.scriptPath
                                )
                                onSettingsChanged?()
                            }
                    }
                    
                    HStack {
                        Text("")
                            .frame(width: 70, alignment: .leading)
                        
                        Button("Reset to Defaults") {
                            settingsManager.updateServerSettings(
                                host: "localhost",
                                port: 3001,
                                pythonPath: "Python/.venv/bin/python3",
                                scriptPath: "Python/transcription_server.py"
                            )
                            onSettingsChanged?()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Divider()
            
            // LLM Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("LLM Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 10) {
                    HStack {
                        Text("Enabled:")
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .leading)
                            .font(.system(size: 14))
                        
                        Toggle("", isOn: $settingsManager.llmEnabled)
                            .onChange(of: settingsManager.llmEnabled) { newValue in
                                settingsManager.updateLLMSettings(
                                    baseUrl: settingsManager.llmBaseUrl,
                                    enabled: newValue,
                                    model: settingsManager.llmModel,
                                    temperature: settingsManager.llmTemperature,
                                    maxTokens: settingsManager.llmMaxTokens,
                                    prompt: settingsManager.llmPrompt
                                )
                                onSettingsChanged?()
                            }
                        
                        Spacer()
                    }
                    
                    if settingsManager.llmEnabled {
                        HStack {
                            Text("Base URL:")
                                .foregroundColor(.secondary)
                                .frame(width: 70, alignment: .leading)
                                .font(.system(size: 14))
                            
                            TextField("http://localhost:11434", text: $settingsManager.llmBaseUrl)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: settingsManager.llmBaseUrl) { newValue in
                                    settingsManager.updateLLMSettings(
                                        baseUrl: newValue,
                                        enabled: settingsManager.llmEnabled,
                                        model: settingsManager.llmModel,
                                        temperature: settingsManager.llmTemperature,
                                        maxTokens: settingsManager.llmMaxTokens,
                                        prompt: settingsManager.llmPrompt
                                    )
                                    onSettingsChanged?()
                                }
                        }
                        
                        HStack {
                            Text("Model:")
                                .foregroundColor(.secondary)
                                .frame(width: 70, alignment: .leading)
                                .font(.system(size: 14))
                            
                            TextField("llama3.1", text: $settingsManager.llmModel)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: settingsManager.llmModel) { newValue in
                                    settingsManager.updateLLMSettings(
                                        baseUrl: settingsManager.llmBaseUrl,
                                        enabled: settingsManager.llmEnabled,
                                        model: newValue,
                                        temperature: settingsManager.llmTemperature,
                                        maxTokens: settingsManager.llmMaxTokens,
                                        prompt: settingsManager.llmPrompt
                                    )
                                    onSettingsChanged?()
                                }
                        }
                        
                        HStack {
                            Text("")
                                .frame(width: 70, alignment: .leading)
                            
                            Button("Reset to Defaults") {
                                settingsManager.updateLLMSettings(
                                    baseUrl: "http://localhost:11434",
                                    enabled: true,
                                    model: "llama3.1",
                                    temperature: 0.1,
                                    maxTokens: 100,
                                    prompt: nil
                                )
                                onSettingsChanged?()
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Divider()
            
            // Logging Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("Logging Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 10) {
                    HStack {
                        Text("Enabled:")
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .leading)
                            .font(.system(size: 14))
                        
                        Toggle("", isOn: $settingsManager.loggingEnabled)
                            .onChange(of: settingsManager.loggingEnabled) { newValue in
                                settingsManager.updateLoggingSettings(
                                    enabled: newValue,
                                    logFile: settingsManager.loggingLogFile,
                                    maxFileSize: settingsManager.loggingMaxFileSize,
                                    backupCount: settingsManager.loggingBackupCount
                                )
                                onSettingsChanged?()
                            }
                        
                        Spacer()
                    }
                    
                    if settingsManager.loggingEnabled {
                        HStack {
                            Text("Log File:")
                                .foregroundColor(.secondary)
                                .frame(width: 70, alignment: .leading)
                                .font(.system(size: 14))
                            
                            TextField("Logs/transcriptions.log", text: $settingsManager.loggingLogFile)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: settingsManager.loggingLogFile) { newValue in
                                    settingsManager.updateLoggingSettings(
                                        enabled: settingsManager.loggingEnabled,
                                        logFile: newValue,
                                        maxFileSize: settingsManager.loggingMaxFileSize,
                                        backupCount: settingsManager.loggingBackupCount
                                    )
                                    onSettingsChanged?()
                                }
                        }
                        
                        HStack {
                            Text("")
                                .frame(width: 70, alignment: .leading)
                            
                            Button("Reset to Defaults") {
                                settingsManager.updateLoggingSettings(
                                    enabled: true,
                                    logFile: "Logs/transcriptions.log",
                                    maxFileSize: "10MB",
                                    backupCount: 5
                                )
                                onSettingsChanged?()
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                            
                            Spacer()
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
                
                VStack(spacing: 10) {
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
                        
                        Button(hotkeyRecorder.isRecording ? "Recording..." : "Change") {
                            if hotkeyRecorder.isRecording {
                                hotkeyRecorder.stopRecording()
                            } else {
                                hotkeyRecorder.startRecording()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(hotkeyRecorder.isRecording)
                    }
                    
                    if hotkeyRecorder.isRecording {
                        HStack {
                            Text("Press:")
                                .foregroundColor(.secondary)
                                .frame(width: 70, alignment: .leading)
                                .font(.system(size: 14))
                            
                            Text(hotkeyRecorder.displayString)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            
                            Spacer()
                            
                            Button("Cancel") {
                                hotkeyRecorder.stopRecording()
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.red)
                        }
                        
                        HStack {
                            Text("")
                                .frame(width: 70, alignment: .leading)
                            
                            Text("Press any key combination to set the new hotkey")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                    
                    if !hotkeyRecorder.isRecording && (hotkeyRecorder.currentKeyCode != 0 || !hotkeyRecorder.currentModifiers.isEmpty) {
                        HStack {
                            Text("New:")
                                .foregroundColor(.secondary)
                                .frame(width: 70, alignment: .leading)
                                .font(.system(size: 14))
                            
                            Text(hotkeyRecorder.displayString)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(6)
                            
                            Spacer()
                            
                            Button("Apply") {
                                let (keyCode, modifiers) = hotkeyRecorder.getHotkeyConfiguration()
                                settingsManager.updateHotkeySettings(keyCode: keyCode, modifiers: modifiers)
                                onSettingsChanged?()
                                
                                // Reset recorder
                                hotkeyRecorder.resetToDefaults()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Cancel") {
                                hotkeyRecorder.resetToDefaults()
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    
                    HStack {
                        Text("")
                            .frame(width: 70, alignment: .leading)
                        
                        Button("Reset to Defaults") {
                            settingsManager.updateHotkeySettings(keyCode: 37, modifiers: ["option"])
                            onSettingsChanged?()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                        
                        Spacer()
                    }
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
