# Quickstart

## Prerequisites
- Xcode 15+
- macOS 14+
- Python 3.12+
- uv package manager

Install uv (Homebrew):
```bash
brew install uv
```

## First Run (Embedded Server)
1. Optional: pre-sync Python deps for faster first run:
   ```bash
   cd stt-server-py && uv sync
   ```
2. Open `SpeechToTextApp.xcodeproj` in Xcode.
3. Build and run.
4. Grant permissions when prompted (Microphone, Accessibility, Apple Events).
5. Use the global hotkey to start/stop transcription.

The app launches the Python server via `uv run` pointing at the bundled `stt-server-py/`.

## Manual Server (for development/testing)
```bash
cd stt-server-py
uv sync
uv run python transcription_server.py ../Swift/settings.yaml --port 3001
```
Then in the app, set `Server → Host/Port` to match, or use defaults (`localhost:3001`).

Troubleshooting? See [`docs/troubleshooting.md`](troubleshooting.md).

