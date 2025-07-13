import SwiftUI
import Cocoa
import AVFoundation

@main
struct SpeechToTextApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Settings {
        //     SettingsView()
        // }
    }
}

struct ContentView: View {
    var body: some View {
        Text("Hello from Speech-to-Text App!")
            .font(.title)
            .fontWeight(.bold)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    private var statusItem: NSStatusItem?
    private var audioRecorder: AudioRecorder?
    private var hotkeyManager: HotkeyManager?
    private var pasteManager: PasteManager?
    // private var pythonBridge: PythonBridge?
    private var logger: Logger?
    
    private var isRecording = false
    
    // MARK: - App Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupComponents()
        setupMenuBar()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanup()
    }
    
    // MARK: - Setup
    private func setupComponents() {
        logger = Logger()
        audioRecorder = AudioRecorder()
        hotkeyManager = HotkeyManager()
        pasteManager = PasteManager()
        // pythonBridge = PythonBridge()
        
        // Set up hotkey callback
        hotkeyManager?.onHotkeyPressed = { [weak self] in
            self?.handleHotkeyPress()
        }
        
        logger?.log("App components initialized")
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "🎤"
            button.action = #selector(menuBarClicked)
            button.target = self
        }
        
        logger?.log("Menu bar setup complete")
    }
    
    // MARK: - Event Handlers
    @objc private func menuBarClicked() {
        logger?.log("Menu bar clicked!")
        showTestOptions()
    }
    
    private func showTestOptions() {
        let alert = NSAlert()
        alert.messageText = "Test Paste Functionality"
        alert.informativeText = "Choose which test to run:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Full Paste Test")
        alert.addButton(withTitle: "Clipboard Only Test")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            testPasteFunctionality()
        case .alertSecondButtonReturn:
            testClipboardOnly()
        default:
            break
        }
    }
    
    private func handleHotkeyPress() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        
        do {
            try audioRecorder?.startRecording()
            isRecording = true
            updateMenuBarIcon(recording: true)
            logger?.log("Recording started")
        } catch {
            logger?.logError(error, context: "Failed to start recording")
            showErrorAlert("Failed to start recording")
        }
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        guard let audioFileURL = audioRecorder?.stopRecording() else {
            logger?.log("Failed to get audio file", level: .error)
            return
        }
        
        isRecording = false
        updateMenuBarIcon(recording: false)
        logger?.log("Recording stopped - Audio saved to: \(audioFileURL.path)")
        
        // Process audio with Python
        // processAudioFile(audioFileURL)
    }
    
//     private func processAudioFile(_ audioFileURL: URL) {
//         pythonBridge?.transcribeAudio(audioFileURL) { [weak self] result in
//             DispatchQueue.main.async {
//                 switch result {
//                 case .success(let transcribedText):
//                     self?.handleTranscribedText(transcribedText)
//                 case .failure(let error):
//                     self?.logger?.log("Transcription failed: \(error.localizedDescription)", level: .error)
//                     self?.showErrorAlert("Transcription failed")
//                 }
//             }
//         }
//     }
    
//     private func handleTranscribedText(_ text: String) {
//         logger?.log("Transcribed text: \(text)")
        
//         // Paste the text at cursor position
//         pasteManager?.pasteText(text) { [weak self] success in
//             if success {
//                 self?.logger?.log("Text pasted successfully")
//             } else {
//                 self?.logger?.log("Failed to paste text", level: .error)
//                 self?.showErrorAlert("Failed to paste text")
//             }
//         }
//     }
    
    // MARK: - UI Updates
    private func updateMenuBarIcon(recording: Bool) {
        if let button = statusItem?.button {
            button.title = recording ? "🔴" : "🎤"
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Microphone Permission Required"
        alert.informativeText = "This app needs microphone access to record audio for transcription.\n\nTo enable microphone access:\n1. Open System Settings\n2. Go to Privacy & Security > Microphone\n3. Find 'Speech To Text App' in the list\n4. Toggle the switch to enable access\n\nAfter enabling, try recording again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings to Privacy & Security > Microphone
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // TESING - HARDCODED
    private func testPasteFunctionality() {
        let testText = "Hello from Speech-to-Text App! This is a test of the paste functionality. 🎤"
        
        logger?.log("Testing paste functionality with text: \(testText)")
        
        pasteManager?.pasteText(testText) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.logger?.log("✅ Text pasted successfully!")
                    self?.showSuccessAlert("Text pasted successfully!")
                } else {
                    self?.logger?.log("❌ Failed to paste text", level: .error)
                    self?.showErrorAlert("Failed to paste text")
                }
            }
        }
    }
    
    // Add clipboard-only test method
    private func testClipboardOnly() {
        let testText = "Hello from Speech-to-Text App! This is a clipboard-only test. 🎤"
        
        logger?.log("Testing clipboard-only functionality with text: \(testText)")
        
        // Save original clipboard content
        let originalContent = NSPasteboard.general.string(forType: .string)
        
        // Copy test text to clipboard
        NSPasteboard.general.clearContents()
        if NSPasteboard.general.setString(testText, forType: .string) {
            logger?.log("✅ Text copied to clipboard successfully!")
            showSuccessAlert("Text copied to clipboard! Press Cmd+V to paste it manually.")
            
            // Restore original clipboard after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if let original = originalContent {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(original, forType: .string)
                    self.logger?.log("✅ Original clipboard content restored")
                }
            }
        } else {
            logger?.log("❌ Failed to copy text to clipboard", level: .error)
            showErrorAlert("Failed to copy text to clipboard")
        }
    }
    
    private func showSuccessAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Success"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    // TESTING - END
    
    // MARK: - Cleanup
    private func cleanup() {
        if isRecording {
            audioRecorder?.stopRecording()
        }
        logger?.log("App terminating")
    }
}

#Preview {
    ContentView()
}
