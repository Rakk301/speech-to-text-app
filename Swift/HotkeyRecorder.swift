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
        // First try to get the character from the event itself
        if let characters = event.characters, !characters.isEmpty {
            return characters.uppercased()
        }
        
        // If no character available, try charactersIgnoringModifiers
        if let charactersIgnoringModifiers = event.charactersIgnoringModifiers, !charactersIgnoringModifiers.isEmpty {
            return charactersIgnoringModifiers.uppercased()
        }
        
        // If no character representation available, return a generic key indicator
        return "Key"
    }
    
    deinit {
        stopRecording()
    }
}


