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
    private let hotkeyID = EventHotKeyID(signature: OSType(fourCharCode: "STTA"), id: 1)
    
    // Callback for when hotkey is pressed
    var onHotkeyPressed: (() -> Void)?
    
    // MARK: - Initialization
    init() {
        setupHotkey()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    func registerHotkey() throws {
        // Check if accessibility permissions are granted
        guard checkAccessibilityPermissions() else {
            throw HotkeyManagerError.permissionDenied
        }
        
        // Register the hotkey (⌘⇧S)
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_S)
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
        
        guard status == noErr else {
            throw HotkeyManagerError.registrationFailed
        }
        
        // Install event handler
        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        let status2 = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let hotkeyManager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            hotkeyManager.handleHotkeyEvent()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        
        guard status2 == noErr else {
            throw HotkeyManagerError.registrationFailed
        }
    }
    
    func unregisterHotkey() {
        cleanup()
    }
    
    // MARK: - Private Methods
    private func setupHotkey() {
        do {
            try registerHotkey()
        } catch {
            print("Failed to register hotkey: \(error.localizedDescription)")
        }
    }
    
    private func handleHotkeyEvent() {
        DispatchQueue.main.async { [weak self] in
            self?.onHotkeyPressed?()
        }
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    private func cleanup() {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
} 