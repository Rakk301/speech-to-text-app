import Foundation
import AppKit
import UserNotifications

class NotificationManager: ObservableObject {
    
    // MARK: - Properties
    private let logger = Logger()
    
    // MARK: - Initialization
    init() {
        requestNotificationPermissions()
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
    
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.logger.logError(error, context: "[NotificationManager] Failed to request notification permissions")
                } else if granted {
                    self.logger.log("[NotificationManager] Notification permissions granted", level: .info)
                } else {
                    self.logger.log("[NotificationManager] Notification permissions denied - will use sound only", level: .warning)
                }
            }
        }
    }
    
    private func showSuccessNotification() {
        // Check if we have permission first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                self.logger.log("[NotificationManager] Notifications not authorized - skipping banner", level: .debug)
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Transcription Complete"
            content.body = "Text has been copied to clipboard"
            content.sound = nil // We're handling sound separately
            
            let request = UNNotificationRequest(
                identifier: "transcription-success",
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    self.logger.logError(error, context: "[NotificationManager] Failed to show success notification")
                } else {
                    self.logger.log("[NotificationManager] Showed success notification", level: .debug)
                }
            }
        }
    }
    
    private func showErrorNotification(_ message: String) {
        // Check if we have permission first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                self.logger.log("[NotificationManager] Notifications not authorized - skipping error banner", level: .debug)
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Transcription Failed"
            content.body = message
            content.sound = nil // We're handling sound separately
            
            let request = UNNotificationRequest(
                identifier: "transcription-error",
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    self.logger.logError(error, context: "[NotificationManager] Failed to show error notification")
                } else {
                    self.logger.log("[NotificationManager] Showed error notification: \(message)", level: .debug)
                }
            }
        }
    }
    
    // MARK: - Visual Feedback
    func showTemporaryBanner(_ message: String, isSuccess: Bool = true) {
        DispatchQueue.main.async {
            // Create a temporary overlay window for visual feedback
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 60),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            window.backgroundColor = isSuccess ? NSColor.systemGreen.withAlphaComponent(0.9) : NSColor.systemRed.withAlphaComponent(0.9)
            window.level = .floating
            window.isOpaque = false
            window.hasShadow = true
            window.ignoresMouseEvents = true
            
            // Center the window on screen
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowFrame = window.frame
                let x = screenFrame.midX - windowFrame.width / 2
                let y = screenFrame.maxY - 100 // Near top of screen
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            // Create label
            let label = NSTextField(labelWithString: message)
            label.textColor = .white
            label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
            label.alignment = .center
            label.frame = NSRect(x: 10, y: 20, width: 280, height: 20)
            
            window.contentView?.addSubview(label)
            window.orderFront(nil)
            
            // Auto-hide after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                window.orderOut(nil)
            }
        }
    }
}