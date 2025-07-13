# Speech-to-Text Application

A macOS-native speech-to-text utility app that runs offline, triggered by a global hotkey (⌘⇧S), transcribes real-time microphone input, applies LLM-based postprocessing, then pastes the final output at the cursor.

## 🏗️ System Architecture

### Core Components
- **Swift**: System integration (hotkeys, audio capture, paste operations)
- **Python**: ML inference (Whisper STT, LLM postprocessing)
- **Bridge**: Subprocess communication between Swift and Python

### Data Flow
1. Global hotkey pressed → Swift records audio
2. Swift saves audio to file → calls Python script
3. Python runs Whisper STT → LLM postprocessing → stdout
4. Swift receives text → pastes at cursor → logs with timestamp

## 📁 Project Directory Structure

```
speech-to-text-app/
├── Swift/                          # macOS native application components
│   ├── SpeechToTextApp.swift      # Main SwiftUI app entry point and coordination
│   ├── SettingsView.swift         # SwiftUI settings interface
│   ├── NotificationView.swift     # SwiftUI notification and result views
│   ├── AudioRecorder.swift        # AVAudioEngine wrapper for microphone capture
│   ├── HotkeyManager.swift        # Global hotkey handling and registration
│   ├── PasteManager.swift         # Clipboard and paste operations
│   ├── PythonBridge.swift         # Subprocess communication with Python scripts
│   ├── Logger.swift               # Logging utilities and file management
│   ├── Info.plist                 # macOS app configuration and permissions
├── Python/                        # Machine learning and transcription components
│   ├── transcribe.py              # Main STT script - orchestrates the pipeline
│   ├── whisper_wrapper.py         # Whisper model integration and inference
│   ├── llm_processor.py           # LLM postprocessing for text enhancement
│   ├── config.py                  # Configuration management and settings loader
│   ├── pyproject.toml             # Python project dependencies and metadata
├── Config/                        # Application configuration
│   └── settings.yaml              # User-configurable settings (hotkeys, models, etc.)
└── README.md                      # This file - project overview and documentation
```

### File Descriptions

#### Swift Components
- **`SpeechToTextApp.swift`**: Main SwiftUI app struct with AppDelegate for lifecycle management and menu bar integration
- **`SettingsView.swift`**: Modern SwiftUI interface for app configuration and settings
- **`NotificationView.swift`**: SwiftUI components for status notifications and transcription result display
- **`AudioRecorder.swift`**: Manages microphone access, audio recording sessions, and file output using AVAudioEngine
- **`HotkeyManager.swift`**: Registers and handles global hotkey (⌘⇧S) using Carbon framework
- **`PasteManager.swift`**: Handles clipboard operations and text pasting at cursor position
- **`PythonBridge.swift`**: Executes Python scripts as subprocesses and manages inter-process communication
- **`Logger.swift`**: Provides logging utilities with timestamp formatting and file output
- **`Info.plist`**: macOS app configuration including permissions for microphone and accessibility

#### Python Components
- **`transcribe.py`**: Main entry point that orchestrates the entire transcription pipeline
- **`whisper_wrapper.py`**: Encapsulates Whisper model loading, inference, and audio preprocessing
- **`llm_processor.py`**: Handles LLM-based text postprocessing for grammar correction and enhancement
- **`config.py`**: Loads and manages configuration from YAML files and environment variables
- **`pyproject.toml`**: Defines Python dependencies, project metadata, and build configuration
- **`uv.lock`**: Locked dependency versions for reproducible builds

#### Configuration
- **`settings.yaml`**: User-configurable settings including hotkey combinations, model paths, and processing options

#### Documentation
- **`BACKLOG.md`**: Development roadmap, feature requests, and bug tracking
- **`XCODE_SETUP.md`**: Step-by-step instructions for setting up the Xcode project
- **`Swift/README.md`**: Swift-specific development guide and setup instructions

## 🎯 Development Principles
- Use SwiftUI for modern, native macOS UI components
- Keep Swift side lean and focused on system integration
- Use Python for all ML/LLM operations
- Maintain loose coupling via subprocess communication
- CLI-style Python scripts for easy testing and iteration
- Comprehensive logging for debugging and user feedback

## 🚀 Getting Started

See `XCODE_SETUP.md` for detailed setup instructions and `Swift/README.md` for Swift-specific development guidelines.