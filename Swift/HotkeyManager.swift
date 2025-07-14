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
    
    // Callback for when hotkey is pressed
    var onHotkeyPressed: (() -> Void)?
    
    // MARK: - Initialization
    init() {
        logger = Logger()
        setupLocalHotkey() // Always works
        setupHotkey()      // Global hotkey (if permissions)
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    func registerHotkey() throws {
        logger?.log("Attempting to register global hotkey (⌘⇧⌥T)", level: .debug)
        // Check if accessibility permissions are granted
        guard checkAccessibilityPermissions() else {
            logger?.log("Accessibility permission denied for global hotkey", level: .warning)
            throw HotkeyManagerError.permissionDenied
        }
        
        // Register the hotkey (⌘⇧⌥T) - Command + Shift + Option + T
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey | optionKey)
        let keyCode = UInt32(kVK_ANSI_T)
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
        
        guard status == noErr else {
            logger?.log("Global hotkey registration failed with status: \(status)", level: .error)
            throw HotkeyManagerError.registrationFailed
        }
        logger?.log("Global hotkey registered successfully", level: .info)
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
    
    // MARK: - Private Methods
    private func setupHotkey() {
        do {
            try registerHotkey()
        } catch {
            logger?.log("Failed to register global hotkey: \(error.localizedDescription)", level: .warning)
            logger?.log("To enable global hotkeys:", level: .info)
            logger?.log("1. Open System Settings", level: .info)
            logger?.log("2. Go to Privacy & Security > Accessibility", level: .info)
            logger?.log("3. Find 'Speech To Text App' in the list", level: .info)
            logger?.log("4. Toggle the switch to enable access", level: .info)
            logger?.log("5. Restart the app", level: .info)
        }
    }
    
    private func handleHotkeyEvent() {
        logger?.log("Global hotkey pressed (⌘⇧⌥T)", level: .info)
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
        logger?.log("Setting up local hotkey (⌘⇧⌥T)", level: .debug)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command, .shift, .option],
               event.keyCode == kVK_ANSI_T {
                self?.logger?.log("Local hotkey pressed (⌘⇧⌥T)", level: .info)
                self?.onHotkeyPressed?()
                return nil // Swallow the keystroke
            }
            return event
        }
        logger?.log("Local hotkey registered successfully", level: .info)
    }
    
    private func cleanup() {
        logger?.log("Cleaning up HotkeyManager", level: .debug)
        // Clean up local monitor
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
            logger?.log("Local hotkey monitor removed", level: .debug)
        }
        // Clean up global hotkey
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
            logger?.log("Global hotkey unregistered", level: .debug)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
            logger?.log("Global hotkey event handler removed", level: .debug)
        }
    }
} 