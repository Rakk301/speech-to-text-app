
import Carbon
import Cocoa

// MARK: - Error Handling
enum HotkeyManagerError: Error, LocalizedError {
    case settingsManagerNotAvailable
    case permissionDenied
    case hotkeyRegistrationFailed(status: OSStatus)
    case eventHandlerInstallationFailed(status: OSStatus)
    case bundleIdentifierNotFound

    var errorDescription: String? {
        switch self {
        case .settingsManagerNotAvailable:
            return "Settings manager is not available."
        case .permissionDenied:
            return "Accessibility permission is required for global hotkeys."
        case .hotkeyRegistrationFailed(let status):
            return "Failed to register global hotkey with status: \(status)"
        case .eventHandlerInstallationFailed(let status):
            return "Failed to install global hotkey event handler with status: \(status)"
        case .bundleIdentifierNotFound:
            return "Could not determine the application's bundle identifier."
        }
    }
}

// MARK: - HotkeyManager Class
class HotkeyManager {
    
    // MARK: - Properties
    private var hotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var localMonitor: Any?
    
    private let logger = Logger()
    private let settingsManager: SettingsManager
    
    // Callback for when hotkey is pressed
    var onHotkeyPressed: (() -> Void)?
    
    // MARK: - Initialization
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        logger.log("[HotkeyManager] Initializing", level: .info)
        setupHotkeys()
        
        // Listen for settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHotkeySettingsChanged),
            name: .hotkeySettingsChanged,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanup()
    }
    
    // MARK: - Public Methods
    func refreshHotkeyConfiguration() {
        logger.log("[HotkeyManager] Refreshing hotkey configuration", level: .info)
        cleanup()
        setupHotkeys()
    }
    
    // MARK: - Settings Change Handling
    @objc private func handleHotkeySettingsChanged() {
        logger.log("[HotkeyManager] Hotkey settings changed, refreshing configuration", level: .info)
        refreshHotkeyConfiguration()
    }
    
    // MARK: - Setup
    private func setupHotkeys() {
        // First, set up the local hotkey which always works
        setupLocalHotkey()
        
        // Then, attempt to set up the global hotkey
        do {
            try setupGlobalHotkey()
        } catch {
            logger.logError(error, context: "Failed to register global hotkey")
            if let error = error as? HotkeyManagerError, case .permissionDenied = error {
                logAccessibilityInstructions()
            }
        }
    }
    
    // MARK: - Global Hotkey (Carbon)
    private func setupGlobalHotkey() throws {
        let hotkeyDisplay = settingsManager.getHotkeyDisplayString()
        logger.log("[HotkeyManager] Attempting to register global hotkey: \(hotkeyDisplay)", level: .debug)
        
        guard checkAccessibilityPermissions() else {
            throw HotkeyManagerError.permissionDenied
        }
        
        let (keyCode, modifiers) = try getHotkeyConfiguration()
        let hotkeyID = try getUniqueHotkeyID()
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
        guard status == noErr else {
            throw HotkeyManagerError.hotkeyRegistrationFailed(status: status)
        }
        
        logger.log("[HotkeyManager] Global hotkey registered successfully: \(hotkeyDisplay)", level: .info)
        
        try installGlobalHotkeyEventHandler()
    }
    
    private func installGlobalHotkeyEventHandler() throws {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        let status = InstallEventHandler(GetApplicationEventTarget(), { (handler, event, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let hotkeyManager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            hotkeyManager.handleGlobalHotkeyEvent()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        
        guard status == noErr else {
            throw HotkeyManagerError.eventHandlerInstallationFailed(status: status)
        }
        logger.log("[HotkeyManager] Global hotkey event handler installed", level: .debug)
    }
    
    private func handleGlobalHotkeyEvent() {
        let hotkeyDisplay = settingsManager.getHotkeyDisplayString()
        logger.log("[HotkeyManager] Global hotkey pressed: \(hotkeyDisplay)", level: .info)
        DispatchQueue.main.async { [weak self] in
            self?.onHotkeyPressed?()
        }
    }
    
    // MARK: - Local Hotkey (Cocoa)
    private func setupLocalHotkey() {
        let hotkeyDisplay = settingsManager.getHotkeyDisplayString()
        logger.log("[HotkeyManager] Setting up local hotkey: \(hotkeyDisplay)", level: .debug)
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self else { return event }
            
            guard let (expectedKeyCode, expectedModifiers) = try? self.getHotkeyConfigurationForLocalMonitor() else {
                return event
            }
            
            let actualModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            if actualModifiers == expectedModifiers && event.keyCode == expectedKeyCode {
                self.logger.log("[HotkeyManager] Local hotkey pressed: \(hotkeyDisplay)", level: .info)
                self.onHotkeyPressed?()
                return nil // Swallow the event
            }
            
            return event
        }
        logger.log("[HotkeyManager] Local hotkey monitor installed", level: .debug)
    }
    
    // MARK: - Configuration & Permissions
    private func getUniqueHotkeyID() throws -> EventHotKeyID {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            throw HotkeyManagerError.bundleIdentifierNotFound
        }
        
        let signature = fourCharString(from: bundleId)
        return EventHotKeyID(signature: signature, id: 1)
    }
    
    private func fourCharString(from string: String) -> FourCharCode {
        // A simple hashing algorithm to generate a FourCharCode from a string.
        var hash: UInt32 = 0
        for char in string.unicodeScalars {
            hash = (hash &* 31) &+ char.value
        }
        return hash
    }
    
    private func getHotkeyConfiguration() throws -> (keyCode: UInt32, modifiers: UInt32) {
        let keyCode = UInt32(settingsManager.hotkeyKeyCode)
        
        var modifiers: UInt32 = 0
        for modifier in settingsManager.hotkeyModifiers {
            switch modifier {
            case "command": modifiers |= UInt32(cmdKey)
            case "shift":   modifiers |= UInt32(shiftKey)
            case "option":  modifiers |= UInt32(optionKey)
            case "control": modifiers |= UInt32(controlKey)
            default: break
            }
        }
        return (keyCode, modifiers)
    }
    
    private func getHotkeyConfigurationForLocalMonitor() throws -> (keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        let keyCode = UInt16(settingsManager.hotkeyKeyCode)
        
        var modifiers: NSEvent.ModifierFlags = []
        for modifier in settingsManager.hotkeyModifiers {
            switch modifier {
            case "command": modifiers.insert(.command)
            case "shift":   modifiers.insert(.shift)
            case "option":  modifiers.insert(.option)
            case "control": modifiers.insert(.control)
            default: break
            }
        }
        return (keyCode, modifiers)
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): kCFBooleanFalse]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        logger.log("[HotkeyManager] Cleaning up hotkey resources", level: .debug)
        
        // Clean up global hotkey
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
            logger.log("[HotkeyManager] Global hotkey unregistered", level: .debug)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
            logger.log("[HotkeyManager] Global event handler removed", level: .debug)
        }
        
        // Clean up local monitor
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
            logger.log("[HotkeyManager] Local hotkey monitor removed", level: .debug)
        }
    }
    
    // MARK: - Helper
    private func logAccessibilityInstructions() {
        logger.log("[HotkeyManager] To enable global hotkeys, please grant Accessibility permissions:", level: .warning)
        logger.log("[HotkeyManager] 1. Open System Settings > Privacy & Security", level: .warning)
        logger.log("[HotkeyManager] 2. Select 'Accessibility'", level: .warning)
        logger.log("[HotkeyManager] 3. Find 'SpeechToTextApp' and enable it.", level: .warning)
        logger.log("[HotkeyManager] 4. A restart of the app may be required.", level: .warning)
    }
}
