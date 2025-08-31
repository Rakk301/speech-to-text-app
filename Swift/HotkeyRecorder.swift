import Foundation
import Cocoa
import Carbon

class HotkeyRecorder: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var currentKeyCode: Int = 0
    @Published var currentModifiers: [String] = []
    @Published var displayString = ""
    
    // MARK: - Properties
    private var localMonitor: Any?
    private let logger = Logger()
    
    // MARK: - Public Methods
    func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        currentKeyCode = 0
        currentModifiers = []
        displayString = "Press keys..."
        
        logger.log("[HotkeyRecorder] Started recording hotkey", level: .info)
        setupLocalMonitor()
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        localMonitor = nil
        
        logger.log("[HotkeyRecorder] Stopped recording hotkey", level: .info)
    }
    
    func getHotkeyConfiguration() -> (keyCode: Int, modifiers: [String]) {
        return (currentKeyCode, currentModifiers)
    }
    
    func resetToDefaults() {
        currentKeyCode = 37  // L key
        currentModifiers = ["option"]
        updateDisplayString()
    }
    
    // MARK: - Private Methods
    private func setupLocalMonitor() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self, self.isRecording else { return event }
            
            if event.type == .keyDown {
                self.handleKeyDown(event)
            } else if event.type == .flagsChanged {
                self.handleFlagsChanged(event)
            }
            
            return nil // Swallow all events while recording
        }
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        let keyCode = Int(event.keyCode)
        let modifiers = getModifiersFromEvent(event)
        
        // Only accept modifier keys if they're combined with a regular key
        if !modifiers.isEmpty && keyCode != 0 {
            currentKeyCode = keyCode
            currentModifiers = modifiers
            updateDisplayString()
            
            logger.log("[HotkeyRecorder] Captured hotkey: \(displayString)", level: .info)
            
            // Stop recording after capturing a valid combination
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.stopRecording()
            }
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        // Update modifiers in real-time while recording
        if isRecording {
            let modifiers = getModifiersFromEvent(event)
            currentModifiers = modifiers
            updateDisplayString()
        }
    }
    
    private func getModifiersFromEvent(_ event: NSEvent) -> [String] {
        var modifiers: [String] = []
        
        if event.modifierFlags.contains(.command) {
            modifiers.append("command")
        }
        if event.modifierFlags.contains(.shift) {
            modifiers.append("shift")
        }
        if event.modifierFlags.contains(.option) {
            modifiers.append("option")
        }
        if event.modifierFlags.contains(.control) {
            modifiers.append("control")
        }
        
        return modifiers
    }
    
    private func updateDisplayString() {
        var display = ""
        
        if currentModifiers.contains("command") { display += "⌘" }
        if currentModifiers.contains("shift") { display += "⇧" }
        if currentModifiers.contains("option") { display += "⌥" }
        if currentModifiers.contains("control") { display += "⌃" }
        
        if currentKeyCode > 0 {
            let keyChar = keyCodeToCharacter(currentKeyCode)
            display += keyChar
        }
        
        displayString = display.isEmpty ? "Press keys..." : display
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
        case 37: return "L"
        case 36: return "Return"
        case 48: return "Tab"
        case 49: return "Space"
        case 51: return "Delete"
        case 53: return "Escape"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "?"
        }
    }
    
    deinit {
        stopRecording()
    }
}
