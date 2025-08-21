import Foundation
import AppKit
import UserNotifications

class NotificationManager: ObservableObject {
    
    // MARK: - Properties
    private let logger = Logger()
    
    // MARK: - Initialization
    init() {
        logger.log("[NotificationManager] Initialized with sound-only notifications", level: .debug)
    }
    
    // MARK: - Public Methods
    func showAppInitializationSuccess() {
        DispatchQueue.main.async {
            self.logger.log("[NotificationManager] showAppInitializationSuccess called", level: .debug)
            self.playAppStartSound()
        }
    }
    
    func showAppInitializationError(_ message: String) {
        DispatchQueue.main.async {
            self.logger.log("[NotificationManager] showAppInitializationError called: \(message)", level: .debug)
            self.playAppErrorSound()
        }
    }
    
    func showRecordingStarted() {
        DispatchQueue.main.async {
            self.logger.log("[NotificationManager] showRecordingStarted called", level: .debug)
            self.playRecordingStartSound()
        }
    }
    
    func showRecordingStopped() {
        DispatchQueue.main.async {
            self.logger.log("[NotificationManager] showRecordingStopped called", level: .debug)
            self.playRecordingStopSound()
        }
    }

    func showTranscriptionSuccess() {
        DispatchQueue.main.async {
            self.logger.log("[NotificationManager] showTranscriptionSuccess called", level: .debug)
            self.playSuccessSound()
        }
    }
    
    func showTranscriptionError(_ message: String) {
        DispatchQueue.main.async {
            self.logger.log("[NotificationManager] showTranscriptionError called: \(message)", level: .debug)
            self.playErrorSound()
        }
    }
    
    // MARK: - Private Methods
    private func playAppStartSound() {
        if let sound = NSSound(named: "Ping") {
            sound.play()
            logger.log("[NotificationManager] Played 'Ping' success sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("[NotificationManager] 'Ping' sound not found, using beep fallback", level: .debug)
        }
    }
    
    private func playAppErrorSound() {
        if let sound = NSSound(named: "Frog") {
            sound.play()
            logger.log("[NotificationManager] Played 'Frog' error sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("[NotificationManager] 'Frog' sound not found, using beep fallback", level: .debug)
        }
    }
    
    private func playSuccessSound() {
        // Use system sound for success (for the transcribed text)
        if let sound = NSSound(named: "Submarine") {
            sound.play()
            logger.log("[NotificationManager] Played 'Submarine' success sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("[NotificationManager] 'Submarine' sound not found, using beep fallback", level: .debug)
        }
    }
    
    private func playErrorSound() {
        // Use system sound for error (for the transcription error)
        if let sound = NSSound(named: "Sosumi") {
            sound.play()
            logger.log("[NotificationManager] Played 'Sosumi' error sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("[NotificationManager] 'Sosumi' sound not found, using beep fallback", level: .debug)
        }
    }
    
    private func playRecordingStartSound() {
        // Subtle sound for recording start
        if let sound = NSSound(named: "Glass") {
            sound.play()
            logger.log("[NotificationManager] Played 'Glass' start sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("[NotificationManager] 'Glass' sound not found, using beep fallback", level: .debug)
        }
    }
    
    private func playRecordingStopSound() {
        // Subtle sound for recording stop
        if let sound = NSSound(named: "Pop") {
            sound.play()
            logger.log("[NotificationManager] Played 'Pop' stop sound", level: .debug)
        } else {
            NSSound.beep()
            logger.log("[NotificationManager] 'Pop' sound not found, using beep fallback", level: .debug)
        }
    }
}