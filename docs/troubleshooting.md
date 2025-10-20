# Troubleshooting

## Global hotkey not working
- Ensure Accessibility permission is granted in System Settings → Privacy & Security → Accessibility.
- Change the hotkey in settings to avoid conflicts.

## Microphone prompt didn’t appear
- Remove the app from Microphone permissions and relaunch.
- Verify your input device in macOS Sound settings.

## Server connection failed
- Check server health: `curl http://localhost:3001/health`
- Port in use? Change the port in settings or stop the conflicting process.
- Ensure `uv` is installed and the path is correct.

## Slow transcription
- Use a smaller Whisper model (e.g., `small` or `base`).
- Disable LLM postprocessing or use a smaller LLM.

## uv / Python env issues
- Re-sync deps: `cd stt-server-py && uv sync`
- Confirm Python 3.12+: `python3 --version`

