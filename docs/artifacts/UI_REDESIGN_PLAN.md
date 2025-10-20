# UI Redesign Implementation Plan

## Overview

Build a minimal menu bar app with:
1. **Menu bar popover** - 3 buttons (start/stop, settings, quit)
2. **Settings window** - Sidebar navigation with Home and Settings tabs
3. **Dock behavior** - Only appear in dock/cmd+tab when settings window is open

---

## Part 1: Creating the New UI

### 1.1 Menu Bar Popover View
**File**: `Swift/MenuBarPopoverView.swift`

**Features**:
- Start/Stop recording button (shows current state)
- Settings button (opens settings window)
- Quit button
- Size: ~220x150px



**SF Symbols**:
- Recording inactive: `mic.circle.fill` (blue)
- Recording active: `stop.circle.fill` (red)
- Settings: `gearshape.fill`
- Quit: `power` (red)

---

### 1.2 Settings Window View
**File**: `Swift/SettingsWindowView.swift`

**Features**:
- Two-pane layout: Sidebar + Content area
- Sidebar tabs: Home and Settings
- Window size: ~700x500 (resizable)
- Triggers dock/cmd+tab visibility when open

**Layout**:
```
┌─────────┬──────────────────────┐
│ Home    │                      │
│ ───────│   Content Area        │
│Settings │                      │
└─────────┴──────────────────────┘
```

**SF Symbols**:
- Home: `house.fill`
- Settings: `gearshape.fill`

---

### 1.3 Home Tab View
**File**: `Swift/HomeTabView.swift`

**Features**:
- Display top N transcriptions (default 20)
- Each entry shows:
  - Timestamp
  - Transcribed text
  - Copy button

**Layout**:
```
┌─────────────────────────────────┐
│ Transcription History           │
│ ─────────────────────────       │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Oct 2, 2025 at 2:45 PM      │ │
│ │ "Sample transcription..."   │ │
│ │                  [📋 Copy]  │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Oct 2, 2025 at 2:30 PM      │ │
│ │ "Another transcription..."  │ │
│ │                  [📋 Copy]  │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**SF Symbol**:
- Copy: `doc.on.doc`

---

### 1.4 Settings Tab View
**File**: `Swift/SettingsTabView.swift`

**Features**:
- Basic Settings section (always visible):
  - Model picker
  - Hotkey configuration
- Developer Settings section (collapsible & Current Work in Progress - no need to add functionality here):
  - Whisper: task, language, temperature
  - Server: host, port, uv path, script path
  - Audio: sample rate, channels, format, chunk duration
  - LLM: enabled, model, base URL, temperature, max tokens, prompt

**Layout**:
```
┌─────────────────────────────────┐
│ Settings                        │
│ ─────────────────────────       │
│                                 │
│ ━━━ Basic Settings ━━━━━━━━━   │
│                                 │
│ Model:    [small      ▾]        │
│ Hotkey:   [⌥L] [Change]         │
│                                 │
│ ━━━ Developer Settings ▾ ━━━━   │
│                                 │
│ Whisper Advanced                │
│   Task:        [transcribe ▾]   │
│   Language:    [English ▾]      │
│   Temperature: [───●───] 0.0    │
│                                 │
│ Server                          │
│   Host: [localhost]             │
│   Port: [3001]                  │
│                                 │
│ Audio                           │
│   Sample Rate: [16000]          │
│   Channels:    [1 (Mono) ▾]     │
│                                 │
│ LLM Post-processing             │
│   Enabled: [✓]                  │
│   Model:   [llama3.1]           │
│                                 │
│                                 │
└─────────────────────────────────┘
```

**SF Symbols**:
- Collapsed: `chevron.right`
- Expanded: `chevron.down`

---

### 1.5 Dock Behavior Implementation
**Location**: `Swift/SpeechToTextApp.swift` (AppDelegate)

**Add window management**:
```swift
private var settingsWindow: NSWindow?
private var settingsWindowController: NSWindowController?

func openSettingsWindow() {
    if settingsWindow == nil {
        let settingsView = SettingsWindowView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        settingsWindow = NSWindow(contentViewController: hostingController)
        settingsWindow?.title = "Speech-to-Text Settings"
        settingsWindow?.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        settingsWindow?.setContentSize(NSSize(width: 700, height: 500))
        settingsWindow?.center()
        settingsWindow?.delegate = self
        
        settingsWindowController = NSWindowController(window: settingsWindow)
    }
    
    // Show in dock
    NSApp.setActivationPolicy(.regular)
    
    settingsWindowController?.showWindow(nil)
    settingsWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}

