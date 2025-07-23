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
    private var pythonBridge: PythonBridge?
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
        logger?.log("=== Initializing App Setup ===", level: .debug)
        audioRecorder = AudioRecorder()
        hotkeyManager = HotkeyManager()
        pasteManager = PasteManager()
        pythonBridge = PythonBridge()
        logger?.log("PythonBridge component initialized", level: .debug)
        
        // Set up hotkey callback
        hotkeyManager?.onHotkeyPressed = { [weak self] in
            self?.handleHotkeyPress()
        }
        
        logger?.log("App Components Initialized", level: .debug)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "🎤"
            button.action = #selector(menuBarClicked)
            button.target = self
        }
        
        logger?.log("Menu Bar Setup Complete", level: .debug)
        logger?.log("=== App Setup Complete ===", level: .debug)
    }
    
    // MARK: - Event Handlers
    @objc private func menuBarClicked() {
        logger?.log("Menu bar clicked!")
        handleHotkeyPress()
    }
    
    private func handleHotkeyPress() {
        if isRecording {
            logger?.log("Stopping recording...", level: .info)
            stopRecording()
        } else {
            logger?.log("Starting recording...", level: .info)
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
        logger?.log("Audio file successfully saved to: \(audioFileURL.path)", level: .debug)
        
        // Process the audio file with Python
        processAudioFile(audioFileURL)
    }
    
    private func processAudioFile(_ audioFileURL: URL) {
        logger?.log("Starting audio file processing for: \(audioFileURL.path)", level: .info)
        
        pythonBridge?.transcribeAudio(audioFileURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcribedText):
                    self?.logger?.log("Transcription completed successfully", level: .info)
                    self?.handleTranscribedText(transcribedText)
                case .failure(let error):
                    self?.logger?.logError(error, context: "Transcription failed")
                    self?.logger?.log("Transcription failed with error: \(error.localizedDescription)", level: .error)
                    // self?.showErrorAlert("Transcription failed: \(error.localizedDescription)")
                }
            }
        }
    }
    

    private func handleTranscribedText(_ text: String) {
        
        logger?.log("Testing clipboard-only functionality with text: \(text)")
        
        // Save original clipboard content
        let originalContent = NSPasteboard.general.string(forType: .string)
        
        // Copy test text to clipboard
        NSPasteboard.general.clearContents()
        if NSPasteboard.general.setString(text, forType: .string) {
            logger?.log("✅ Text copied to clipboard successfully!")
            // showSuccessAlert("Text copied to clipboard! Press Cmd+V to paste it manually.")
            
            // Restore original clipboard after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                if let original = originalContent {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(original, forType: .string)
                    self.logger?.log("✅ Original clipboard content restored")
                }
            }
        } else {
            logger?.log("❌ Failed to copy text to clipboard", level: .error)
            // showErrorAlert("Failed to copy text to clipboard")
        }
    }

    // // MARK: - Text Processing
    // private func handleTranscribedText(_ text: String) {
    //     logger?.log("Handling transcribed text: \(text)", level: .info)
        
    //     // Paste the transcribed text at the cursor
    //     pasteManager?.pasteText(text) { [weak self] success in
    //         DispatchQueue.main.async {
    //             if success {
    //                 self?.logger?.log("Text pasted successfully", level: .info)
    //                 // self?.showSuccessNotification("Text transcribed and pasted!")
    //             } else {
    //                 self?.logger?.log("Failed to paste text", level: .error)
    //                 // self?.showErrorAlert("Failed to paste text")
    //             }
    //         }
    //     }
    // }
    
    // MARK: - UI Updates
    private func updateMenuBarIcon(recording: Bool) {
        if let button = statusItem?.button {
            button.title = recording ? "🔴" : "🎤"
        }
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        if isRecording {
            _ = audioRecorder?.stopRecording()
        }
        logger?.log("App terminating")
    }
}

#Preview {
    ContentView()
}
