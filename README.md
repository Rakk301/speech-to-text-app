# Speech-to-Text Application

A macOS-native speech-to-text utility app that runs locally, triggered by a global hotkey, transcribes real-time microphone input, (optionally) applies LLM-based postprocessing, then pastes the final output at the cursor.

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
├── Swift/                           # macOS app components
│   ├── SpeechToTextApp.swift        # App entry & coordination
│   ├── AudioRecorder.swift          # AVAudioEngine wrapper
│   ├── HotkeyManager.swift          # Global hotkey registration
│   ├── PasteManager.swift           # Clipboard & paste operations
│   ├── TranscriptionServer.swift    # Embedded Python server launcher (uv)
│   ├── TranscriptionServerClient.swift # HTTP client to server
│   ├── SettingsManager.swift        # YAML-backed settings
│   └── ...                          # Other Swift components
├── stt-server-py/                   # Python transcription server
│   ├── transcription_server.py      # aiohttp server entrypoint
│   ├── whisper_STTProvider.py       # Whisper provider
│   ├── llm_processor.py             # Optional LLM post-processing
│   ├── config.py                    # Config loader
│   ├── settings.yaml                # Server settings (YAML)
│   └── pyproject.toml               # Python deps (uv)
├── docs/
│   ├── quickstart.md
│   ├── architecture.md
│   ├── configuration.md
│   ├── development.md
│   ├── troubleshooting.md
│   └── artifacts/
│       └── UI_REDESIGN_PLAN.md
├── SpeechToTextApp.xcodeproj/
└── README.md
```

## 🎯 Development Principles
- Use SwiftUI for modern, native macOS UI components
- Keep Swift side lean and focused on system integration
- Use Python for all ML/LLM operations
- Maintain loose coupling via subprocess communication
- CLI-style Python scripts for easy testing and iteration
- Comprehensive logging for debugging and user feedback

## ⚙️ Settings Management

The app uses a robust YAML-based configuration system with automatic component reloading:

### Configuration Features
- **Type-safe YAML parsing** using the Yams package
- **Automatic settings persistence** to user documents directory
- **Real-time component updates** when relevant settings change
- **Comprehensive configuration** covering all app aspects

### Settings Categories
- **Whisper Configuration**: Model size, language, task, temperature
- **Server Settings**: Host, port, Python paths
- **Hotkey Configuration**: Global key combinations
- **LLM Settings**: Post-processing model and parameters
- **Audio Settings**: Sample rate, channels, format
- **Logging Configuration**: File paths and rotation

### Automatic Reloading
- **Whisper settings changes** → Model reload via API (fallback: restart)
- **Hotkey configuration changes** → Global hotkeys automatically reload
- **Server settings changes** → Server automatically restarts
- **Other settings changes** → Components update in real-time

See [`docs/configuration.md`](docs/configuration.md) for detailed setup instructions.

## 🔧 Building the Project

### Prerequisites
- Xcode 15+
- macOS 14+
- Python 3.12+ with required dependencies
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
1. Navigate to the `stt-server-py/` directory
2. Install dependencies using uv:
   ```bash
   cd stt-server-py
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
- **Yams** - YAML configuration parsing and generation

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


### Python Components (stt-server-py)
- **transcription_server.py** - aiohttp HTTP server exposing transcription endpoints
- **whisper_STTProvider.py** - Whisper model provider
- **llm_processor.py** - Optional LLM-based postprocessing
- **config.py** - Loads YAML configuration

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
- Python server output captured and logged when embedded; manual server logs to stdout/stderr

## 📝 Notes

- Audio is recorded at 16kHz mono for optimal Whisper compatibility
- Temporary audio files are automatically cleaned up
- The app runs as a menu bar application (LSUIElement = true)
- Global hotkey requires accessibility permissions
- Python server is bundled and launched via uv at runtime
- Dependencies for Python are defined in `stt-server-py/pyproject.toml`

## 🎯 Development Workflow

1. **Swift Development**: Edit Swift files in Xcode for UI and system integration
2. **Python Development**: Edit Python scripts in your preferred editor
3. **Testing**: Use the test bridge functionality to verify Python communication
4. **Building**: Xcode bundles `stt-server-py/` as a resource; the app uses `uv` at runtime
5. **Deployment**: Ensure `uv` is installed on target machines for embedded server

## 🔧 Configuration

- The app maintains a YAML at `~/Library/Application Support/SpeechToTextApp/settings.yaml`.
- The embedded/manually run Python server reads that same file by default.
- Common fields:
  - `whisper.model`, `whisper.language`, `whisper.task`, `whisper.temperature`
  - `hotkey.key_code`, `hotkey.modifiers`
  - `server.host`, `server.port`, `server.uv_path`
  - Optional: `llm.enabled`, `llm.model`, `llm.base_url`, `llm.temperature`, `llm.max_tokens`, `llm.prompt`

See `docs/configuration.md` for full details and examples.

## 📚 Documentation
- Quickstart: [`docs/quickstart.md`](docs/quickstart.md)
- Architecture: [`docs/architecture.md`](docs/architecture.md)
- Configuration: [`docs/configuration.md`](docs/configuration.md)
- Development: [`docs/development.md`](docs/development.md)
- Troubleshooting: [`docs/troubleshooting.md`](docs/troubleshooting.md)
- UI Redesign Plan (artifact): [`docs/artifacts/UI_REDESIGN_PLAN.md`](docs/artifacts/UI_REDESIGN_PLAN.md)