func closeSettingsWindow() {
    settingsWindow?.close()
    settingsWindow = nil
    settingsWindowController = nil
    
    // Hide from dock
    NSApp.setActivationPolicy(.accessory)
}

// Handle window close
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == settingsWindow {
            closeSettingsWindow()
        }
    }
}
```

---

## Part 2: SettingsManager Integration

### 2.1 What SettingsManager Already Provides

**Published Properties** (for SwiftUI binding):
```swift
@Published var whisperModel: String
@Published var whisperLanguage: String
@Published var whisperTask: String
@Published var whisperTemperature: Double

@Published var hotkeyKeyCode: Int
@Published var hotkeyModifiers: [String]

@Published var serverHost: String
@Published var serverPort: Int
@Published var uvPath: String
@Published var scriptPath: String

@Published var audioSampleRate: Int
@Published var audioChannels: Int
@Published var audioFormat: String
@Published var audioChunkDuration: Int

@Published var llmEnabled: Bool
@Published var llmModel: String
@Published var llmBaseUrl: String
@Published var llmTemperature: Double
@Published var llmMaxTokens: Int
@Published var llmPrompt: String?

@Published var loggingEnabled: Bool
@Published var loggingLogFile: String
@Published var loggingMaxFileSize: String
@Published var loggingBackupCount: Int
```

**Update Methods** (automatically save and notify):
```swift
updateWhisperSettings(model:language:task:temperature:)
updateHotkeySettings(keyCode:modifiers:)
updateServerSettings(host:port:uvPath:scriptPath:)
updateAudioSettings(sampleRate:channels:format:chunkDuration:)
updateLLMSettings(baseUrl:enabled:model:temperature:maxTokens:prompt:)
updateLoggingSettings(enabled:logFile:maxFileSize:backupCount:)
```

**Helper Methods**:
```swift
getHotkeyDisplayString() -> String  // Returns "⌥L" format
languageDisplayName(_:) -> String   // Returns "English" from "en"
```

---

### 2.2 How to Use in New UI

**Basic Settings Section**:
```swift
@StateObject private var settingsManager = SettingsManager()

// Model picker
Picker("Model", selection: $settingsManager.whisperModel) {
    ForEach(settingsManager.availableModels, id: \.self) { model in
        Text(model.capitalized).tag(model)
    }
}
.onChange(of: settingsManager.whisperModel) { newValue in
    settingsManager.updateWhisperSettings(
        model: newValue,
        language: settingsManager.whisperLanguage,
        task: settingsManager.whisperTask,
        temperature: settingsManager.whisperTemperature
    )
}

// Hotkey (reuse existing HotkeyRecorder component)
Text(settingsManager.getHotkeyDisplayString())
Button("Change") {
    // Use HotkeyRecorder to capture new hotkey
    // Then call settingsManager.updateHotkeySettings(...)
}
```

**Developer Settings Section**:
```swift
// Whisper Advanced
Picker("Task", selection: $settingsManager.whisperTask) { ... }
    .onChange { settingsManager.updateWhisperSettings(...) }

Picker("Language", selection: $settingsManager.whisperLanguage) { ... }
    .onChange { settingsManager.updateWhisperSettings(...) }

Slider(value: $settingsManager.whisperTemperature, in: 0...1)
    .onChange { settingsManager.updateWhisperSettings(...) }

// Server
TextField("Host", text: $settingsManager.serverHost)
    .onChange { settingsManager.updateServerSettings(...) }

TextField("Port", value: $settingsManager.serverPort)
    .onChange { settingsManager.updateServerSettings(...) }

// Audio
TextField("Sample Rate", value: $settingsManager.audioSampleRate)
    .onChange { settingsManager.updateAudioSettings(...) }

// LLM
Toggle("Enabled", isOn: $settingsManager.llmEnabled)
    .onChange { settingsManager.updateLLMSettings(...) }

TextField("Model", text: $settingsManager.llmModel)
    .onChange { settingsManager.updateLLMSettings(...) }

// Logging
Toggle("Enabled", isOn: $settingsManager.loggingEnabled)
    .onChange { settingsManager.updateLoggingSettings(...) }

TextField("Log File", text: $settingsManager.loggingLogFile)
    .onChange { settingsManager.updateLoggingSettings(...) }
```

---

## Implementation Summary

**New Files to Create**:
1. `MenuBarPopoverView.swift` - 3-button popover
2. `SettingsWindowView.swift` - Window with sidebar
3. `HomeTabView.swift` - Transcription history
4. `SettingsTabView.swift` - Settings with sections

**Files to Modify**:
1. `SpeechToTextApp.swift` - Add window management and dock behavior

**Key Point**: SettingsManager requires no changes. All functionality needed already exists.
