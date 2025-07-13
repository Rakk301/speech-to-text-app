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
    
    // Callback for when hotkey is pressed
    var onHotkeyPressed: (() -> Void)?
    
    // MARK: - Initialization
    init() {
        print("[HotkeyManager] Initializing HotkeyManager")
        setupLocalHotkey() // Always works
        setupHotkey()      // Global hotkey (if permissions)
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    func registerHotkey() throws {
        print("[HotkeyManager] Attempting to register hotkey (⌘⇧⌥T)")
        // Check if accessibility permissions are granted
        guard checkAccessibilityPermissions() else {
            print("[HotkeyManager] Accessibility permission denied")
            throw HotkeyManagerError.permissionDenied
        }
        
        // Register the hotkey (⌘⇧⌥T) - Command + Shift + Option + T
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey | optionKey)
        let keyCode = UInt32(kVK_ANSI_T)
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
        
        guard status == noErr else {
            print("[HotkeyManager] Hotkey registration failed with status: \(status)")
            throw HotkeyManagerError.registrationFailed
        }
        print("[HotkeyManager] Hotkey registered successfully")
        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        let status2 = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let hotkeyManager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            hotkeyManager.handleHotkeyEvent()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        
        guard status2 == noErr else {
            print("[HotkeyManager] Event handler installation failed with status: \(status2)")
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
            print("To enable global hotkeys:")
            print("1. Open System Settings")
            print("2. Go to Privacy & Security > Accessibility")
            print("3. Find 'Speech To Text App' in the list")
            print("4. Toggle the switch to enable access")
            print("5. Restart the app")
        }
    }
    
    private func handleHotkeyEvent() {
        print("[HotkeyManager] Hotkey pressed (⌘⇧⌥T)")
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
        print("[HotkeyManager] Setting up local hotkey (⌘⇧⌥T)")
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command, .shift, .option],
               event.keyCode == kVK_ANSI_T {
                print("[HotkeyManager] Local hotkey pressed (⌘⇧⌥T)")
                self?.onHotkeyPressed?()
                return nil // Swallow the keystroke
            }
            return event
        }
        print("[HotkeyManager] Local hotkey registered successfully")
    }
    
    private func cleanup() {
        // Clean up local monitor
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        // Clean up global hotkey
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