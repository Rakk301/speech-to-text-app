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
├── speech-to-text-app/              # Xcode project directory
│   ├── speech-to-text-app/          # Swift application components
│   │   ├── SpeechToTextApp.swift    # Main SwiftUI app entry point and coordination
│   │   ├── SettingsView.swift       # SwiftUI settings interface

│   │   ├── AudioRecorder.swift      # AVAudioEngine wrapper for microphone capture
│   │   ├── HotkeyManager.swift      # Global hotkey handling and registration
│   │   ├── PasteManager.swift       # Clipboard and paste operations
│   │   ├── PythonBridge.swift       # Subprocess communication with Python scripts
│   │   ├── Logger.swift             # Logging utilities and file management
│   │   └── Info.plist               # macOS app configuration and permissions
│   └── speech-to-text-app.xcodeproj # Xcode project files
├── Python/                          # Machine learning and transcription components
│   ├── transcribe.py                # Main STT script - orchestrates the pipeline
│   ├── whisper_wrapper.py           # Whisper model integration and inference
│   ├── llm_processor.py             # LLM postprocessing for text enhancement
│   ├── config.py                    # Configuration management and settings loader
│   ├── pyproject.toml               # Python project dependencies and metadata
│   └── uv.lock                      # Locked dependency versions for reproducible builds
├── Config/                          # Application configuration
│   └── settings.yaml                # User-configurable settings (hotkeys, models, etc.)
└── README.md                        # This file - project overview and documentation
```

## 🎯 Development Principles
- Use SwiftUI for modern, native macOS UI components
- Keep Swift side lean and focused on system integration
- Use Python for all ML/LLM operations
- Maintain loose coupling via subprocess communication
- CLI-style Python scripts for easy testing and iteration
- Comprehensive logging for debugging and user feedback

## 🔧 Building the Project

### Prerequisites
- Xcode 13+ 
- macOS 12.0+
- Python 3.8+ with required dependencies
- uv package manager (for Python dependency management)

### Swift Components Setup
1. Open the Xcode project in `speech-to-text-app/speech-to-text-app.xcodeproj`
2. Configure build settings:
   - Set deployment target to macOS 12.0+
   - Enable App Sandbox (optional)
   - Add required frameworks:
     - AVFoundation
     - Carbon
     - AppKit
     - Foundation

### Python Components Setup
1. Navigate to the `Python/` directory
2. Install dependencies using uv:
   ```bash
   cd Python
   uv sync
   ```

### Required Permissions
The app requires the following permissions:
- **Microphone** - For audio recording
- **Accessibility** - For global hotkeys and cursor positioning
- **Apple Events** - For controlling other apps to paste text

### Dependencies

#### Swift Dependencies
- **AVFoundation** - Audio recording and playback
- **Carbon** - Global hotkey management
- **AppKit** - macOS UI components
- **Foundation** - Basic functionality

#### Python Dependencies
- **whisper** - Speech-to-text transcription
- **ollama** - Local LLM processing
- **sounddevice** - Audio processing
- **numpy** - Numerical operations
- **pyyaml** - Configuration file parsing

## 🏗️ Architecture

The app follows a component-based architecture where each Swift file has a single responsibility:

### Swift Components
- **SpeechToTextApp** - Coordinates all components and manages the app lifecycle
- **AudioRecorder** - Handles microphone recording with Whisper-compatible settings (16kHz, mono)
- **HotkeyManager** - Registers and handles the global hotkey (⌘⇧S)
- **PasteManager** - Manages clipboard operations and text insertion at cursor position
- **PythonBridge** - Executes Python scripts for ML processing via subprocess communication
- **Logger** - Provides timestamped logging for debugging and user feedback
- **SettingsView** - Modern SwiftUI interface for app configuration


### Python Components
- **transcribe.py** - Main entry point that orchestrates the entire transcription pipeline
- **whisper_wrapper.py** - Encapsulates Whisper model loading, inference, and audio preprocessing
- **llm_processor.py** - Handles LLM-based text postprocessing for grammar correction and enhancement
- **config.py** - Loads and manages configuration from YAML files and environment variables

## 🚀 Usage

1. Build and run the app in Xcode
2. Grant microphone and accessibility permissions when prompted
3. Press ⌘⇧S to start recording
4. Speak into the microphone
5. Press ⌘⇧S again to stop recording
6. The transcribed text will be pasted at the cursor position

## 🔍 Debugging

The app includes comprehensive logging:
- Check the log file in `~/Documents/Logs/transcriptions.log`
- Console output for real-time debugging
- Error handling with user-friendly alerts
- Python script output captured and logged

## 📝 Notes

- Audio is recorded at 16kHz mono for optimal Whisper compatibility
- Temporary audio files are automatically cleaned up
- The app runs as a menu bar application (LSUIElement = true)
- Global hotkey requires accessibility permissions
- Python scripts are bundled within the app for sandboxed execution
- Virtual environment is created using uv for dependency management

## 🎯 Development Workflow

1. **Swift Development**: Edit Swift files in Xcode for UI and system integration
2. **Python Development**: Edit Python scripts in your preferred editor
3. **Testing**: Use the test bridge functionality to verify Python communication
4. **Building**: Xcode automatically bundles Python components with the app
5. **Deployment**: App bundle includes all necessary Python dependencies

## 🔧 Configuration

Edit `Config/settings.yaml` to customize:
- Hotkey combinations
- Whisper model selection
- LLM settings and prompts
- Audio recording parameters
- Logging preferences