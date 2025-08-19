import Foundation
import AVFoundation
import ApplicationServices
import AppKit

class PermissionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var microphonePermissionStatus: PermissionStatus = .notDetermined
    @Published var accessibilityPermissionStatus: PermissionStatus = .notDetermined
    
    private let logger = Logger()
    
    // MARK: - Permission Status Enum
    enum PermissionStatus {
        case notDetermined
        case denied
        case authorized
        case restricted
        
        var displayText: String {
            switch self {
            case .notDetermined:
                return "Not Requested"
            case .denied:
                return "Denied"
            case .authorized:
                return "Authorized"
            case .restricted:
                return "Restricted"
            }
        }
        
        var color: NSColor {
            switch self {
            case .notDetermined:
                return .systemOrange
            case .denied, .restricted:
                return .systemRed
            case .authorized:
                return .systemGreen
            }
        }
        
        var icon: String {
            switch self {
            case .notDetermined:
                return "questionmark.circle.fill"
            case .denied, .restricted:
                return "xmark.circle.fill"
            case .authorized:
                return "checkmark.circle.fill"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        checkAllPermissions()
    }
    
    // MARK: - Public Methods
    func checkAllPermissions() {
        checkMicrophonePermission()
        checkAccessibilityPermission()
    }
    
    func requestMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            DispatchQueue.main.async {
                self.microphonePermissionStatus = granted ? .authorized : .denied
            }
            logger.log("Microphone permission requested, granted: \(granted)", level: .info)
            return granted
            
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.microphonePermissionStatus = status == .denied ? .denied : .restricted
            }
            logger.log("Microphone permission denied or restricted", level: .warning)
            return false
            
        case .authorized:
            DispatchQueue.main.async {
                self.microphonePermissionStatus = .authorized
            }
            return true
            
        @unknown default:
            DispatchQueue.main.async {
                self.microphonePermissionStatus = .denied
            }
            return false
        }
    }
    
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        DispatchQueue.main.async {
            self.accessibilityPermissionStatus = trusted ? .authorized : .denied
        }
        
        logger.log("Accessibility permission requested, trusted: \(trusted)", level: .info)
    }
    

    
    func openSystemPreferences(for permission: PermissionType) {
        switch permission {
        case .microphone:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        case .accessibility:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    func canTogglePermission(_ permission: PermissionType) -> Bool {
        switch permission {
        case .microphone:
            // Can request microphone if not determined, otherwise need to go to settings
            return microphonePermissionStatus == .notDetermined
        case .accessibility:
            // Can always request accessibility permission (opens System Preferences)
            return true
        }
    }
    
    func getActionText(for permission: PermissionType) -> String {
        switch permission {
        case .microphone:
            switch microphonePermissionStatus {
            case .notDetermined:
                return "Grant"
            case .denied, .restricted:
                return "Open Settings"
            case .authorized:
                return "Granted"
            }
        case .accessibility:
            switch accessibilityPermissionStatus {
            case .authorized:
                return "Open Settings"
            case .denied, .notDetermined, .restricted:
                return "Grant"
            }
        }
    }
    
    // MARK: - Private Methods
    private func checkMicrophonePermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        DispatchQueue.main.async {
            switch status {
            case .notDetermined:
                self.microphonePermissionStatus = .notDetermined
            case .denied:
                self.microphonePermissionStatus = .denied
            case .restricted:
                self.microphonePermissionStatus = .restricted
            case .authorized:
                self.microphonePermissionStatus = .authorized
            @unknown default:
                self.microphonePermissionStatus = .denied
            }
        }
    }
    
    private func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        
        DispatchQueue.main.async {
            self.accessibilityPermissionStatus = trusted ? .authorized : .denied
        }
    }
    

}

// MARK: - Permission Type Enum
enum PermissionType {
    case microphone
    case accessibility
    
    var displayName: String {
        switch self {
        case .microphone:
            return "Microphone"
        case .accessibility:
            return "Accessibility"
        }
    }
    
    var description: String {
        switch self {
        case .microphone:
            return "Required for speech recording"
        case .accessibility:
            return "Required for global hotkeys and paste-at-cursor"
        }
    }
}
