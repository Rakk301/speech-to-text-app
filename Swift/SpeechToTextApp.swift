import Cocoa
import AVFoundation

@main
class SpeechToTextApp: NSObject, NSApplicationDelegate {
    
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
        requestPermissions()
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
        pythonBridge = PythonBridge()
        
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
    
    private func requestPermissions() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.logger?.log("Microphone permission granted")
                } else {
                    self?.logger?.log("Microphone permission denied", level: .error)
                    self?.showPermissionAlert()
                }
            }
        }
    }
    
    // MARK: - Event Handlers
    @objc private func menuBarClicked() {
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
            logger?.log("Recording started")
        } catch {
            logger?.log("Failed to start recording: \(error.localizedDescription)", level: .error)
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
        logger?.log("Recording stopped")
        
        // Process audio with Python
        processAudioFile(audioFileURL)
    }
    
    private func processAudioFile(_ audioFileURL: URL) {
        pythonBridge?.transcribeAudio(audioFileURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcribedText):
                    self?.handleTranscribedText(transcribedText)
                case .failure(let error):
                    self?.logger?.log("Transcription failed: \(error.localizedDescription)", level: .error)
                    self?.showErrorAlert("Transcription failed")
                }
            }
        }
    }
    
    private func handleTranscribedText(_ text: String) {
        logger?.log("Transcribed text: \(text)")
        
        // Paste the text at cursor position
        pasteManager?.pasteText(text) { [weak self] success in
            if success {
                self?.logger?.log("Text pasted successfully")
            } else {
                self?.logger?.log("Failed to paste text", level: .error)
                self?.showErrorAlert("Failed to paste text")
            }
        }
    }
    
    // MARK: - UI Updates
    private func updateMenuBarIcon(recording: Bool) {
        if let button = statusItem?.button {
            button.title = recording ? "🔴" : "🎤"
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Microphone Permission Required"
        alert.informativeText = "This app needs microphone access to record audio for transcription. Please enable it in System Preferences > Security & Privacy > Privacy > Microphone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        if isRecording {
            audioRecorder?.stopRecording()
        }
        logger?.log("App terminating")
    }
} 