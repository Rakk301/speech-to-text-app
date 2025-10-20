import Foundation
import AppKit
import QuartzCore

enum MenuBarIconState {
    case startup
    case ready
    case recording
    case processing
    case success
    case error
    case hidden
}

class MenuBarIconManager: ObservableObject {
    
    // MARK: - Properties
    private let logger = Logger()
    private weak var statusItem: NSStatusItem?
    private var currentState: MenuBarIconState = .startup
    
    // MARK: - Initialization
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        logger.log("[MenuBarIconManager] Initialized", level: .debug)
    }
    
    // MARK: - Public Methods
    
    /// Play the startup animation sequence
    func playStartupAnimation() {
        logger.log("[MenuBarIconManager] Playing startup animation", level: .debug)
        
        guard let button = statusItem?.button else {
            logger.log("[MenuBarIconManager] Status item button not available", level: .error)
            return
        }
        
        // Start invisible
        button.alphaValue = 0.0
        currentState = .startup
        
        // Sequence: invisible → mic → mic.fill → mic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.transitionToIcon("mic", withAnimation: false)
            self.fadeInIcon()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.transitionToIcon("mic.fill", withAnimation: false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.transitionToIcon("mic", withAnimation: false)
            self.currentState = .ready
        }
    }
    
    /// Transition to ready state (default mic icon)
    func setReadyState() {
        logger.log("[MenuBarIconManager] Setting ready state", level: .debug)
        transitionToIcon("mic", withAnimation: true)
        currentState = .ready
    }
    
    /// Transition to recording state and hide icon (let Apple's native indicator show)
    func setRecordingState() {
        logger.log("[MenuBarIconManager] Setting recording state - hiding icon", level: .debug)
        fadeOutIcon {
            self.currentState = .recording
        }
    }
    
    /// Show processing state after recording stops
    func setProcessingState() {
        logger.log("[MenuBarIconManager] Setting processing state", level: .debug)
        transitionToIcon("clock", withAnimation: true)
        currentState = .processing
    }
    
    /// Show success state briefly
    func showSuccessState() {
        logger.log("[MenuBarIconManager] Showing success state", level: .debug)
        transitionToIcon("checkmark.circle.fill", withAnimation: true)
        currentState = .success
        
        // Return to ready state after brief flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.setReadyState()
        }
    }
    
    /// Show error state briefly
    func showErrorState() {
        logger.log("[MenuBarIconManager] Showing error state", level: .debug)
        transitionToIcon("exclamationmark.triangle.fill", withAnimation: true)
        currentState = .error
        
        // Return to ready state after brief flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.setReadyState()
        }
    }
    
    /// Hide the icon completely
    func hideIcon() {
        logger.log("[MenuBarIconManager] Hiding icon", level: .debug)
        fadeOutIcon {
            self.currentState = .hidden
        }
    }
    
    /// Show the icon if it was hidden
    func showIcon() {
        if currentState == .hidden {
            logger.log("[MenuBarIconManager] Showing hidden icon", level: .debug)
            fadeInIcon()
            setReadyState()
        }
    }
    
    // MARK: - Private Methods
    
    private func transitionToIcon(_ iconName: String, withAnimation: Bool = true) {
        guard let button = statusItem?.button else { return }
        
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let newImage = NSImage(systemSymbolName: iconName, accessibilityDescription: "Speech to Text")?.withSymbolConfiguration(config)
        
        if withAnimation {
            // Use NSAnimationContext for smooth macOS animations
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                // Fade out
                button.animator().alphaValue = 0.0
            }, completionHandler: {
                // Change icon
                button.image = newImage
                
                // Fade in
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.15
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    button.animator().alphaValue = 1.0
                })
            })
        } else {
            button.image = newImage
        }
    }
    
    private func fadeInIcon() {
        guard let button = statusItem?.button else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            button.animator().alphaValue = 1.0
        })
    }
    
    private func fadeOutIcon(completion: @escaping () -> Void) {
        guard let button = statusItem?.button else {
            completion()
            return
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            button.animator().alphaValue = 0.0
        }, completionHandler: completion)
    }
    
    // MARK: - Debug
    func getCurrentState() -> MenuBarIconState {
        return currentState
    }
}
