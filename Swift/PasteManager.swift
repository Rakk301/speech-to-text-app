import Cocoa
import ApplicationServices

enum PasteManagerError: Error, LocalizedError {
    case pasteboardFailed
    case accessibilityPermissionDenied
    case pasteOperationFailed
    
    var errorDescription: String? {
        switch self {
        case .pasteboardFailed:
            return "Failed to access pasteboard"
        case .accessibilityPermissionDenied:
            return "Accessibility permission required for paste-at-cursor"
        case .pasteOperationFailed:
            return "Failed to paste text at cursor"
        }
    }
}

class PasteManager {
    
    // MARK: - Properties
    private let pasteboard = NSPasteboard.general
    private let logger = Logger(componentName: "PasteManager")
    private var originalClipboardContent: String?
    
    // MARK: - Public Methods
    func pasteText(_ text: String, completion: @escaping (Bool) -> Void) {
        // Check accessibility permissions first
        guard AXIsProcessTrusted() else {
            logger.log("Accessibility permissions not granted", level: .warning)
            completion(false)
            return
        }
        
        // Save original clipboard content
        saveOriginalClipboard()
        
        // Copy text to clipboard
        guard copyToClipboard(text) else {
            logger.log("Failed to copy text to clipboard", level: .error)
            completion(false)
            return
        }
        
        // Send Cmd+V using CGEvent to paste at cursor
        let success = simulatePasteKeyEvent()
        
        // Restore original clipboard after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.restoreOriginalClipboard()
        }
        
        if success {
            logger.log("Text pasted at cursor successfully", level: .info)
        } else {
            logger.log("Failed to paste text at cursor", level: .error)
        }
        
        completion(success)
    }
    
    // MARK: - Private Methods
    private func saveOriginalClipboard() {
        originalClipboardContent = pasteboard.string(forType: .string)
        logger.log("Saved original clipboard content", level: .debug)
    }
    
    private func restoreOriginalClipboard() {
        if let originalContent = originalClipboardContent {
            pasteboard.clearContents()
            pasteboard.setString(originalContent, forType: .string)
            logger.log("Restored original clipboard content", level: .debug)
        }
        originalClipboardContent = nil
    }
    
    private func copyToClipboard(_ text: String) -> Bool {
        // Clear existing content
        pasteboard.clearContents()
        
        // Set new text content
        guard pasteboard.setString(text, forType: .string) else {
            logger.log("Failed to set text in clipboard", level: .error)
            return false
        }
        
        logger.log("Text copied to clipboard successfully", level: .info)
        return true
    }
    
    private func simulatePasteKeyEvent() -> Bool {
        // Create Cmd+V key event
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            logger.log("Failed to create CGEventSource", level: .error)
            return false
        }
        
        // Create key down event for 'V' key (keycode 9) with Command modifier
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true) else {
            logger.log("Failed to create key down event", level: .error)
            return false
        }
        
        // Create key up event for 'V' key
        guard let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else {
            logger.log("Failed to create key up event", level: .error)
            return false
        }
        
        // Set Command modifier flag
        keyDownEvent.flags = .maskCommand
        keyUpEvent.flags = .maskCommand
        
        // Post the events
        keyDownEvent.post(tap: .cgAnnotatedSessionEventTap)
        
        // Small delay between key down and key up
        usleep(10000) // 10ms delay
        
        keyUpEvent.post(tap: .cgAnnotatedSessionEventTap)
        
        logger.log("Sent Cmd+V key events", level: .debug)
        return true
    }
} 