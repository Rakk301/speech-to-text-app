# Development Guide

This guide covers building and developing SpeechToTextApp from source.

## Prerequisites

- **Xcode 15+** — [Download from Mac App Store](https://apps.apple.com/app/xcode/id497799835)
- **macOS 14 (Sonoma)+** — Required for deployment target
- **uv** — Python package manager

Install uv:

```bash
brew install uv
```

## Repository Structure

```
speech-to-text-app/
├── Swift/                      # macOS app source
│   ├── SpeechToTextApp.swift   # App entry point
│   ├── AudioRecorder.swift     # Audio capture
│   ├── HotkeyManager.swift     # Global hotkeys
│   └── ...
├── stt-server-py/              # Python server
│   ├── transcription_server.py # Server entry point
│   ├── whisper_STTProvider.py  # Whisper integration
│   └── pyproject.toml          # Python dependencies
├── docs/                       # Documentation
├── SpeechToTextApp.xcodeproj/  # Xcode project
└── README.md
```

## Building the App

### 1. Clone the Repository

```bash
git clone https://github.com/Rakk301/speech-to-text-app.git
cd speech-to-text-app
```

### 2. Install Python Dependencies

```bash
cd stt-server-py
uv sync
cd ..
```

This creates a virtual environment and installs all Python dependencies.

### 3. Open in Xcode

```bash
open SpeechToTextApp.xcodeproj
```

### 4. Build and Run

- Select **SpeechToTextApp** scheme
- Press `Cmd+R` to build and run
- Grant permissions when prompted

## Development Workflow

### Swift Development

Edit Swift files in Xcode. The app will:
- Launch the Python server automatically from the bundled `stt-server-py/`
- Reload settings when changed
- Show errors in the console

### Python Development

For iterating on the Python server, run it manually:

```bash
cd stt-server-py
uv run python transcription_server.py settings.yaml --host localhost --port 3001
```

Then configure the app to connect to your manual server:
1. Open Settings in the app
2. Set Server Host to `localhost`
3. Set Server Port to `3001`

This lets you modify Python code without rebuilding the Swift app.

### Testing Transcription

Test the Python server directly:

```bash
# Health check
curl http://localhost:3001/health

# Transcribe audio file
curl -X POST http://localhost:3001/transcribe \
  -F "audio=@test.wav"
```

## Required Permissions

When running from Xcode, you'll need to grant:

| Permission | Purpose | How to Grant |
|------------|---------|--------------|
| Microphone | Audio recording | Prompt appears, or System Settings → Privacy |
| Accessibility | Global hotkeys, paste | System Settings → Privacy → Accessibility |

**Tip:** If hotkeys stop working, check that Xcode (or the built app) is in the Accessibility list.

## Debugging

### Swift Logs

Logs appear in Xcode console. Filter by component:

- `[AudioRecorder]` — Recording issues
- `[HotkeyManager]` — Hotkey registration
- `[TranscriptionServer]` — Server launch issues
- `[TranscriptionServerClient]` — HTTP errors

### Python Logs

When running the server manually, logs go to stdout:

```bash
uv run python transcription_server.py settings.yaml --port 3001
```

### Common Issues

**Server won't start:**
- Check `uv` is installed: `which uv`
- Check port isn't in use: `lsof -i :3001`

**Hotkey not working:**
- Verify Accessibility permission is granted
- Check another app isn't using the same hotkey

**Transcription fails:**
- Check microphone permission
- Check Whisper model downloaded (first run takes time)

## Code Style

### Swift

- One file per component/responsibility
- Use `Logger` for all logging
- Prefer async/await for async operations
- Follow existing patterns in the codebase

### Python

- Type hints on all functions
- Use `logging` module, not `print()`
- Keep CLI scripts simple and testable

## Building for Distribution

To create a distributable app:

1. In Xcode, select **Product → Archive**
2. Export as **Copy App** (for unsigned distribution)
3. Create a ZIP:
   ```bash
   cd /path/to/export
   zip -r SpeechToTextApp.zip SpeechToTextApp.app
   ```

See [Releasing Guide](releasing.md) for full release process.

## Related Docs

- [Architecture](architecture.md) — How it works internally
- [Configuration](configuration.md) — Settings reference
- [Troubleshooting](troubleshooting.md) — Common issues
