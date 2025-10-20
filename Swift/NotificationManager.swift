import Foundation
import AppKit
import UserNotifications

class NotificationManager: ObservableObject {
    
    // MARK: - Properties
    private let logger = Logger(componentName: "NotificationManager")
    
    // MARK: - Initialization
    init() {
        logger.log("Initialized with sound-only notifications", level: .debug)
    }
    
    // MARK: - Public Methods
    func showAppInitializationSuccess() {
        DispatchQueue.main.async {
            self.logger.log("App initialization success", level: .debug)
            self.playAppStartSound()
        }
    }
    
    func showAppInitializationError(_ message: String) {
        DispatchQueue.main.async {
            self.logger.log("App initialization error: \(message)", level: .debug)
            self.playAppErrorSound()
        }
    }
    
    func showRecordingStarted() {
        DispatchQueue.main.async {
            self.logger.log("Recording started", level: .debug)
            self.playRecordingStartSound()
        }
    }
    
    func showRecordingStopped() {
        DispatchQueue.main.async {
            self.logger.log("Recording stopped", level: .debug)
            self.playRecordingStopSound()
        }
    }

    func showTranscriptionSuccess() {
        DispatchQueue.main.async {
            self.logger.log("Transcription success", level: .debug)
            self.playSuccessSound()
        }
    }
    
    func showTranscriptionError(_ message: String) {
        DispatchQueue.main.async {
            self.logger.log("Transcription error: \(message)", level: .debug)
            self.playErrorSound()
        }
    }
    
    // MARK: - Private Methods
    private func playAppStartSound() {
        if let sound = NSSound(named: "Ping") {
            sound.play()
            logger.log("Played 'Ping' success sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("'Ping' sound not found, using beep fallback", level: .debug)
        }
    }
    
    private func playAppErrorSound() {
        if let sound = NSSound(named: "Frog") {
            sound.play()
            logger.log("Played 'Frog' error sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("'Frog' sound not found, using beep fallback", level: .debug)
        }
    }
    
    private func playSuccessSound() {
        // Use system sound for success (for the transcribed text)
        if let sound = NSSound(named: "Submarine") {
            sound.play()
            logger.log("Played 'Submarine' success sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("'Submarine' sound not found, using beep fallback", level: .debug)
        }
    }
    
    private func playErrorSound() {
        // Use system sound for error (for the transcription error)
        if let sound = NSSound(named: "Sosumi") {
            sound.play()
            logger.log("Played 'Sosumi' error sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("'Sosumi' sound not found, using beep fallback", level: .debug)
        }
    }
    
    private func playRecordingStartSound() {
        // Subtle sound for recording start
        if let sound = NSSound(named: "Glass") {
            sound.play()
            logger.log("Played 'Glass' start sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("'Glass' sound not found, using beep fallback", level: .debug)
        }
    }
    
    private func playRecordingStopSound() {
        // Subtle sound for recording stop
        if let sound = NSSound(named: "Bottle") {
            sound.play()
            logger.log("Played 'Bottle' stop sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("'Bottle' sound not found, using beep fallback", level: .debug)
        }
    }
}