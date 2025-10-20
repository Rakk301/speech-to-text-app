import SwiftUI

struct MenuBarPopoverView: View {
    @State private var isRecording = false
    
    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 0) {
            // Start/Stop Recording Button
            IconButton(
                icon: isRecording ? "stop.circle.fill" : "mic.circle.fill",
                color: isRecording ? .red : .blue,
                action: handleRecordingToggle
            )
            .frame(width: 38, height: 38)
            
            Divider()
                .frame(width: 1, height: 28)
                .padding(.horizontal, 6)
            
            // Settings Button
            IconButton(
                icon: "gearshape.fill",
                color: .gray,
                action: { onOpenSettings?() }
            )
            .frame(width: 38, height: 38)
            
            Divider()
                .frame(width: 1, height: 28)
                .padding(.horizontal, 6)
            
            // Quit Button
            IconButton(
                icon: "power",
                color: .red,
                action: { NSApplication.shared.terminate(nil) }
            )
            .frame(width: 38, height: 38)
        }
        .frame(height: 38)  // Exact content height
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: 160, height: 54)  // Exact total dimensions: 3×38 + 2×13 + 2×10 = 160
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func handleRecordingToggle() {
        if isRecording {
            onStopRecording?()
        } else {
            onStartRecording?()
        }
        isRecording.toggle()
    }
    
    func updateRecordingState(_ recording: Bool) {
        isRecording = recording
    }
}

// MARK: - Icon Button Component
struct IconButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 38, height: 38, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isHovered ? Color.gray.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 38, height: 38)  // Enforce exact button size
        .onHover { hovering in
            isHovered = hovering
        }
        .help(getTooltip())
    }
    
    private func getTooltip() -> String {
        switch icon {
        case "mic.circle.fill": return "Start Recording"
        case "stop.circle.fill": return "Stop Recording"
        case "gearshape.fill": return "Settings"
        case "power": return "Quit"
        default: return ""
        }
    }
}

#Preview {
    MenuBarPopoverView()
}


