import SwiftUI
import Carbon

class HotkeyRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var currentKeyCode: Int = 0
    @Published var currentModifiers: [String] = []
    @Published var displayString: String = "Press any key..."
    
    private var eventMonitor: Any?
    
    func startRecording() {
        isRecording = true
        currentKeyCode = 0
        currentModifiers = []
        displayString = "Press any key..."
        
        // Monitor key down events
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
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
        currentKeyCode = 0
        currentModifiers = []
        displayString = "Press any key..."
    }
    
    func getHotkeyConfiguration() -> (keyCode: Int, modifiers: [String]) {
        return (currentKeyCode, currentModifiers)
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        currentKeyCode = Int(event.keyCode)
        currentModifiers = extractModifiers(from: event.modifierFlags)
        displayString = generateDisplayString()
        
        // Auto-stop recording after capturing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.stopRecording()
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
    
    private func generateDisplayString() -> String {
        var display = ""
        
        if currentModifiers.contains("command") { display += "⌘" }
        if currentModifiers.contains("shift") { display += "⇧" }
        if currentModifiers.contains("option") { display += "⌥" }
        if currentModifiers.contains("control") { display += "⌃" }
        
        let keyChar = keyCodeToCharacter(currentKeyCode)
        display += keyChar
        
        return display
    }
    
    private func keyCodeToCharacter(_ keyCode: Int) -> String {
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
    
    deinit {
        stopRecording()
    }
}


