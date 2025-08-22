import Carbon
import Cocoa

enum HotkeyManagerError: Error, LocalizedError {
    case registrationFailed
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .registrationFailed:
            return "Failed to register global hotkey"
        case .permissionDenied:
            return "Accessibility permission required for global hotkeys"
        }
    }
}

class HotkeyManager {
    
    // MARK: - Properties
    private var eventHandler: EventHandlerRef?
    private var hotkeyRef: EventHotKeyRef?
    private let hotkeyID = EventHotKeyID(signature: OSType(0x53545441), id: 1) // "STTA" as 32-bit value
    // Local hotkey monitor (works without permissions)
    private var localMonitor: Any?
    private var logger: Logger?
    private var settingsManager: SettingsManager?
    
    // Callback for when hotkey is pressed
    var onHotkeyPressed: (() -> Void)?
    
    // MARK: - Initialization
    init() {
        logger = Logger()
        let folderManager = FolderAccessManager()
        settingsManager = SettingsManager(folderAccessManager: folderManager)
        setupLocalHotkey() // Always works
        setupHotkey()      // Global hotkey (if permissions)
        
        // Listen for hotkey settings changes
        setupNotificationObservers()
    }
    
    deinit {
        cleanup()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notification Setup
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHotkeySettingsChanged),
            name: NSNotification.Name("HotkeySettingsChanged"),
            object: nil
        )
    }
    
    @objc private func handleHotkeySettingsChanged() {
        logger?.log("[HotkeyManager] Hotkey settings changed, refreshing configuration...", level: .info)
        refreshHotkeyConfiguration()
    }
    
    // MARK: - Public Methods
    func registerHotkey() throws {
        guard let settings = settingsManager else {
            logger?.log("Settings manager not available for hotkey registration", level: .error)
            throw HotkeyManagerError.registrationFailed
        }
        
        let hotkeyDisplay = settings.getHotkeyDisplayString()
        logger?.log("Attempting to register global hotkey (\(hotkeyDisplay))", level: .debug)
        
        // Check if accessibility permissions are granted
        guard checkAccessibilityPermissions() else {
            logger?.log("[HotkeyManager] Accessibility permission denied for global hotkey", level: .warning)
            throw HotkeyManagerError.permissionDenied
        }
        
        // Build modifiers from settings
        var modifiers: UInt32 = 0
        for modifier in settings.hotkeyModifiers {
            switch modifier {
            case "command": modifiers |= UInt32(cmdKey)
            case "shift": modifiers |= UInt32(shiftKey)
            case "option": modifiers |= UInt32(optionKey)
            case "control": modifiers |= UInt32(controlKey)
            default: break
            }
        }
        
        let keyCode = UInt32(settings.hotkeyKeyCode)
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
        
        guard status == noErr else {
            logger?.log("Global hotkey registration failed with status: \(status)", level: .error)
            throw HotkeyManagerError.registrationFailed
        }
        logger?.log("Global hotkey (\(hotkeyDisplay)) registered successfully", level: .info)
        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        let status2 = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let hotkeyManager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            hotkeyManager.handleHotkeyEvent()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        
        guard status2 == noErr else {
            logger?.log("Global hotkey event handler installation failed with status: \(status2)", level: .error)
            throw HotkeyManagerError.registrationFailed
        }
    }
    
    func unregisterHotkey() {
        cleanup()
    }
    
    func refreshHotkeyConfiguration() {
        logger?.log("[HotkeyManager] Refreshing hotkey configuration", level: .info)
        cleanup()
        setupHotkey()
    }
    
    // MARK: - Private Methods
    private func setupHotkey() {
        do {
            try registerHotkey()
        } catch {
            logger?.log("[HotkeyManager] Failed to register global hotkey: \(error.localizedDescription)", level: .warning)
            logger?.log("[HotkeyManager] To enable global hotkeys:", level: .info)
            logger?.log("[HotkeyManager] 1. Open System Settings", level: .info)
            logger?.log("[HotkeyManager] 2. Go to Privacy & Security > Accessibility", level: .info)
            logger?.log("[HotkeyManager] 3. Find 'Speech To Text App' in the list", level: .info)
            logger?.log("[HotkeyManager] 4. Toggle the switch to enable access", level: .info)
            logger?.log("[HotkeyManager] 5. Restart the app", level: .info)
        }
    }
    
    private func handleHotkeyEvent() {
        let hotkeyDisplay = settingsManager?.getHotkeyDisplayString() ?? "Unknown"
        logger?.log("[HotkeyManager] Global hotkey pressed (\(hotkeyDisplay))", level: .info)
        DispatchQueue.main.async { [weak self] in
            self?.onHotkeyPressed?()
        }
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // Local hotkey (works immediately, no permissions needed)
    private func setupLocalHotkey() {
        guard let settings = settingsManager else {
            logger?.log("[HotkeyManager] Settings manager not available for local hotkey setup", level: .error)
            return
        }
        
        let hotkeyDisplay = settings.getHotkeyDisplayString()
        logger?.log("[HotkeyManager] Setting up local hotkey (\(hotkeyDisplay))", level: .debug)
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self, let settings = self.settingsManager else { return event }
            
            // Build expected modifier flags
            var expectedModifiers: NSEvent.ModifierFlags = []
            for modifier in settings.hotkeyModifiers {
                switch modifier {
                case "command": expectedModifiers.insert(.command)
                case "shift": expectedModifiers.insert(.shift)
                case "option": expectedModifiers.insert(.option)
                case "control": expectedModifiers.insert(.control)
                default: break
                }
            }
            
            let actualModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            if actualModifiers == expectedModifiers && Int(event.keyCode) == settings.hotkeyKeyCode {
                self.logger?.log("[HotkeyManager] Local hotkey pressed (\(hotkeyDisplay))", level: .info)
                self.onHotkeyPressed?()
                return nil // Swallow the keystroke
            }
            return event
        }
        logger?.log("[HotkeyManager] Local hotkey (\(hotkeyDisplay)) registered successfully", level: .info)
    }
    
    private func cleanup() {
        logger?.log("[HotkeyManager] Cleaning up HotkeyManager", level: .debug)
        // Clean up local monitor
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
            logger?.log("[HotkeyManager] Local hotkey monitor removed", level: .debug)
        }
        // Clean up global hotkey
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
            logger?.log("[HotkeyManager] Global hotkey unregistered", level: .debug)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
            logger?.log("[HotkeyManager] Global hotkey event handler removed", level: .debug)
        }
    }
} 