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
    // private var hotkeyManager: HotkeyManager?
    // private var pasteManager: PasteManager?
    // private var pythonBridge: PythonBridge?
    // private var logger: Logger?
    
    private var isRecording = false
    
    // MARK: - App Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupComponents()
        setupMenuBar()
        requestPermissions()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // cleanup()
    }
    
    // MARK: - Setup
    private func setupComponents() {
        // logger = Logger()
        audioRecorder = AudioRecorder()
        // hotkeyManager = HotkeyManager()
        // pasteManager = PasteManager()
        // pythonBridge = PythonBridge()
        
        // // Set up hotkey callback
        // hotkeyManager?.onHotkeyPressed = { [weak self] in
        //     self?.handleHotkeyPress()
        // }
        
        print("App components initialized")
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "🎤"
            button.action = #selector(menuBarClicked)
            button.target = self
        }
        
        print("Menu bar setup complete")
    }
    
    private func requestPermissions() {
        // On macOS, microphone permissions are handled automatically by the system
        // The user will be prompted when the app first tries to record
        print("Microphone permissions will be requested when recording starts")
    }
    
    // MARK: - Event Handlers
    @objc private func menuBarClicked() {
        print("Menu bar clicked!")
        handleHotkeyPress()
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
            print("Recording started")
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
            showErrorAlert("Failed to start recording")
        }
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        guard let audioFileURL = audioRecorder?.stopRecording() else {
            print("Failed to get audio file")
            return
        }
        
        isRecording = false
        updateMenuBarIcon(recording: false)
        print("Recording stopped - Audio saved to: \(audioFileURL.path)")
        
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
    
    // MARK: - Test Methods
    private func showTestAlert() {
        let alert = NSAlert()
        alert.messageText = "Menu Bar Working!"
        alert.informativeText = "The menu bar integration is working correctly. Ready for the next step!"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Great!")
        alert.runModal()
    }
    
    //     // MARK: - Cleanup
    //     private func cleanup() {
    //         if isRecording {
    //             audioRecorder?.stopRecording()
    //         }
    //         logger?.log("App terminating")
    //     }
}

#Preview {
    ContentView()
}
