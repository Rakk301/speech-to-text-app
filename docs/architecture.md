# Architecture

## Overview
1. Hotkey pressed → Swift records audio
2. Swift saves audio to file → calls Python server API
3. Python runs Whisper STT → optional LLM postprocessing → JSON
4. Swift receives text → pastes at cursor → logs

## Components Map

### Swift
- `Swift/SpeechToTextApp.swift`: App lifecycle & coordination
- `Swift/AudioRecorder.swift`: AVAudioEngine wrapper (16kHz mono)
- `Swift/HotkeyManager.swift`: Global hotkey registration
- `Swift/PasteManager.swift`: Clipboard & paste
- `Swift/TranscriptionServer.swift`: Launches embedded server with `uv`
- `Swift/TranscriptionServerClient.swift`: HTTP client (`/transcribe`)
- `Swift/SettingsManager.swift`: YAML-backed settings (App Support)

### Python (`stt-server-py/`)
- `transcription_server.py`: aiohttp server (`/transcribe`, `/providers`, `/reload_model`, `/health`)
- `whisper_STTProvider.py`: Whisper integration
- `llm_processor.py`: Optional LLM postprocessing
- `config.py`: YAML loader
- `settings.yaml`: Default config example
- `pyproject.toml`: Dependencies (managed by `uv`)

## Server Modes
- Embedded (default): Swift launches `uv run python transcription_server.py` with the app settings file.
- Manual: Run server from terminal for development; point app to host/port.
# Architecture

## Overview
1. Hotkey pressed → Swift records audio
2. Swift saves audio to file → calls Python server API
3. Python runs Whisper STT → optional LLM postprocessing → JSON
4. Swift receives text → pastes at cursor → logs

## Components Map

### Swift
- `Swift/SpeechToTextApp.swift`: App lifecycle & coordination
- `Swift/AudioRecorder.swift`: AVAudioEngine wrapper (16kHz mono)
- `Swift/HotkeyManager.swift`: Global hotkey registration
- `Swift/PasteManager.swift`: Clipboard & paste
- `Swift/TranscriptionServer.swift`: Launches embedded server with `uv`
- `Swift/TranscriptionServerClient.swift`: HTTP client (`/transcribe`)
- `Swift/SettingsManager.swift`: YAML-backed settings (App Support)

### Python (`stt-server-py/`)
- `transcription_server.py`: aiohttp server (`/transcribe`, `/providers`, `/reload_model`, `/health`)
- `whisper_STTProvider.py`: Whisper integration
- `llm_processor.py`: Optional LLM postprocessing
- `config.py`: YAML loader
- `settings.yaml`: Default config example
- `pyproject.toml`: Dependencies (managed by `uv`)

## Server Modes
- Embedded (default): Swift launches `uv run python transcription_server.py` with the app settings file.
- Manual: Run server from terminal for development; point app to host/port.

