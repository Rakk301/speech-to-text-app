import SwiftUI
import Cocoa
import AVFoundation

@main
struct SpeechToTextApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Menu bar app
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    
    // MARK: - Properties
    private var statusItem: NSStatusItem?
    private var audioRecorder: AudioRecorder?
    private var hotkeyManager: HotkeyManager?
    private var pasteManager: PasteManager?
    private var transcriptionClient: TranscriptionServerClient?
    private var serverManager: ServerManager?
    private var logger: Logger?
    private var settingsManager: SettingsManager?
    private var historyManager: HistoryManager?
    private var notificationManager: NotificationManager?
    private var folderAccessManager: FolderAccessManager?
    private var menuBarView: MenuBarView?
    private var popover: NSPopover?
    private var menuBarIconManager: MenuBarIconManager?
    
    private var isRecording = false
    
    // MARK: - App Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure as menu bar app - hide from dock and cmd+tab
        NSApp.setActivationPolicy(.accessory)
        
        setupComponents()
        setupMenuBar()
        startTranscriptionServer()
        logger?.log("=== App Setup Complete ===", level: .info)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanup()
    }
    
    // MARK: - Setup
    private func setupComponents() {
        logger = Logger()
        logger?.log("=== Initializing App Setup ===", level: .debug)
        
        // Initialize managers
        settingsManager = SettingsManager()
        historyManager = HistoryManager()
        notificationManager = NotificationManager()
        folderAccessManager = FolderAccessManager()
        
        // Initialize core components
        audioRecorder = AudioRecorder()
        
        guard let settingsManager = settingsManager,
              let folderAccessManager = folderAccessManager else {
            logger?.log("Failed to initialize required managers", level: .error)
            return
        }
        
        hotkeyManager = HotkeyManager(settingsManager: settingsManager)
        pasteManager = PasteManager()
        transcriptionClient = TranscriptionServerClient(settingsManager: settingsManager)
        serverManager = ServerManager(settingsManager: settingsManager, folderAccessManager: folderAccessManager)
        logger?.log("TranscriptionServerClient component initialized", level: .debug)
        
        // Set up hotkey callback
        hotkeyManager?.onHotkeyPressed = { [weak self] in
            self?.handleHotkeyPress()
        }
        
        // Initialize menu bar view
        menuBarView = MenuBarView()
        menuBarView?.onStartRecording = { [weak self] in
            self?.startRecording()
        }
        menuBarView?.onStopRecording = { [weak self] in
            self?.stopRecording()
        }
        menuBarView?.onSettingsChanged = { [weak self] in
            self?.handleSettingsChanged()
        }
        
        logger?.log("App Components Initialized", level: .debug)
    }
    
    private func startTranscriptionServer() {
        serverManager?.startServer { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.logger?.log("Transcription server started successfully", level: .info)
                    self?.notificationManager?.showAppInitializationSuccess()
                    self?.menuBarIconManager?.playStartupAnimation()
                } else {
                    self?.logger?.log("Failed to start transcription server", level: .error)
                    self?.notificationManager?.showAppInitializationError("Failed to start transcription server")
                    self?.menuBarIconManager?.showErrorState()
                }
            }
        }
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.imagePosition = .imageLeft
            button.action = #selector(menuBarClicked)
            button.target = self
        }
        
        // Initialize the menu bar icon manager
        menuBarIconManager = MenuBarIconManager(statusItem: statusItem!)
        
        // Setup popover for menu with our custom MenuBarView
        setupPopover()
    }
    
    private func setupPopover() {
        guard let menuBarView = menuBarView else {
            logger?.log("Error: menuBarView is nil during popover setup", level: .error)
            return
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 450)
        popover?.behavior = .transient  // Auto-dismisses when losing focus
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: menuBarView)
        
        // Set up popover delegate for additional menu-bar behavior
        popover?.delegate = self
        
        logger?.log("MenuBarView setup complete", level: .debug)
    }
    
    // MARK: - Event Handlers
    @objc private func menuBarClicked() {
        logger?.log("Menu bar clicked!")
        
        guard let button = statusItem?.button else { return }
        
        if popover?.isShown == true {
            popover?.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
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
            menuBarView?.updateRecordingState(true)
            
            // Hide our icon and let Apple's native recording indicator show
            menuBarIconManager?.setRecordingState()
            
            notificationManager?.showRecordingStarted()
            logger?.log("Recording started")
        } catch {
            logger?.logError(error, context: "Failed to start recording")
            notificationManager?.showTranscriptionError("Failed to start recording")
            menuBarIconManager?.showErrorState()
        }
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        guard let audioFileURL = audioRecorder?.stopRecording() else {
            logger?.log("Failed to get audio file", level: .error)
            notificationManager?.showTranscriptionError("Failed to save audio file")
            menuBarIconManager?.showErrorState()
            return
        }
        
        isRecording = false
        menuBarView?.updateRecordingState(false)
        notificationManager?.showRecordingStopped()
        logger?.log("Audio file successfully saved to: \(audioFileURL.path)", level: .debug)
        menuBarIconManager?.setProcessingState()
        
        // Process the audio file with Python
        processAudioFile(audioFileURL)
    }
    
    private func processAudioFile(_ audioFileURL: URL) {
        logger?.log("Starting audio file processing for: \(audioFileURL.path)", level: .info)
        
        transcriptionClient?.transcribeAudio(audioFileURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transcribedText):
                    self?.logger?.log("Transcription completed successfully", level: .info)
                    self?.handleTranscribedText(transcribedText, audioFileName: audioFileURL.lastPathComponent)
                case .failure(let error):
                    self?.logger?.logError(error, context: "Transcription failed")
                    self?.logger?.log("Transcription failed with error: \(error.localizedDescription)", level: .error)
                    self?.notificationManager?.showTranscriptionError("Transcription failed: \(error.localizedDescription)")
                    self?.menuBarIconManager?.showErrorState()
                }
            }
        }
    }
    
    private func handleTranscribedText(_ text: String, audioFileName: String? = nil) {
        logger?.log("Handling transcribed text: \(text)", level: .info)
        
        // Add to history
        historyManager?.addTranscription(text, audioFileName: audioFileName)
        menuBarView?.addTranscription(text, audioFileName: audioFileName)
        
        // Paste the transcribed text at cursor
        pasteManager?.pasteText(text) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.logger?.log("Text pasted at cursor successfully", level: .info)
                    self?.notificationManager?.showTranscriptionSuccess()
                    self?.menuBarIconManager?.showSuccessState()
                } else {
                    self?.logger?.log("Failed to paste text at cursor", level: .error)
                    self?.notificationManager?.showTranscriptionError("Failed to paste text at cursor")
                    self?.menuBarIconManager?.showErrorState()
                }
            }
        }
    }
    
    // MARK: - Settings Handler
    private func handleSettingsChanged() {
        logger?.log("Settings changed, reloading configuration", level: .info)
        // Reload settings and update components as needed
        settingsManager?.loadSettings()
        
        // Refresh hotkey manager with new configuration
        hotkeyManager?.refreshHotkeyConfiguration()
        
        // Restart server if Whisper settings changed (to pick up new model/language)
        serverManager?.stopServer()
        startTranscriptionServer()
    }
        
    // MARK: - Cleanup
    private func cleanup() {
        if isRecording {
            _ = audioRecorder?.stopRecording()
        }
        serverManager?.stopServer()
        popover?.performClose(nil)
        logger?.log("App terminating")
    }
}
