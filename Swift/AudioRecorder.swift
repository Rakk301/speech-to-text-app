import AVFoundation
import Foundation

enum AudioRecorderError: Error, LocalizedError {
    case audioSessionFailed
    case recordingFailed
    case fileCreationFailed
    
    var errorDescription: String? {
        switch self {
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
    private var logger: Logger?
    
    // MARK: - Initialization
    init() {
        inputNode = audioEngine.inputNode
        logger = Logger()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// Start recording - macOS will automatically request microphone permission if needed
    func startRecording() throws {
        logger?.log("Starting audio recording", level: .info)
        
        // Create temporary audio file
        recordingURL = createTemporaryAudioFile()
        guard let url = recordingURL else {
            logger?.log("Failed to create temporary audio file", level: .error)
            throw AudioRecorderError.fileCreationFailed
        }
        
        logger?.log("Recording to: \(url.path)", level: .debug)
        
        // Get the native format from the input node
        let format = inputNode.inputFormat(forBus: 0)
        logger?.log("Using audio format: \(format)", level: .debug)
        
        // Create audio file
        do {
            audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        } catch {
            logger?.log("Failed to create audio file: \(error.localizedDescription)", level: .error)
            throw AudioRecorderError.fileCreationFailed
        }
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.handleAudioBuffer(buffer)
        }
        
        // Start audio engine - this will trigger permission request if needed
        do {
            try audioEngine.start()
            logger?.log("Audio recording started successfully", level: .info)
        } catch {
            inputNode.removeTap(onBus: 0)
            logger?.log("Audio engine start failed: \(error.localizedDescription)", level: .error)
            throw AudioRecorderError.recordingFailed
        }
    }
    
    func stopRecording() -> URL? {
        guard audioEngine.isRunning else { return nil }
        
        logger?.log("Stopping audio recording", level: .info)
        
        // Stop audio engine
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        
        // Close audio file
        audioFile = nil
        
        // Return the recorded file URL
        let url = recordingURL
        recordingURL = nil
        
        if let url = url {
            
            // Check file size
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: url.path) {
                let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                let fileSize = attributes?[.size] as? Int64 ?? 0
                logger?.log("Audio file size: \(fileSize) bytes", level: .debug)
            }
        }
        
        return url
    }
    
    // MARK: - Private Methods
    
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
            logger?.log("Failed to write audio buffer: \(error.localizedDescription)", level: .error)
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