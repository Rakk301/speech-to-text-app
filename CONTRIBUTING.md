# Contributing

## How to Contribute
1. Fork and create a feature branch.
2. Make focused changes with clear commits.
3. Open a PR describing the change and a brief test plan.

## Code Style
- Swift: prioritize readability; follow file-per-responsibility pattern used in `Swift/`.
- Python: add type hints, use logging, and keep CLI scripts simple.

## Testing Changes
- Manual server: `cd stt-server-py && uv sync && uv run python transcription_server.py settings.yaml --port 3001`.
- Point the app at `localhost:3001` in Settings → Server.

## Scope
- Keep Swift side focused on system integration.
- Keep ML and LLM logic in Python.

