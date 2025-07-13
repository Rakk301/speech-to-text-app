import AVFoundation
import Foundation

enum AudioRecorderError: Error, LocalizedError {
    case permissionDenied
    case audioSessionFailed
    case recordingFailed
    case fileCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required"
        case .audioSessionFailed:
            return "Failed to configure audio session"
        case .recordingFailed:
            return "Failed to start recording"
        case .fileCreationFailed:
            return "Failed to create audio file"
        }
    }
}

class AudioRecorder {
    
    // MARK: - Properties
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    
    // Whisper-compatible audio settings
    private let sampleRate: Double = 16000
    private let channels: AVAudioChannelCount = 1
    private let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
    
    // MARK: - Initialization
    init() {
        inputNode = audioEngine.inputNode
        setupAudioSession()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    func startRecording() throws {
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            throw AudioRecorderError.permissionDenied
        }
        
        // Create temporary audio file
        recordingURL = createTemporaryAudioFile()
        guard let url = recordingURL else {
            throw AudioRecorderError.fileCreationFailed
        }
        
        do {
            audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        } catch {
            throw AudioRecorderError.fileCreationFailed
        }
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.handleAudioBuffer(buffer)
        }
        
        // Start audio engine
        do {
            try audioEngine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            throw AudioRecorderError.recordingFailed
        }
    }
    
    func stopRecording() -> URL? {
        guard audioEngine.isRunning else { return nil }
        
        // Stop audio engine
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        
        // Close audio file
        audioFile = nil
        
        // Return the recorded file URL
        let url = recordingURL
        recordingURL = nil
        return url
    }
    
    // MARK: - Private Methods
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func createTemporaryAudioFile() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "recording_\(timestamp).wav"
        return tempDir.appendingPathComponent(filename)
    }
    
    private func handleAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let audioFile = audioFile else { return }
        
        do {
            try audioFile.write(from: buffer)
        } catch {
            print("Failed to write audio buffer: \(error)")
        }
    }
    
    private func cleanup() {
        if audioEngine.isRunning {
            audioEngine.stop()
            inputNode.removeTap(onBus: 0)
        }
        audioFile = nil
        recordingURL = nil
    }
} 