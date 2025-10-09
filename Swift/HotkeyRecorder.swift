import SwiftUI
import Carbon

class HotkeyRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var isRecordingComplete = false
    @Published var displayString: String = "Press any key..."
    
    private var eventMonitor: Any?
    private var recordedKeyCode: Int = 0
    private var recordedModifiers: [String] = []
    
    func startRecording() {
        isRecording = true
        isRecordingComplete = false
        displayString = "Press any key..."
        recordedKeyCode = 0
        recordedModifiers = []
        
        // Monitor key down events
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDownEvent(event)
            return nil // Consume the event
        }
    }
    
    func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    func resetToDefaults() {
        isRecording = false
        isRecordingComplete = false
        displayString = "Press any key..."
        recordedKeyCode = 0
        recordedModifiers = []
    }
    
    func getRecordedKeysString() -> String {
        return displayString
    }
    
    func getHotkeyConfiguration() -> (keyCode: Int, modifiers: [String]) {
        return (recordedKeyCode, recordedModifiers)
    }
    
    private func handleKeyDownEvent(_ event: NSEvent) {
        let keyCode = Int(event.keyCode)
        let modifiers = extractModifiers(from: event.modifierFlags)
        
        // Only record if we have a valid key combination
        if keyCode > 0 && !modifiers.isEmpty {
            recordedKeyCode = keyCode
            recordedModifiers = modifiers
            displayString = generateDisplayString(from: event)
            isRecordingComplete = true
        }
    }
    
    private func extractModifiers(from flags: NSEvent.ModifierFlags) -> [String] {
        var modifiers: [String] = []
        
        if flags.contains(.command) {
            modifiers.append("command")
        }
        if flags.contains(.shift) {
            modifiers.append("shift")
        }
        if flags.contains(.option) {
            modifiers.append("option")
        }
        if flags.contains(.control) {
            modifiers.append("control")
        }
        
        return modifiers
    }
    
    private func generateDisplayString(from event: NSEvent) -> String {
        var display = ""
        
        // Add modifier symbols in consistent order
        if recordedModifiers.contains("command") { display += "⌘" }
        if recordedModifiers.contains("shift") { display += "⇧" }
        if recordedModifiers.contains("option") { display += "⌥" }
        if recordedModifiers.contains("control") { display += "⌃" }
        
        // Use system APIs to get the character representation
        let character = getCharacterFromEvent(event)
        display += character
        
        return display
    }
    
    private func getCharacterFromEvent(_ event: NSEvent) -> String {
        // Use charactersIgnoringModifiers to get the base character
        // This gives us the unmodified key character
        if let baseChar = event.charactersIgnoringModifiers, !baseChar.isEmpty {
            // For letter keys, always show uppercase
            let char = baseChar.uppercased()
            // Return the first character only (in case of multi-char strings)
            return String(char.prefix(1))
        }
        
        // Fallback: use a keyCode-to-character mapping for special keys
        return keyCodeToDisplayCharacter(Int(event.keyCode))
    }
    
    private func keyCodeToDisplayCharacter(_ keyCode: Int) -> String {
        // Map common key codes to their display characters
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
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 50: return "`"
        case 49: return "Space"
        case 36: return "↵"  // Return
        case 48: return "⇥"  // Tab
        case 51: return "⌫"  // Delete
        case 53: return "⎋"  // Escape
        case 117: return "⌦" // Forward Delete
        default: return "Key"
        }
    }
    
    deinit {
        stopRecording()
    }
}


