# SpeechToTextApp

A macOS menu bar app for speech-to-text transcription. Press a hotkey, speak, and the transcribed text is automatically pasted at your cursor.

Runs locally using [OpenAI Whisper](https://github.com/openai/whisper) with optional LLM post-processing.

## Features

- **Global hotkey** — Trigger recording from anywhere with a customizable shortcut
- **Local processing** — All transcription happens on your Mac, no cloud services
- **Auto-paste** — Transcribed text is pasted directly at your cursor
- **LLM post-processing** — Optional cleanup/formatting via local LLM (Ollama)
- **Menu bar app** — Stays out of your way, lives in the menu bar

## Installation

### Homebrew (Recommended)

```bash
brew tap Rakk301/speechtotextapp
brew install --cask speechtotextapp
```

### From Source

See [Development Guide](docs/development.md) for building from source.

## Quick Start

1. Launch **SpeechToTextApp** from Applications
2. Grant permissions when prompted:
   - **Microphone** — For recording speech
   - **Accessibility** — For global hotkey and paste functionality
3. Click the menu bar icon to configure your hotkey (default: `⌥L`)
4. Press the hotkey to start recording, press again to stop
5. Transcribed text appears at your cursor

## Configuration

The app stores settings in `~/Library/Application Support/SpeechToTextApp/settings.yaml`.

Configure via the menu bar icon → Settings:
- **Whisper model** — tiny, base, small, medium, large
- **Language** — Auto-detect or specify
- **Hotkey** — Customize your trigger shortcut
- **LLM** — Enable/disable post-processing

See [Configuration Guide](docs/configuration.md) for all options.

## Documentation

- [Getting Started](docs/getting-started.md) — Detailed setup guide
- [Configuration](docs/configuration.md) — All settings explained
- [Architecture](docs/architecture.md) — How it works (for contributors)
- [Development](docs/development.md) — Building from source
- [Troubleshooting](docs/troubleshooting.md) — Common issues and fixes

## Requirements

- macOS 14 (Sonoma) or later
- ~2GB disk space for Whisper models (downloaded on first use)

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
