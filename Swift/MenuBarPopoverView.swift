import SwiftUI

struct MenuBarPopoverView: View {
    @State private var isRecording = false
    
    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Start/Stop Recording Button
            Button(action: handleRecordingToggle) {
                HStack(spacing: 10) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                        .foregroundColor(isRecording ? .red : .blue)
                    
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                        .foregroundColor(isRecording ? .red : .primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Settings Button
            Button(action: { onOpenSettings?() }) {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape.fill")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    Text("Settings")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
            
            // Quit Button
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack(spacing: 10) {
                    Image(systemName: "power")
                        .font(.body)
                        .foregroundColor(.red)
                    
                    Text("Quit")
                        .font(.body)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 220)
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

#Preview {
    MenuBarPopoverView()
}


