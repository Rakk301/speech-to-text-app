import SwiftUI

struct NotificationView: View {
    let title: String
    let message: String
    let type: NotificationType
    let isVisible: Bool
    
    enum NotificationType {
        case success
        case error
        case info
        case recording
        
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "xmark.circle.fill"
            case .info:
                return "info.circle.fill"
            case .recording:
                return "mic.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success:
                return .green
            case .error:
                return .red
            case .info:
                return .blue
            case .recording:
                return .orange
            }
        }
    }
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: isVisible)
        }
    }
}

struct TranscriptionResultView: View {
    let transcribedText: String
    let isVisible: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        if isVisible {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "text.bubble.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    Text("Transcription Complete")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                ScrollView {
                    Text(transcribedText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                
                HStack {
                    Button("Copy to Clipboard") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(transcribedText, forType: .string)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .frame(width: 400)
            .transition(.scale.combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: isVisible)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        NotificationView(
            title: "Recording Started",
            message: "Press ⌘⇧S again to stop recording",
            type: .recording,
            isVisible: true
        )
        
        NotificationView(
            title: "Transcription Complete",
            message: "Text has been pasted to your cursor position",
            type: .success,
            isVisible: true
        )
        
        TranscriptionResultView(
            transcribedText: "This is a sample transcription result that shows how the text would appear in the notification view.",
            isVisible: true,
            onDismiss: {}
        )
    }
    .padding()
} 