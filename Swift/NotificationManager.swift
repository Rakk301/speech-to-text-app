import Foundation
import AppKit
import UserNotifications

class NotificationManager: ObservableObject {
    
    // MARK: - Properties
    private let logger = Logger()
    
    // MARK: - Initialization
    init() {
        setupAudio()
        requestNotificationPermissions()
    }
    
    // MARK: - Public Methods
    func showTranscriptionSuccess() {
        DispatchQueue.main.async {
            self.playSuccessSound()
            self.showSuccessNotification()
        }
    }
    
    func showTranscriptionError(_ message: String) {
        DispatchQueue.main.async {
            self.playErrorSound()
            self.showErrorNotification(message)
        }
    }
    
    func showRecordingStarted() {
        DispatchQueue.main.async {
            self.playStartSound()
        }
    }
    
    func showRecordingStopped() {
        DispatchQueue.main.async {
            self.playStopSound()
        }
    }
    
    // MARK: - Private Methods
    private func setupAudio() {
        // No audio session setup needed on macOS - NSSound handles this automatically
        logger.log("Audio setup complete for notifications", level: .debug)
    }
    
    private func playSuccessSound() {
        // Use system sound for success
        NSSound.beep()
        logger.log("Played success notification sound", level: .debug)
    }
    
    private func playErrorSound() {
        // Use system sound for error
        if let sound = NSSound(named: "Funk") {
            sound.play()
        } else {
            NSSound.beep()
        }
        logger.log("Played error notification sound", level: .debug)
    }
    
    private func playStartSound() {
        // Subtle sound for recording start
        if let sound = NSSound(named: "Glass") {
            sound.play()
        }
        logger.log("Played recording start sound", level: .debug)
    }
    
    private func playStopSound() {
        // Subtle sound for recording stop
        if let sound = NSSound(named: "Tink") {
            sound.play()
        }
        logger.log("Played recording stop sound", level: .debug)
    }
    
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.logger.logError(error, context: "Failed to request notification permissions")
                } else if granted {
                    self.logger.log("Notification permissions granted", level: .info)
                } else {
                    self.logger.log("Notification permissions denied - will use sound only", level: .warning)
                }
            }
        }
    }
    
    private func showSuccessNotification() {
        // Check if we have permission first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                self.logger.log("Notifications not authorized - skipping banner", level: .debug)
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
                    self.logger.logError(error, context: "Failed to show success notification")
                } else {
                    self.logger.log("Showed success notification", level: .debug)
                }
            }
        }
    }
    
    private func showErrorNotification(_ message: String) {
        // Check if we have permission first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                self.logger.log("Notifications not authorized - skipping error banner", level: .debug)
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
                    self.logger.logError(error, context: "Failed to show error notification")
                } else {
                    self.logger.log("Showed error notification: \(message)", level: .debug)
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