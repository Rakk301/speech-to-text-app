import SwiftUI

struct SettingsView: View {
    @State private var hotkey = "⌘⇧S"
    @State private var isEnabled = true
    @State private var showNotifications = true
    @State private var selectedModel = "base"
    
    private let availableModels = ["tiny", "base", "small", "medium", "large"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Speech to Text")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Global hotkey utility for real-time transcription")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            // Settings Form
            Form {
                Section("Recording") {
                    HStack {
                        Text("Global Hotkey")
                        Spacer()
                        Text(hotkey)
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    Toggle("Enable App", isOn: $isEnabled)
                    
                    Toggle("Show Notifications", isOn: $showNotifications)
                }
                
                Section("Model Settings") {
                    Picker("Whisper Model", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model.capitalized)
                                .tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    HStack {
                        Text("Model Size")
                        Spacer()
                        Text(modelSizeDescription)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Section("Status") {
                    HStack {
                        Text("Status")
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isEnabled ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(isEnabled ? "Active" : "Inactive")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Microphone")
                        Spacer()
                        Text("Granted")
                            .foregroundColor(.green)
                    }
                }
            }
            .formStyle(GroupedFormStyle())
            
            // Footer
            VStack(spacing: 8) {
                Text("Press \(hotkey) to start recording")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Recording will automatically stop when you release the hotkey")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: 500)
        .padding()
    }
    
    private var modelSizeDescription: String {
        switch selectedModel {
        case "tiny":
            return "Fastest, least accurate"
        case "base":
            return "Good balance"
        case "small":
            return "Better accuracy"
        case "medium":
            return "High accuracy"
        case "large":
            return "Best accuracy, slowest"
        default:
            return "Good balance"
        }
    }
}

#Preview {
    SettingsView()
} 