import Foundation
import SwiftUI

// MARK: - Update Type Enum
enum SettingsUpdateType {
    case immediate      // No restart needed (hotkeys, UI preferences)
    case serverRestart  // Python server needs restart (model changes, server config)
    case appRestart     // Full app restart needed (permissions, entitlements)
}

// MARK: - Setting Metadata
struct SettingMetadata {
    let keyPath: String
    let updateType: SettingsUpdateType
    let requiresValidation: Bool
    let validationRule: ((Any) -> Bool)?
}

// Configuration models matching settings.yaml structure
struct STTProviderConfig: Codable {
    let provider: String
}

struct ServerConfig: Codable {
    var host: String
    var port: Int
    var pythonPath: String
    var scriptPath: String
}

struct WhisperConfig: Codable {
    var model: String
    var language: String
    var task: String
    var temperature: Double
}

struct HotkeyConfig: Codable {
    var keyCode: Int
    var modifiers: [String]
}

struct AppConfig: Codable {
    var stt: STTProviderConfig
    var server: ServerConfig
    var whisper: WhisperConfig
    var hotkey: HotkeyConfig
}

class SettingsManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var whisperModel: String = "small"
    @Published var whisperLanguage: String = "en"
    @Published var whisperTask: String = "transcribe"
    @Published var whisperTemperature: Double = 0.0
    @Published var hotkeyKeyCode: Int = 37  // L key
    @Published var hotkeyModifiers: [String] = ["option"]
    @Published var serverHost: String = "localhost"
    @Published var serverPort: Int = 3001
    @Published var pythonPath: String = "Python/.venv/bin/python3"  // Relative to project folder
    @Published var scriptPath: String = "Python/transcription_server.py"  // Relative to project folder
    
    // MARK: - Properties
    private let configFileURL: URL
    private let logger = Logger()
    private let folderAccessManager: FolderAccessManager
    
    // Settings metadata for update categorization
    private let settingsMetadata: [String: SettingMetadata] = [
        "whisperModel": SettingMetadata(
            keyPath: "whisperModel",
            updateType: .serverRestart,
            requiresValidation: true,
            validationRule: { value in
                guard let model = value as? String else { return false }
                return ["tiny", "base", "small", "medium", "large"].contains(model)
            }
        ),
        "whisperLanguage": SettingMetadata(
            keyPath: "whisperLanguage",
            updateType: .serverRestart,
            requiresValidation: true,
            validationRule: { value in
                guard let language = value as? String else { return false }
                return ["en", "es", "fr", "de", "it", "pt", "ru", "ja", "zh"].contains(language)
            }
        ),
        "whisperTask": SettingMetadata(
            keyPath: "whisperTask",
            updateType: .serverRestart,
            requiresValidation: true,
            validationRule: { value in
                guard let task = value as? String else { return false }
                return ["transcribe", "translate"].contains(task)
            }
        ),
        "whisperTemperature": SettingMetadata(
            keyPath: "whisperTemperature",
            updateType: .serverRestart,
            requiresValidation: true,
            validationRule: { value in
                guard let temp = value as? Double else { return false }
                return temp >= 0.0 && temp <= 1.0
            }
        ),
        "hotkeyKeyCode": SettingMetadata(
            keyPath: "hotkeyKeyCode",
            updateType: .immediate,
            requiresValidation: true,
            validationRule: { value in
                guard let keyCode = value as? Int else { return false }
                return keyCode >= 0 && keyCode <= 127
            }
        ),
        "hotkeyModifiers": SettingMetadata(
            keyPath: "hotkeyModifiers",
            updateType: .immediate,
            requiresValidation: true,
            validationRule: { value in
                guard let modifiers = value as? [String] else { return false }
                let validModifiers = ["command", "shift", "option", "control"]
                return !modifiers.isEmpty && modifiers.allSatisfy { validModifiers.contains($0) }
            }
        ),
        "serverHost": SettingMetadata(
            keyPath: "serverHost",
            updateType: .serverRestart,
            requiresValidation: true,
            validationRule: { value in
                guard let host = value as? String else { return false }
                return !host.isEmpty
            }
        ),
        "serverPort": SettingMetadata(
            keyPath: "serverPort",
            updateType: .serverRestart,
            requiresValidation: true,
            validationRule: { value in
                guard let port = value as? Int else { return false }
                return port > 0 && port <= 65535
            }
        ),
        "pythonPath": SettingMetadata(
            keyPath: "pythonPath",
            updateType: .serverRestart,
            requiresValidation: true,
            validationRule: { value in
                guard let path = value as? String else { return false }
                return !path.isEmpty
            }
        ),
        "scriptPath": SettingMetadata(
            keyPath: "scriptPath",
            updateType: .serverRestart,
            requiresValidation: true,
            validationRule: { value in
                guard let path = value as? String else { return false }
                return !path.isEmpty
            }
        )
    ]
    
    // Available options
    let availableModels = ["tiny", "base", "small", "medium", "large"]
    let availableLanguages = ["en", "es", "fr", "de", "it", "pt", "ru", "ja", "zh"]
    let availableTasks = ["transcribe", "translate"]
    
    // MARK: - Initialization
    init(folderAccessManager: FolderAccessManager? = nil) {
        // Initialize folder access manager
        self.folderAccessManager = folderAccessManager ?? FolderAccessManager()
        
        // Use project folder for settings instead of documents directory
        if let projectFolder = self.folderAccessManager.getProjectFolderURL() {
            configFileURL = projectFolder.appendingPathComponent("Config/settings.yaml")
        } else {
            // Fallback to documents directory if no project folder
            configFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .first!.appendingPathComponent("speech-to-text-settings.yaml")
        }
        
        // Try to load from bundle first, then from project folder or documents
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Updates hotkey settings with immediate effect
    func updateHotkey(keyCode: Int, modifiers: [String]) -> Bool {
        // Validate hotkey settings
        guard keyCode >= 0 && keyCode <= 127 else {
            logger.log("Invalid hotkey key code: \(keyCode)", level: .error)
            return false
        }
        
        let validModifiers = ["command", "shift", "option", "control"]
        guard !modifiers.isEmpty && modifiers.allSatisfy({ validModifiers.contains($0) }) else {
            logger.log("Invalid hotkey modifiers: \(modifiers)", level: .error)
            return false
        }
        
        // Update the in-memory values immediately
        self.hotkeyKeyCode = keyCode
        self.hotkeyModifiers = modifiers
        
        // Save to YAML for persistence
        saveSettings()
        
        // Log the change
        logger.log("Hotkey updated to: \(getHotkeyDisplayString())", level: .info)
        
        // Hotkey changes are immediate, so refresh the configuration
        refreshHotkeyConfiguration()
        
        return true
    }
    
    /// Updates Whisper model setting (requires server restart)
    func updateWhisperModel(_ model: String) -> Bool {
        guard availableModels.contains(model) else {
            logger.log("Invalid Whisper model: \(model)", level: .error)
            return false
        }
        
        // Update the in-memory value immediately
        self.whisperModel = model
        
        // Save to YAML for persistence
        saveSettings()
        
        // Log the change
        logger.log("Whisper model updated to: \(model)", level: .info)
        
        // Whisper settings require server restart
        refreshWhisperConfiguration()
        
        return true
    }
    
    /// Updates Whisper language setting (requires server restart)
    func updateWhisperLanguage(_ language: String) -> Bool {
        guard availableLanguages.contains(language) else {
            logger.log("Invalid Whisper language: \(language)", level: .error)
            return false
        }
        
        // Update the in-memory value immediately
        self.whisperLanguage = language
        
        // Save to YAML for persistence
        saveSettings()
        
        // Log the change
        logger.log("Whisper language updated to: \(language)", level: .info)
        
        // Whisper settings require server restart
        refreshWhisperConfiguration()
        
        return true
    }
    
    /// Updates Whisper task setting (requires server restart)
    func updateWhisperTask(_ task: String) -> Bool {
        guard availableTasks.contains(task) else {
            logger.log("Invalid Whisper task: \(task)", level: .error)
            return false
        }
        
        // Update the in-memory value immediately
        self.whisperTask = task
        
        // Save to YAML for persistence
        saveSettings()
        
        // Log the change
        logger.log("Whisper task updated to: \(task)", level: .info)
        
        // Whisper settings require server restart
        refreshWhisperConfiguration()
        
        return true
    }
    
    /// Updates Whisper temperature setting (requires server restart)
    func updateWhisperTemperature(_ temperature: Double) -> Bool {
        guard temperature >= 0.0 && temperature <= 1.0 else {
            logger.log("Invalid Whisper temperature: \(temperature)", level: .error)
            return false
        }
        
        // Update the in-memory value immediately
        self.whisperTemperature = temperature
        
        // Save to YAML for persistence
        saveSettings()
        
        // Log the change
        logger.log("Whisper temperature updated to: \(temperature)", level: .info)
        
        // Whisper settings require server restart
        refreshWhisperConfiguration()
        
        return true
    }
    
    /// Updates server host setting (requires server restart)
    func updateServerHost(_ host: String) -> Bool {
        guard !host.isEmpty else {
            logger.log("Invalid server host: \(host)", level: .error)
            return false
        }
        
        // Update the in-memory value immediately
        self.serverHost = host
        
        // Save to YAML for persistence
        saveSettings()
        
        // Log the change
        logger.log("Server host updated to: \(host)", level: .info)
        
        // Server settings require server restart
        refreshServerConfiguration()
        
        return true
    }
    
    /// Updates server port setting (requires server restart)
    func updateServerPort(_ port: Int) -> Bool {
        guard port > 0 && port <= 65535 else {
            logger.log("Invalid server port: \(port)", level: .error)
            return false
        }
        
        // Update the in-memory value immediately
        self.serverPort = port
        
        // Save to YAML for persistence
        saveSettings()
        
        // Log the change
        logger.log("Server port updated to: \(port)", level: .info)
        
        // Server settings require server restart
        refreshServerConfiguration()
        
        return true
    }
    
    /// Updates Python path setting (requires server restart)
    func updatePythonPath(_ path: String) -> Bool {
        guard !path.isEmpty else {
            logger.log("Invalid Python path: \(path)", level: .error)
            return false
        }
        
        // Update the in-memory value immediately
        self.pythonPath = path
        
        // Save to YAML for persistence
        saveSettings()
        
        // Log the change
        logger.log("Python path updated to: \(path)", level: .info)
        
        // Server settings require server restart
        refreshServerConfiguration()
        
        return true
    }
    
    /// Updates script path setting (requires server restart)
    func updateScriptPath(_ path: String) -> Bool {
        guard !path.isEmpty else {
            logger.log("Invalid script path: \(path)", level: .error)
            return false
        }
        
        // Update the in-memory value immediately
        self.scriptPath = path
        
        // Save to YAML for persistence
        saveSettings()
        
        // Log the change
        logger.log("Script path updated to: \(path)", level: .info)
        
        // Server settings require server restart
        refreshServerConfiguration()
        
        return true
    }
    
    func loadSettings() {
        logger.log("Loading settings from: \(configFileURL.path)", level: .debug)
        
        // First try to load from bundle (default settings)
        if let bundleURL = Bundle.main.url(forResource: "settings", withExtension: "yaml") {
            do {
                let data = try Data(contentsOf: bundleURL)
                if let yamlString = String(data: data, encoding: .utf8) {
                    parseYAMLSettings(yamlString)
                    logger.log("Loaded default settings from bundle", level: .debug)
                }
            } catch {
                logger.logError(error, context: "Failed to load bundle settings")
            }
        }
        
        // Then try to load from project folder Config/settings.yaml
        if FileManager.default.fileExists(atPath: configFileURL.path) {
            do {
                let data = try Data(contentsOf: configFileURL)
                if let yamlString = String(data: data, encoding: .utf8) {
                    parseYAMLSettings(yamlString)
                    logger.log("Loaded user settings from project folder: \(configFileURL.path)", level: .debug)
                }
            } catch {
                logger.logError(error, context: "Failed to load project folder settings")
            }
        } else {
            logger.log("No settings file found at project folder path: \(configFileURL.path)", level: .debug)
        }
    }
    
    func saveSettings() {
        logger.log("Saving settings to: \(configFileURL.path)", level: .debug)
        
        let yamlContent = generateYAMLContent()
        
        do {
            // Ensure Config directory exists in project folder
            let configDir = configFileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            
            try yamlContent.write(to: configFileURL, atomically: true, encoding: .utf8)
            logger.log("Settings saved successfully to project folder: \(configFileURL.path)", level: .info)
        } catch {
            logger.logError(error, context: "Failed to save settings to project folder")
        }
    }
    
    func refreshHotkeyConfiguration() {
        // This method will be called when hotkey settings change
        // The HotkeyManager should listen for these changes and re-register the hotkey
        logger.log("Hotkey configuration refreshed", level: .info)
        
        // Post notification for HotkeyManager to pick up
        NotificationCenter.default.post(name: NSNotification.Name("HotkeySettingsChanged"), object: nil)
    }
    
    func refreshWhisperConfiguration() {
        // This method will be called when Whisper settings change
        // Instead of restarting the server, we'll reload the model via API
        logger.log("Whisper configuration refreshed, reloading model via API", level: .info)
        
        // Call the API to reload the model with new settings
        reloadWhisperModelViaAPI()
    }
    
    func refreshServerConfiguration() {
        // This method will be called when server settings change
        logger.log("Server configuration refreshed", level: .info)
        
        // Post notification for ServerManager to pick up
        NotificationCenter.default.post(name: NSNotification.Name("ServerSettingsChanged"), object: nil)
    }
    
    func getHotkeyDisplayString() -> String {
        var display = ""
        if hotkeyModifiers.contains("command") { display += "⌘" }
        if hotkeyModifiers.contains("shift") { display += "⇧" }
        if hotkeyModifiers.contains("option") { display += "⌥" }
        if hotkeyModifiers.contains("control") { display += "⌃" }
        
        // Convert keyCode to character (simplified mapping)
        let keyChar = keyCodeToCharacter(hotkeyKeyCode)
        display += keyChar
        
        return display
    }
    
    func getServerURL() -> String {
        return "http://\(serverHost):\(serverPort)"
    }
    
    func getFullPythonPath() -> String {
        // Use path as-is - can be absolute or relative to user's working directory
        return pythonPath
    }
    
    func getFullScriptPath() -> String {
        // Use path as-is - can be absolute or relative to user's working directory  
        return scriptPath
    }
    
    // MARK: - Private Methods
    private func parseYAMLSettings(_ yamlString: String) {
        let lines = yamlString.components(separatedBy: .newlines)
        
        enum Section {
            case none
            case stt
            case server
            case whisper
            case llm
            case hotkey
            case audio
            case logging
        }
        
        var currentSection: Section = .none
        
        for rawLine in lines {
            // Preserve indentation to detect top-level keys
            let line = rawLine
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            // Detect section headers (top-level keys end with ':')
            let leadingSpaces = line.prefix { $0 == " " }.count
            if leadingSpaces == 0 && trimmed.hasSuffix(":") {
                switch trimmed {
                case "stt:": currentSection = .stt
                case "server:": currentSection = .server
                case "whisper:": currentSection = .whisper
                case "llm:": currentSection = .llm
                case "hotkey:": currentSection = .hotkey
                case "audio:": currentSection = .audio
                case "logging:": currentSection = .logging
                default: currentSection = .none
                }
                continue
            }
            
            // Parse keys within their respective sections only
            switch currentSection {
            case .whisper:
                if trimmed.hasPrefix("model:") {
                    whisperModel = extractValue(from: trimmed) ?? whisperModel
                } else if trimmed.hasPrefix("language:") {
                    whisperLanguage = extractValue(from: trimmed) ?? whisperLanguage
                } else if trimmed.hasPrefix("task:") {
                    whisperTask = extractValue(from: trimmed) ?? whisperTask
                } else if trimmed.hasPrefix("temperature:") {
                    if let tempStr = extractValue(from: trimmed),
                       let temp = Double(tempStr) {
                        whisperTemperature = temp
                    }
                }
            case .server:
                if trimmed.hasPrefix("host:") {
                    serverHost = extractValue(from: trimmed) ?? serverHost
                } else if trimmed.hasPrefix("port:") {
                    if let portStr = extractValue(from: trimmed), let port = Int(portStr) {
                        serverPort = port
                    }
                } else if trimmed.hasPrefix("python_path:") {
                    pythonPath = extractValue(from: trimmed) ?? pythonPath
                } else if trimmed.hasPrefix("script_path:") {
                    scriptPath = extractValue(from: trimmed) ?? scriptPath
                }
            case .hotkey:
                if trimmed.hasPrefix("key_code:") {
                    if let keyStr = extractValue(from: trimmed), let key = Int(keyStr) {
                        hotkeyKeyCode = key
                    }
                } else if trimmed.hasPrefix("modifiers:") {
                    // Basic parsing for modifier list, e.g., modifiers: ["option"]
                    if let raw = extractValue(from: trimmed) {
                        let cleaned = raw.replacingOccurrences(of: "[", with: "")
                            .replacingOccurrences(of: "]", with: "")
                        let parts = cleaned.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
                        if !parts.isEmpty { hotkeyModifiers = parts }
                    }
                }
            default:
                // Ignore keys in other sections here
                break
            }
        }
    }
    
    private func extractValue(from line: String) -> String? {
        // Take the substring after the first ':'
        guard let colonIndex = line.firstIndex(of: ":") else { return nil }
        var value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
        // Strip inline comments
        if let hashIndex = value.firstIndex(of: "#") {
            value = String(value[..<hashIndex]).trimmingCharacters(in: .whitespaces)
        }
        // Strip surrounding quotes
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        return value.isEmpty ? nil : value
    }
    
    private func setDefaultSettings() {
        whisperModel = "small"
        whisperLanguage = "en"
        whisperTask = "transcribe"
        whisperTemperature = 0.0
        hotkeyKeyCode = 37  // L key
        hotkeyModifiers = ["option"]
        serverHost = "localhost"
        serverPort = 3001
        pythonPath = "Python/.venv/bin/python3"  // Relative to project folder
        scriptPath = "Python/transcription_server.py"  // Relative to project folder
        
        logger.log("Default settings applied", level: .info)
    }
    
    private func generateYAMLContent() -> String {
        return """
        # Speech-to-Text Application Configuration

        # Model Selection
        stt:
          provider: "whisper"

        # Server Settings (port is chosen dynamically at runtime)
        server:
          host: "\(serverHost)"
          python_path: "\(pythonPath)"
          script_path: "\(scriptPath)"

        # Audio Settings
        audio:
          sample_rate: 16000
          channels: 1
          format: wav
          chunk_duration: 3  # seconds

        # Whisper Settings
        whisper:
          model: "\(whisperModel)"
          language: "\(whisperLanguage)"
          task: "\(whisperTask)"
          temperature: \(whisperTemperature)

        # LLM Settings
        llm:
          base_url: "http://localhost:11434"
          enabled: true
          model: "llama3.1"
          temperature: 0.1
          max_tokens: 100
          prompt: null  # Use default prompt

        # Hotkey Settings
        hotkey:
          key_code: \(hotkeyKeyCode)
          modifiers: [\(hotkeyModifiers.map { "\"\($0)\"" }.joined(separator: ", "))]

        # Logging Settings
        logging:
          enabled: true
          log_file: "Logs/transcriptions.log"
          max_file_size: "10MB"
          backup_count: 5
        """
    }
    
    private func keyCodeToCharacter(_ keyCode: Int) -> String {
        // Simplified mapping for common keys
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 37: return "L"  // L key
        default: return "?"
        }
    }
    
    // MARK: - API Methods
    
    /// Reloads the Whisper model via API call instead of restarting the server
    private func reloadWhisperModelViaAPI() {
        guard let url = URL(string: "\(getServerURL())/reload_model") else {
            logger.log("Failed to create reload_model URL", level: .error)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send the new configuration
        let config: [String: Any] = [
            "model": whisperModel,
            "language": whisperLanguage,
            "task": whisperTask,
            "temperature": whisperTemperature
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: config)
        } catch {
            logger.log("Failed to serialize model config: \(error)", level: .error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.logger.log("Failed to reload model via API: \(error)", level: .error)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self?.logger.log("Whisper model reloaded successfully via API", level: .info)
                    } else {
                        self?.logger.log("Failed to reload model via API: HTTP \(httpResponse.statusCode)", level: .error)
                    }
                }
            }
        }.resume()
    }
}