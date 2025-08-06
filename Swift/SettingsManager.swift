import Foundation
import SwiftUI

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
    @Published var serverPort: Int = 8080
    @Published var pythonPath: String = "Python/.venv/bin/python3"  // Relative to project folder
    @Published var scriptPath: String = "Python/transcription_server.py"  // Relative to project folder
    
    // MARK: - Properties
    private let configFileURL: URL
    private let logger = Logger()
    
    // Available options
    let availableModels = ["tiny", "base", "small", "medium", "large"]
    let availableLanguages = ["en", "es", "fr", "de", "it", "pt", "ru", "ja", "zh"]
    let availableTasks = ["transcribe", "translate"]
    
    // MARK: - Initialization
    init() {
        // Simple: try bundle first, fallback to documents for user customization
        if let bundleURL = Bundle.main.url(forResource: "settings", withExtension: "yaml") {
            configFileURL = bundleURL
        } else {
            // Fallback to documents directory for user customization
            configFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .first!.appendingPathComponent("speech-to-text-settings.yaml")
        }
        
        loadSettings()
    }
    
    // MARK: - Public Methods
    func loadSettings() {
        logger.log("Loading settings from: \(configFileURL.path)", level: .debug)
        
        do {
            let data = try Data(contentsOf: configFileURL)
            if let yamlString = String(data: data, encoding: .utf8) {
                parseYAMLSettings(yamlString)
            }
        } catch {
            logger.logError(error, context: "Failed to load settings")
            setDefaultSettings()
        }
    }
    
    func saveSettings() {
        logger.log("Saving settings to: \(configFileURL.path)", level: .debug)
        
        let yamlContent = generateYAMLContent()
        
        do {
            // Ensure directory exists
            let configDir = configFileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            
            try yamlContent.write(to: configFileURL, atomically: true, encoding: .utf8)
            logger.log("Settings saved successfully", level: .info)
        } catch {
            logger.logError(error, context: "Failed to save settings")
        }
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
    
    func updateHotkey(keyCode: Int, modifiers: [String]) {
        hotkeyKeyCode = keyCode
        hotkeyModifiers = modifiers
        saveSettings()
        logger.log("Hotkey updated to: \(getHotkeyDisplayString())", level: .info)
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
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Whisper settings
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
            // Hotkey settings
            else if trimmed.hasPrefix("key_code:") {
                if let keyStr = extractValue(from: trimmed),
                   let key = Int(keyStr) {
                    hotkeyKeyCode = key
                }
            }
            // Server settings
            else if trimmed.hasPrefix("host:") {
                serverHost = extractValue(from: trimmed) ?? serverHost
            } else if trimmed.hasPrefix("port:") {
                if let portStr = extractValue(from: trimmed),
                   let port = Int(portStr) {
                    serverPort = port
                }
            } else if trimmed.hasPrefix("python_path:") {
                pythonPath = extractValue(from: trimmed) ?? pythonPath
            } else if trimmed.hasPrefix("script_path:") {
                scriptPath = extractValue(from: trimmed) ?? scriptPath
            }
        }
    }
    
    private func extractValue(from line: String) -> String? {
        let components = line.components(separatedBy: ":")
        guard components.count >= 2 else { return nil }
        
        let value = components[1].trimmingCharacters(in: .whitespaces)
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
    
    private func setDefaultSettings() {
        whisperModel = "small"
        whisperLanguage = "en"
        whisperTask = "transcribe"
        whisperTemperature = 0.0
        hotkeyKeyCode = 37  // L key
        hotkeyModifiers = ["option"]
        serverHost = "localhost"
        serverPort = 8080
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

        # Server Settings
        server:
          host: "\(serverHost)"
          port: \(serverPort)
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
}