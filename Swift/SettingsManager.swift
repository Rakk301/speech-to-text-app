import Foundation
import SwiftUI
import Yams
import Carbon

// MARK: - Configuration Models
struct WhisperConfig: Codable {
    var model: String
    var task: String
    var language: String
    var temperature: Float

    enum CodingKeys: String, CodingKey {
        case model
        case task
        case language
        case temperature
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

struct ServerConfig: Codable {
    var host: String
    var port: Int
    var uvPath: String?
    
    enum CodingKeys: String, CodingKey {
        case host
        case port
        case uvPath = "uv_path"
    }
}

struct AppConfig: Codable {
    var whisper: WhisperConfig
    var hotkey: HotkeyConfig
    var server: ServerConfig?
}

// MARK: - Settings Change Notifications
extension Notification.Name {
    static let whisperModelChanged = Notification.Name("whisperModelChanged")
    static let hotkeyChanged = Notification.Name("hotkeyChanged")
    static let hotkeySettingsChanged = Notification.Name("hotkeySettingsChanged")
    static let whisperSettingsChanged = Notification.Name("whisperSettingsChanged")
    static let serverSettingsChanged = Notification.Name("serverSettingsChanged")
    static let whisperModelReloaded = Notification.Name("whisperModelReloaded")
}

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var whisperModel: String = "small"
    @Published var whisperTask: String = "transcribe"
    @Published var whisperLanguage: String = "auto"
    @Published var whisperTemperature: Float = 0.0
    @Published var hotkeyKeyCode: Int = 37  // L key
    @Published var hotkeyModifiers: [String] = ["option"]
    
    // Server configuration
    var serverHost: String = "localhost"
    var serverPort: Int = 3001
    var uvPath: String = "/opt/homebrew/bin/uv"
    
    
    // MARK: - Properties
    let configFileURL: URL
    private let logger = Logger()
    
    // Available options
    let availableModels = ["tiny", "base", "small", "medium", "large"]
    
    // MARK: - Initialization
    init() {
        // Use Application Support for config
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("SpeechToTextApp")
        configFileURL = appSupportURL.appendingPathComponent("settings.yaml")
        
        logger.log("Using config file at: \(configFileURL.path)", level: .debug)
        loadSettings()
    }
    
    // MARK: - Load Settings
    func loadSettings() {
        logger.log("Loading settings from: \(configFileURL.path)", level: .debug)
        
        if FileManager.default.fileExists(atPath: configFileURL.path) {
            do {
                let data = try Data(contentsOf: configFileURL)
                if let yamlString = String(data: data, encoding: .utf8) {
                    try parseYAMLSettings(yamlString)
                    logger.log("Settings loaded successfully", level: .debug)
                }
            } catch {
                logger.logError(error, context: "Failed to load settings")
                setDefaultSettings()
            }
        } else {
            logger.log("No settings file found, creating defaults", level: .debug)
            setDefaultSettings()
            saveSettings()
        }
    }
    
    // MARK: - Save Settings
    func saveSettings() {
        logger.log("Saving settings to: \(configFileURL.path)", level: .debug)
        
        do {
            let config = AppConfig(
                whisper: WhisperConfig(
                    model: whisperModel,
                    task: whisperTask,
                    language: whisperLanguage,
                    temperature: whisperTemperature
                ),
                hotkey: HotkeyConfig(keyCode: hotkeyKeyCode, modifiers: hotkeyModifiers)
            )
            
            let encoder = YAMLEncoder()
            let yamlContent = try encoder.encode(config)
            
            // Ensure directory exists
            let configDir = configFileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            
            try yamlContent.write(to: configFileURL, atomically: true, encoding: .utf8)
            logger.log("Settings saved successfully", level: .info)
        } catch {
            logger.logError(error, context: "Failed to save settings")
        }
    }
    
    // MARK: - Update Methods
    func updateWhisperModel(_ model: String) {
        whisperModel = model
        NotificationCenter.default.post(name: .whisperModelChanged, object: self)
        logger.log("Whisper model changed to: \(model)", level: .info)
        saveSettings()
    }
    
    func updateHotkey(keyCode: Int, modifiers: [String]) {
        hotkeyKeyCode = keyCode
        hotkeyModifiers = modifiers
        NotificationCenter.default.post(name: .hotkeyChanged, object: self)
        logger.log("Hotkey changed", level: .info)
        saveSettings()
    }

    func updateWhisperSettings() {
        NotificationCenter.default.post(name: .whisperSettingsChanged, object: self)
        saveSettings()
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
    
    // MARK: - Private Methods
    private func parseYAMLSettings(_ yamlString: String) throws {
        let decoder = YAMLDecoder()
        let config = try decoder.decode(AppConfig.self, from: yamlString)
        
        // Load whisper configuration
        whisperModel = config.whisper.model
        whisperTask = config.whisper.task
        whisperLanguage = config.whisper.language
        whisperTemperature = config.whisper.temperature
        
        // Load hotkey configuration
        hotkeyKeyCode = config.hotkey.keyCode
        hotkeyModifiers = config.hotkey.modifiers
        
        // Load server configuration
        if let server = config.server {
            serverHost = server.host
            serverPort = server.port
            if let uv = server.uvPath {
                uvPath = uv
            }
        }
    }
    
    private func setDefaultSettings() {
        whisperModel = "small"
        whisperTask = "transcribe"
        whisperLanguage = "auto"
        whisperTemperature = 0.0
        hotkeyKeyCode = 37  // L key
        hotkeyModifiers = ["option"]
        logger.log("Default settings applied", level: .info)
    }

    private func keyCodeToCharacter(_ keyCode: Int) -> String {
        // Use system APIs for proper keyboard layout support
        return keyCodeToCharacterWithLayout(UInt16(keyCode), modifiers: 0)
    }

    private func keyCodeToCharacterWithLayout(_ virtualKeyCode: UInt16, modifiers: UInt32) -> String {
        // Get current keyboard layout
        let inputSourceRef = TISCopyCurrentKeyboardInputSource()
        guard let inputSource = inputSourceRef?.takeUnretainedValue(),
              let layoutData = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData) else {
            // Release the input source reference if it was created
            if let inputSourceRef = inputSourceRef {
                inputSourceRef.release()
            }
            // Fallback to hardcoded mapping if system APIs fail
            return fallbackKeyCodeToCharacter(Int(virtualKeyCode))
        }

        let keyLayoutPtr = unsafeBitCast(layoutData, to: UnsafePointer<UCKeyboardLayout>.self)

        var deadKeyState: UInt32 = 0
        var actualStringLength: Int = 0
        var unicodeString: [UniChar] = [0, 0, 0, 0] // Buffer for up to 4 Unicode characters

        let status = UCKeyTranslate(
            keyLayoutPtr,
            virtualKeyCode,
            UInt16(kUCKeyActionDown),
            modifiers,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysMask),
            &deadKeyState,
            unicodeString.count,
            &actualStringLength,
            &unicodeString
        )

        // Release the input source reference
        if let inputSourceRef = inputSourceRef {
            inputSourceRef.release()
        }

        if status == noErr && actualStringLength > 0 {
            // Convert UniChar array to String
            let unicodeValue = UInt32(unicodeString[0])
            if let unicodeScalar = UnicodeScalar(unicodeValue) {
                return String(unicodeScalar)
            }
        }
        return "?"
    }

    private func fallbackKeyCodeToCharacter(_ keyCode: Int) -> String {
        // Keep the original hardcoded mapping as fallback
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
        case 37: return "L"
        default: return "?"
        }
    }
}

