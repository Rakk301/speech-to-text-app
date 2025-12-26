# Getting Started

This guide walks you through installing and setting up SpeechToTextApp.

## Installation

### Option 1: Homebrew (Recommended)

```bash
brew tap Rakk301/speechtotextapp
brew install --cask speechtotextapp
```

This automatically installs the app and its dependencies.

### Option 2: Download from Releases

1. Download the latest `.zip` from [GitHub Releases](https://github.com/Rakk301/speech-to-text-app/releases)
2. Extract and move `SpeechToTextApp.app` to `/Applications`
3. Install the `uv` dependency:
   ```bash
   brew install uv
   ```

### Allowing the App (Gatekeeper)

Since the app is not notarized, macOS will block it on first launch:

1. Try to open the app — you'll see a warning
2. Go to **System Settings → Privacy & Security**
3. Scroll down and click **Open Anyway** next to the SpeechToTextApp message
4. Click **Open** in the confirmation dialog

## Required Permissions

The app needs these permissions to function:

### Microphone Access

Required for recording your speech.

- The app will prompt automatically on first recording attempt
- Or grant manually: **System Settings → Privacy & Security → Microphone**

### Accessibility Access

Required for global hotkeys and pasting text at your cursor.

- The app will prompt automatically
- Or grant manually: **System Settings → Privacy & Security → Accessibility**
- Add SpeechToTextApp to the allowed list

## First Run

1. **Launch the app** — Look for the icon in your menu bar
2. **Grant permissions** — Follow the prompts for Microphone and Accessibility
3. **Wait for model download** — On first transcription, Whisper downloads the model (~500MB for "small")
4. **Test it** — Press your hotkey (default: `⌥L`), speak, press again to stop

## Using the App

### Basic Workflow

1. Place your cursor where you want text to appear
2. Press the hotkey to **start recording** (menu bar icon changes)
3. Speak clearly into your microphone
4. Press the hotkey again to **stop recording**
5. Wait briefly for transcription
6. Text is automatically pasted at your cursor

### Menu Bar

Click the menu bar icon to:
- See recording status
- Start/stop recording manually
- Open Settings

### Settings

Access via menu bar icon → Settings:

| Setting | Description |
|---------|-------------|
| **Whisper Model** | tiny, base, small (default), medium, large — larger = more accurate but slower |
| **Language** | Auto-detect or specify (e.g., "en", "es", "fr") |
| **Hotkey** | Click to record a new shortcut |
| **LLM Post-processing** | Enable to clean up transcription with a local LLM |

## Whisper Models

The app uses OpenAI's Whisper for transcription. Models are downloaded on first use.

| Model | Size | Speed | Accuracy | Best For |
|-------|------|-------|----------|----------|
| tiny | ~75MB | Fastest | Lower | Quick notes, testing |
| base | ~150MB | Fast | Good | General use |
| small | ~500MB | Medium | Better | Recommended default |
| medium | ~1.5GB | Slow | High | Important transcriptions |
| large | ~3GB | Slowest | Highest | Maximum accuracy |

## Next Steps

- [Configuration Guide](configuration.md) — All settings explained
- [Troubleshooting](troubleshooting.md) — Common issues and fixes
