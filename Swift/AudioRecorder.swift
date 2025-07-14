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
    
    // MARK: - Initialization
    init() {
        inputNode = audioEngine.inputNode
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// Start recording - macOS will automatically request microphone permission if needed
    func startRecording() throws {
        print("🎤 Starting recording...")
        
        // Create temporary audio file
        recordingURL = createTemporaryAudioFile()
        guard let url = recordingURL else {
            throw AudioRecorderError.fileCreationFailed
        }
        
        print("💾 Recording to: \(url.path)")
        
        // Get the native format from the input node
        let format = inputNode.inputFormat(forBus: 0)
        print("📊 Using format: \(format)")
        
        // Create audio file
        do {
            audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        } catch {
            throw AudioRecorderError.fileCreationFailed
        }
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.handleAudioBuffer(buffer)
        }
        
        // Start audio engine - this will trigger permission request if needed
        do {
            try audioEngine.start()
            print("✅ Recording started successfully")
        } catch {
            inputNode.removeTap(onBus: 0)
            print("❌ Audio engine start failed: \(error)")
            throw AudioRecorderError.recordingFailed
        }
    }
    
    func stopRecording() -> URL? {
        guard audioEngine.isRunning else { return nil }
        
        print("🛑 Stopping recording...")
        
        // Stop audio engine
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        
        // Close audio file
        audioFile = nil
        
        // Return the recorded file URL
        let url = recordingURL
        recordingURL = nil
        
        if let url = url {
            print("✅ Recording completed: \(url.path)")
            
            // Check file size
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: url.path) {
                let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                let fileSize = attributes?[.size] as? Int64 ?? 0
                print("📁 File size: \(fileSize) bytes")
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
            print("❌ Failed to write audio buffer: \(error)")
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