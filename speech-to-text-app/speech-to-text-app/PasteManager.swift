import Cocoa
import ApplicationServices

enum PasteManagerError: Error, LocalizedError {
    case pasteboardFailed
    case cursorPositionFailed
    case accessibilityPermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .pasteboardFailed:
            return "Failed to access pasteboard"
        case .cursorPositionFailed:
            return "Failed to get cursor position"
        case .accessibilityPermissionDenied:
            return "Accessibility permission required for cursor positioning"
        }
    }
}

class PasteManager {
    
    // MARK: - Properties
    private let pasteboard = NSPasteboard.general
    
    // MARK: - Public Methods
    func pasteText(_ text: String, completion: @escaping (Bool) -> Void) {
        // First try to paste at cursor position
        if pasteAtCursorPosition(text) {
            completion(true)
            return
        }
        
        // Fallback to clipboard paste
        if pasteToClipboard(text) {
            completion(true)
            return
        }
        
        completion(false)
    }
    
    // MARK: - Private Methods
    private func pasteAtCursorPosition(_ text: String) -> Bool {
        // Check accessibility permissions
        guard checkAccessibilityPermissions() else {
            return false
        }
        
        // Get current cursor position
        guard let cursorPosition = getCursorPosition() else {
            return false
        }
        
        // Type the text at cursor position
        return typeTextAtPosition(text, position: cursorPosition)
    }
    
    private func pasteToClipboard(_ text: String) -> Bool {
        // Clear existing content
        pasteboard.clearContents()
        
        // Set new text content
        guard pasteboard.setString(text, forType: .string) else {
            return false
        }
        
        // Simulate Cmd+V to paste
        return simulatePasteShortcut()
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    private func getCursorPosition() -> CGPoint? {
        // Get the current mouse position as a fallback
        // In a real implementation, you'd use accessibility APIs to get the actual text cursor position
        let mouseLocation = NSEvent.mouseLocation
        return CGPoint(x: mouseLocation.x, y: mouseLocation.y)
    }
    
    private func typeTextAtPosition(_ text: String, position: CGPoint) -> Bool {
        // This is a simplified implementation
        // In a real app, you'd use accessibility APIs to type at the specific position
        
        // For now, we'll use the system-wide pasteboard and simulate typing
        return simulateTyping(text)
    }
    
    private func simulateTyping(_ text: String) -> Bool {
        // Use AppleScript to type the text
        let script = """
        tell application "System Events"
            keystroke "\(text)"
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        
        return error == nil
    }
    
    private func simulatePasteShortcut() -> Bool {
        // Use AppleScript to simulate Cmd+V
        let script = """
        tell application "System Events"
            key code 9 using command down
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        
        return error == nil
    }
} 