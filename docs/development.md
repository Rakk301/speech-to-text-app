# Development

## Repo Layout
- Swift app under `Swift/`
- Python server under `stt-server-py/`
- Docs under `docs/`

## Embedded Server (default)
- App bundles `stt-server-py/` as a resource and launches:
  - `uv run --project <bundle>/stt-server-py python transcription_server.py <AppSupport>/settings.yaml --host localhost --port <chosenPort>`
- Ensure `uv` is installed. Configure path via Settings → Server → uv path.

## Manual Server Workflow
```bash
cd stt-server-py
uv sync
uv run python transcription_server.py settings.yaml --host localhost --port 3001
```
Then in the app: Settings → Server → set host `localhost` and port `3001`.

## Logging
- Swift logs to the console and app log file (see Settings/Logging).
- Python server logs to stdout/stderr; configure file logging via `logging` section.

## Permissions in Dev
- Microphone (recording)
- Accessibility (global hotkeys/paste)
- Apple Events (pasting into other apps)

