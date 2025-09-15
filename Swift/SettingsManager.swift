import Foundation
import SwiftUI
import Yams

// MARK: - Configuration Models
struct STTProviderConfig: Codable {
    let provider: String
}

struct ServerConfig: Codable {
    var host: String
    var port: Int
    var uvPath: String
    var scriptPath: String
    
    enum CodingKeys: String, CodingKey {
        case host
        case port
        case uvPath = "uv_path"
        case scriptPath = "script_path"
    }
}

struct AudioConfig: Codable {
    var sampleRate: Int
    var channels: Int
    var format: String
    var chunkDuration: Int
    
    enum CodingKeys: String, CodingKey {
        case sampleRate = "sample_rate"
        case channels
        case format
        case chunkDuration = "chunk_duration"
    }
}

struct WhisperConfig: Codable {
    var model: String
    var language: String
    var task: String
    var temperature: Double
}

struct LLMConfig: Codable {
    var baseUrl: String
    var enabled: Bool
    var model: String
    var temperature: Double
    var maxTokens: Int
    var prompt: String?
    
    enum CodingKeys: String, CodingKey {
        case baseUrl = "base_url"
        case enabled
        case model
        case temperature
        case maxTokens = "max_tokens"
        case prompt
    }
}

struct HotkeyConfig: Codable {
    var keyCode: Int
    var modifiers: [String]
    
    enum CodingKeys: String, CodingKey {
        case keyCode = "key_code"
        case modifiers
    }
}

struct LoggingConfig: Codable {
    var enabled: Bool
    var logFile: String
    var maxFileSize: String
    var backupCount: Int
    
    enum CodingKeys: String, CodingKey {
        case enabled
        case logFile = "log_file"
        case maxFileSize = "max_file_size"
        case backupCount = "backup_count"
    }
}

struct AppConfig: Codable {
    var stt: STTProviderConfig
    var server: ServerConfig
    var audio: AudioConfig
    var whisper: WhisperConfig
    var llm: LLMConfig
    var hotkey: HotkeyConfig
    var logging: LoggingConfig
}

// MARK: - Settings Change Notifications
extension Notification.Name {
    static let whisperSettingsChanged = Notification.Name("whisperSettingsChanged")
    static let whisperModelReloaded = Notification.Name("whisperModelReloaded")
    static let hotkeySettingsChanged = Notification.Name("hotkeySettingsChanged")
    static let serverSettingsChanged = Notification.Name("serverSettingsChanged")
    static let audioSettingsChanged = Notification.Name("audioSettingsChanged")
    static let llmSettingsChanged = Notification.Name("llmSettingsChanged")
    static let loggingSettingsChanged = Notification.Name("loggingSettingsChanged")
}

