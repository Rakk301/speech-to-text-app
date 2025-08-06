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
    private var originalClipboardContent: String?
    
    // MARK: - Public Methods
    func pasteText(_ text: String, completion: @escaping (Bool) -> Void) {
        print("[PasteManager] Starting seamless paste operation for text: \(text)")
        
        // Step 1: Save original clipboard content
        saveOriginalClipboard()
        
        // Step 2: Copy text to clipboard
        guard copyTextToClipboard(text) else {
            restoreOriginalClipboard()
            completion(false)
            return
        }
        
        // Step 3: Immediately simulate paste at live cursor position
        if simulatePasteAtCursor() {
            print("[PasteManager] ✅ Text pasted seamlessly at cursor")
            restoreOriginalClipboard()
            completion(true)
        } else {
            print("[PasteManager] ❌ Failed to paste at cursor")
            restoreOriginalClipboard()
            completion(false)
        }
    }
    
    // MARK: - Private Methods
    private func saveOriginalClipboard() {
        originalClipboardContent = pasteboard.string(forType: .string)
        print("[PasteManager] Saved original clipboard content")
    }
    
    private func restoreOriginalClipboard() {
        if let originalContent = originalClipboardContent {
            pasteboard.clearContents()
            pasteboard.setString(originalContent, forType: .string)
            print("[PasteManager] Restored original clipboard content")
        }
        originalClipboardContent = nil
    }
    
    private func copyTextToClipboard(_ text: String) -> Bool {
        pasteboard.clearContents()
        
        guard pasteboard.setString(text, forType: .string) else {
            print("[PasteManager] Failed to copy text to clipboard")
            return false
        }
        
        print("[PasteManager] Text copied to clipboard successfully")
        return true
    }
    
    private func simulatePasteAtCursor() -> Bool {
        // Check accessibility permissions
        guard checkAccessibilityPermissions() else {
            print("[PasteManager] Accessibility permissions not granted")
            return false
        }
        
        // Use AppleScript to paste at current live cursor position
        return executePasteAppleScript()
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !isTrusted {
            print("[PasteManager] Accessibility permissions not granted. Please enable in System Preferences > Security & Privacy > Privacy > Accessibility")
        }
        
        return isTrusted
    }
    
    private func executePasteAppleScript() -> Bool {
        // AppleScript to paste at current live cursor position
        let script = """
        tell application "System Events"
            -- Get the frontmost application
            set frontApp to name of first application process whose frontmost is true
            
            -- Activate the frontmost app to ensure focus
            tell application frontApp to activate
            
            -- Small delay to ensure app is focused
            delay 0.05
            
            -- Simulate Cmd+V to paste at live cursor position
            key code 9 using command down
            
            return true
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        let result = appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            print("[PasteManager] AppleScript error: \(error)")
            
            // More detailed error analysis
            if let errorNumber = error[NSAppleScript.errorNumber] as? Int {
                switch errorNumber {
                case -1743:
                    print("[PasteManager] ❌ Apple Events permission denied. Please grant permission in System Preferences > Privacy & Security > Automation")
                case -1740:
                    print("[PasteManager] ❌ Accessibility permission denied. Please grant permission in System Preferences > Privacy & Security > Accessibility")
                default:
                    print("[PasteManager] ❌ AppleScript error number: \(errorNumber)")
                }
            }
            
            return false
        }
        
        return result?.booleanValue ?? false
    }
    
    // MARK: - Alternative Methods (for debugging)
    func pasteWithDelay(_ text: String, delay: TimeInterval = 2, completion: @escaping (Bool) -> Void) {
        print("[PasteManager] Starting delayed paste operation")
        
        // Save original clipboard
        saveOriginalClipboard()
        
        // Copy to clipboard
        guard copyTextToClipboard(text) else {
            restoreOriginalClipboard()
            completion(false)
            return
        }
        
        // Wait for specified delay then paste
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            let success = self?.executePasteAppleScript() ?? false
            self?.restoreOriginalClipboard()
            completion(success)
        }
    }
    
    func testAccessibilityPermissions() -> Bool {
        let hasPermissions = checkAccessibilityPermissions()
        print("[PasteManager] Accessibility permissions: \(hasPermissions ? "✅ Granted" : "❌ Not granted")")
        
        // Also test Apple Events permission
        let appleEventsTest = testAppleEventsPermission()
        print("[PasteManager] Apple Events permissions: \(appleEventsTest ? "✅ Granted" : "❌ Not granted")")
        
        // If Apple Events not granted, try to trigger permission request
        if !appleEventsTest {
            print("[PasteManager] 🔄 Attempting to trigger Apple Events permission request...")
            triggerAppleEventsPermissionRequest()
        }
        
        return hasPermissions && appleEventsTest
    }
    
    private func triggerAppleEventsPermissionRequest() {
        // Try to trigger the permission request by attempting a simple AppleScript
        let script = """
        tell application "System Events"
            return "permission test"
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)
        
        // We expect this to fail, but it should trigger the permission dialog
        if let error = error {
            print("[PasteManager] Permission request triggered. Please check for a permission dialog.")
        }
    }
    
    private func testAppleEventsPermission() -> Bool {
        let script = """
        tell application "System Events"
            return "test"
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        let result = appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            print("[PasteManager] Apple Events test failed: \(error)")
            return false
        }
        
        return result?.stringValue == "test"
    }
} 