import SwiftUI

struct SettingsTabView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var hotkeyRecorder = HotkeyRecorder()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                Divider()
                
                // Basic Settings Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Basic Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Whisper Model
                    HStack {
                        Text("Model:")
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .leading)
                        
                        Picker("Model", selection: $settingsManager.whisperModel) {
                            ForEach(settingsManager.availableModels, id: \.self) { model in
                                Text(model.capitalized).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: settingsManager.whisperModel) { newValue in
                            settingsManager.updateWhisperModel(newValue)
                        }
                        
                        Spacer()
                    }
                    
                    // Global Hotkey
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Hotkey:")
                                .foregroundColor(.secondary)
                                .frame(width: 100, alignment: .leading)
                            
                            Text(settingsManager.getHotkeyDisplayString())
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            
                            Spacer()
                            
                            Button(hotkeyRecorder.isRecording ? "Recording..." : "Change") {
                                if hotkeyRecorder.isRecording {
                                    hotkeyRecorder.stopRecording()
                                } else {
                                    hotkeyRecorder.startRecording()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // Recording State
                        if hotkeyRecorder.isRecording {
                            HStack {
                                Text("")
                                    .frame(width: 100)
                                
                                Text(hotkeyRecorder.displayString)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text("")
                                    .frame(width: 100)
                                
                                Text("Press any key combination...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                        
                        // Apply New Hotkey
                        if !hotkeyRecorder.isRecording && (hotkeyRecorder.currentKeyCode != 0 || !hotkeyRecorder.currentModifiers.isEmpty) {
                            HStack {
                                Text("")
                                    .frame(width: 100)
                                
                                Text(hotkeyRecorder.displayString)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
                                
                                Spacer()
                                
                                Button("Apply") {
                                    let (keyCode, modifiers) = hotkeyRecorder.getHotkeyConfiguration()
                                    settingsManager.updateHotkey(keyCode: keyCode, modifiers: modifiers)
                                    hotkeyRecorder.resetToDefaults()
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Cancel") {
                                    hotkeyRecorder.resetToDefaults()
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Divider()
                
                // Developer Settings Section (Placeholder)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Developer Settings")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("(Work in Progress)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Advanced configuration options coming soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}

#Preview {
    SettingsTabView()
}