// MARK: - Settings Manager
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
    @Published var uvPath: String = "/opt/homebrew/bin/uv"
    @Published var scriptPath: String = "transcription_server.py"  // Relative to stt-server-py folder
    
    @Published var audioSampleRate: Int = 16000
    @Published var audioChannels: Int = 1
    @Published var audioFormat: String = "wav"
    @Published var audioChunkDuration: Int = 3
    
    @Published var llmBaseUrl: String = "http://localhost:11434"
    @Published var llmEnabled: Bool = true
    @Published var llmModel: String = "llama3.1"
    @Published var llmTemperature: Double = 0.1
    @Published var llmMaxTokens: Int = 100
    @Published var llmPrompt: String? = nil
    
    @Published var loggingEnabled: Bool = true
    @Published var loggingLogFile: String = "transcriptions.log"
    @Published var loggingMaxFileSize: String = "10MB"
    @Published var loggingBackupCount: Int = 5
    
    // MARK: - Properties
    let configFileURL: URL
    private let logger = Logger()
    private var appConfig: AppConfig?
    
    // Available options
    let availableModels = ["tiny", "base", "small", "medium", "large"]
    let availableLanguages = ["en", "es", "fr", "de", "it", "pt", "ru", "ja", "zh"]
    let availableTasks = ["transcribe", "translate"]
    
    // MARK: - Initialization
    init() {
        // Always use Application Support for writable config
        // Default config is bundled, user config goes to Application Support
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("SpeechToTextApp")
        configFileURL = appSupportURL.appendingPathComponent("settings.yaml")
        logger.log("Using config file at: \(configFileURL.path)", level: .debug)
        
        // Load or create settings
        loadSettings()
    }

    
    // MARK: - Private Methods
    private func getBundledSettingsURL() -> URL? {
        guard let bundleResources = Bundle.main.resourceURL else {
            return nil
        }
        return bundleResources.appendingPathComponent("stt-server-py/settings.yaml")
    }
    
    // MARK: - Public Methods
    func loadSettings() {
        logger.log("Loading settings from: \(configFileURL.path)", level: .debug)
        
        // Check if settings file exists
        if FileManager.default.fileExists(atPath: configFileURL.path) {
            // Load existing settings
            do {
                let data = try Data(contentsOf: configFileURL)
                logger.log("Settings loaded, size: \(data.count) bytes", level: .debug)
                if let yamlString = String(data: data, encoding: .utf8) {
                    try parseYAMLSettings(yamlString)
                    logger.log("Loaded settings successfully", level: .debug)
                    logger.log("Whisper model: \(whisperModel)", level: .debug)
                } else {
                    logger.log("Failed to convert data to UTF-8 string", level: .error)
                    createDefaultSettings()
                }
            } catch {
                logger.logError(error, context: "Failed to load settings")
                createDefaultSettings()
            }
        } else {
            // Try to copy from bundled settings first
            if let bundledSettingsURL = getBundledSettingsURL() {
                do {
                    // Ensure the Application Support directory exists
                    try FileManager.default.createDirectory(at: configFileURL.deletingLastPathComponent(), 
                                                          withIntermediateDirectories: true, 
                                                          attributes: nil)
                    
                    // Copy bundled settings to writable location
                    try FileManager.default.copyItem(at: bundledSettingsURL, to: configFileURL)
                    logger.log("Copied bundled settings to: \(configFileURL.path)", level: .info)
                    
                    // Load the copied settings
                    let data = try Data(contentsOf: configFileURL)
                    if let yamlString = String(data: data, encoding: .utf8) {
                        try parseYAMLSettings(yamlString)
                        logger.log("Loaded settings from bundled copy", level: .info)
                        return
                    }
                } catch {
                    logger.log("Failed to copy bundled settings: \(error)", level: .warning)
                }
            }
            
            // Create default settings file if bundled copy failed
            logger.log("No settings file found, creating defaults", level: .debug)
            createDefaultSettings()
        }
    }


    private func createDefaultSettings() {
        logger.log("Creating default settings file", level: .info)
        
        // Set default values
        setDefaultSettings()
        
        // Save to file
        saveSettings()
    }
    
    func saveSettings() {
        logger.log("Saving settings to: \(configFileURL.path)", level: .debug)
        
        do {
            let yamlContent = try generateYAMLContent()
            
            // Ensure directory exists
            let configDir = configFileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            
            try yamlContent.write(to: configFileURL, atomically: true, encoding: .utf8)
            logger.log("Settings saved successfully", level: .info)
        } catch {
            logger.logError(error, context: "Failed to save settings")
        }
    }
    
    // MARK: - Settings Update Methods with Notifications
    
    func updateWhisperSettings(model: String, language: String, task: String, temperature: Double) {
        let oldModel = whisperModel
        let oldLanguage = whisperLanguage
        let oldTask = whisperTask
        let oldTemperature = whisperTemperature
        
        whisperModel = model
        whisperLanguage = language
        whisperTask = task
        whisperTemperature = temperature
        
        // Check if any critical settings changed that require model reload
        if oldModel != model || oldLanguage != language || oldTask != task {
            NotificationCenter.default.post(name: .whisperSettingsChanged, object: self)
            logger.log("Whisper settings changed - model reload required", level: .info)
        }
        
        // Persist user changes
        saveSettings()
    }
    
    func updateHotkeySettings(keyCode: Int, modifiers: [String]) {
        let oldKeyCode = hotkeyKeyCode
        let oldModifiers = hotkeyModifiers
        
        hotkeyKeyCode = keyCode
        hotkeyModifiers = modifiers
        
        // Always notify hotkey changes as they require immediate reload
        NotificationCenter.default.post(name: .hotkeySettingsChanged, object: self)
        logger.log("Hotkey settings changed - hotkey reload required", level: .info)
        
        // Persist user changes
        saveSettings()
    }
    
    func updateServerSettings(host: String, port: Int, uvPath: String, scriptPath: String) {
        let oldHost = serverHost
        let oldPort = serverPort
        let oldUvPath = self.uvPath
        let oldScriptPath = self.scriptPath
        
        serverHost = host
        serverPort = port
        self.uvPath = uvPath
        self.scriptPath = scriptPath
        
        // Check if critical server settings changed
        if oldHost != host || oldPort != port || oldUvPath != uvPath || oldScriptPath != scriptPath {
            NotificationCenter.default.post(name: .serverSettingsChanged, object: self)
            logger.log("Server settings changed - server restart required", level: .info)
        }
        
        // Persist user changes
        saveSettings()
    }
    
    func updateAudioSettings(sampleRate: Int, channels: Int, format: String, chunkDuration: Int) {
        audioSampleRate = sampleRate
        audioChannels = channels
        audioFormat = format
        audioChunkDuration = chunkDuration
        
        NotificationCenter.default.post(name: .audioSettingsChanged, object: self)
        logger.log("Audio settings changed", level: .info)
        
        // Persist user changes
        saveSettings()
    }
    
    func updateLLMSettings(baseUrl: String, enabled: Bool, model: String, temperature: Double, maxTokens: Int, prompt: String?) {
        llmBaseUrl = baseUrl
        llmEnabled = enabled
        llmModel = model
        llmTemperature = temperature
        llmMaxTokens = maxTokens
        llmPrompt = prompt
        
        NotificationCenter.default.post(name: .llmSettingsChanged, object: self)
        logger.log("LLM settings changed", level: .info)
        
        // Persist user changes
        saveSettings()
    }
    
    func updateLoggingSettings(enabled: Bool, logFile: String, maxFileSize: String, backupCount: Int) {
        loggingEnabled = enabled
        loggingLogFile = logFile
        loggingMaxFileSize = maxFileSize
        loggingBackupCount = backupCount
        
        NotificationCenter.default.post(name: .loggingSettingsChanged, object: self)
        logger.log("Logging settings changed", level: .info)
        
        // Persist user changes
        saveSettings()
    }
    
    func manuallyReloadWhisperModel() {
        // This method can be called from the UI to manually trigger a model reload
        NotificationCenter.default.post(name: .whisperSettingsChanged, object: self)
        logger.log("Manual Whisper model reload requested", level: .info)
    }
    
    // MARK: - Utility Methods
    
    func getHotkeyDisplayString() -> String {
        var display = ""
        if hotkeyModifiers.contains("command") { display += "⌘" }
        if hotkeyModifiers.contains("shift") { display += "⇧" }
        if hotkeyModifiers.contains("option") { display += "⌥" }
        if hotkeyModifiers.contains("control") { display += "⌃" }
        
        let keyChar = keyCodeToCharacter(hotkeyKeyCode)
        display += keyChar
        
        return display
    }
    
    func getServerURL() -> String {
        return "http://\(serverHost):\(serverPort)"
    }
    
    func getFullUvPath() -> String {
        return uvPath
    }
    
    func getFullScriptPath() -> String {
        return scriptPath
    }
    
    func languageDisplayName(_ code: String) -> String {
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
        default: return code.capitalized
        }
    }
    
    // MARK: - Private Methods
    
    private func parseYAMLSettings(_ yamlString: String) throws {
        do {
            let decoder = YAMLDecoder()
            let config = try decoder.decode(AppConfig.self, from: yamlString)
            self.appConfig = config
            
            // Update published properties
            updatePublishedProperties(from: config)
            
        } catch {
            logger.logError(error, context: "Failed to parse YAML settings")
            throw error
        }
    }
    
    private func updatePublishedProperties(from config: AppConfig) {
        // Whisper settings
        whisperModel = config.whisper.model
        whisperLanguage = config.whisper.language
        whisperTask = config.whisper.task
        whisperTemperature = config.whisper.temperature
        
        // Hotkey settings
        hotkeyKeyCode = config.hotkey.keyCode
        hotkeyModifiers = config.hotkey.modifiers
        
        // Server settings
        serverHost = config.server.host
        serverPort = config.server.port
        uvPath = config.server.uvPath
        scriptPath = config.server.scriptPath
        
        // Audio settings
        audioSampleRate = config.audio.sampleRate
        audioChannels = config.audio.channels
        audioFormat = config.audio.format
        audioChunkDuration = config.audio.chunkDuration
        
        // LLM settings
        llmBaseUrl = config.llm.baseUrl
        llmEnabled = config.llm.enabled
        llmModel = config.llm.model
        llmTemperature = config.llm.temperature
        llmMaxTokens = config.llm.maxTokens
        llmPrompt = config.llm.prompt
        
        // Logging settings
        loggingEnabled = config.logging.enabled
        loggingLogFile = config.logging.logFile
        loggingMaxFileSize = config.logging.maxFileSize
        loggingBackupCount = config.logging.backupCount
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
        uvPath = "/opt/homebrew/bin/uv"  // Full path to uv executable
        scriptPath = "transcription_server.py"  // Relative to stt-server-py folder
        
        audioSampleRate = 16000
        audioChannels = 1
        audioFormat = "wav"
        audioChunkDuration = 3
        
        llmBaseUrl = "http://localhost:11434"
        llmEnabled = true
        llmModel = "llama3.1"
        llmTemperature = 0.1
        llmMaxTokens = 100
        llmPrompt = nil
        
        loggingEnabled = true
        loggingLogFile = "transcriptions.log"
        loggingMaxFileSize = "10MB"
        loggingBackupCount = 5
        
        logger.log("Default settings applied", level: .info)
    }
    
    private func generateYAMLContent() throws -> String {
        let config = AppConfig(
            stt: STTProviderConfig(provider: "whisper"),
            server: ServerConfig(
                host: serverHost,
                port: serverPort,
                uvPath: uvPath,
                scriptPath: scriptPath
            ),
            audio: AudioConfig(
                sampleRate: audioSampleRate,
                channels: audioChannels,
                format: audioFormat,
                chunkDuration: audioChunkDuration
            ),
            whisper: WhisperConfig(
                model: whisperModel,
                language: whisperLanguage,
                task: whisperTask,
                temperature: whisperTemperature
            ),
            llm: LLMConfig(
                baseUrl: llmBaseUrl,
                enabled: llmEnabled,
                model: llmModel,
                temperature: llmTemperature,
                maxTokens: llmMaxTokens,
                prompt: llmPrompt
            ),
            hotkey: HotkeyConfig(
                keyCode: hotkeyKeyCode,
                modifiers: hotkeyModifiers
            ),
            logging: LoggingConfig(
                enabled: loggingEnabled,
                logFile: loggingLogFile,
                maxFileSize: loggingMaxFileSize,
                backupCount: loggingBackupCount
            )
        )
        
        let encoder = YAMLEncoder()
        return try encoder.encode(config)
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