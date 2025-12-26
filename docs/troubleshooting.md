# Troubleshooting

Common issues and solutions for SpeechToTextApp.

## Installation Issues

### "App can't be opened because Apple cannot check it for malicious software"

The app is not notarized. To open it:

1. Go to **System Settings → Privacy & Security**
2. Scroll down to find the message about SpeechToTextApp
3. Click **Open Anyway**
4. Click **Open** in the confirmation dialog

### "uv: command not found" or server won't start

The `uv` package manager is required. Install it:

```bash
brew install uv
```

If installed via Homebrew but still not found, check your PATH:

```bash
echo $PATH | grep -q "/opt/homebrew/bin" || echo "Homebrew not in PATH"
```

## Permission Issues

### Global hotkey not working

1. Open **System Settings → Privacy & Security → Accessibility**
2. Find SpeechToTextApp in the list
3. Toggle it **off**, then **on** again
4. Restart the app

If the app isn't in the list, try pressing the hotkey once — this should trigger the permission prompt.

### Microphone permission denied

1. Open **System Settings → Privacy & Security → Microphone**
2. Ensure SpeechToTextApp is toggled **on**
3. If not listed, remove and re-add the app, or reset permissions:
   ```bash
   tccutil reset Microphone com.yourname.SpeechToTextApp
   ```

### "Recording failed" error

- Check another app isn't using the microphone exclusively
- Verify your input device is selected in **System Settings → Sound → Input**
- Try unplugging and reconnecting external microphones

## Server Issues

### "Server connection failed" or transcription hangs

Check if the server is running:

```bash
curl http://localhost:3001/health
```

If no response:
- The server may still be starting (first launch downloads models)
- Check Console.app for errors from SpeechToTextApp
- Try restarting the app

### Port already in use

If the configured port is busy, the app auto-selects a free port. To manually fix:

```bash
# Find what's using the port
lsof -i :3001

# Kill the process if needed
kill -9 <PID>
```

Or change the port in Settings.

### Python/uv errors

Re-sync dependencies:

```bash
cd /Applications/SpeechToTextApp.app/Contents/Resources/stt-server-py
uv sync
```

If building from source:

```bash
cd stt-server-py
uv sync
```

## Transcription Issues

### Slow transcription

1. **Use a smaller model** — Settings → Whisper Model → "small" or "base"
2. **Disable LLM post-processing** — Settings → LLM → Enabled: Off
3. **Check CPU usage** — Another process may be competing for resources

### Poor accuracy

1. **Use a larger model** — "medium" or "large" are more accurate
2. **Speak clearly** — Whisper works best with clear speech
3. **Reduce background noise** — Use a better microphone or quieter environment
4. **Specify language** — Set the language explicitly instead of "auto"

### First transcription is very slow

This is normal. On first use, Whisper downloads the model:

| Model | Download Size |
|-------|---------------|
| tiny | ~75 MB |
| base | ~150 MB |
| small | ~500 MB |
| medium | ~1.5 GB |
| large | ~3 GB |

Subsequent transcriptions are much faster.

### Text not pasting

1. **Check cursor position** — Click where you want text before starting
2. **Check Accessibility permission** — Required for paste simulation
3. **Try a different app** — Some apps block paste simulation

## LLM Post-Processing Issues

### LLM not working

LLM post-processing requires [Ollama](https://ollama.ai) running locally:

```bash
# Install Ollama
brew install ollama

# Start Ollama
ollama serve

# Pull a model
ollama pull llama3.2
```

Verify Ollama is running:

```bash
curl http://localhost:11434/api/tags
```

### LLM making transcription worse

Disable it: Settings → LLM → Enabled: Off

Or try a different model in Settings → LLM → Model.

## Log Files

Check logs for detailed error information:

```bash
# App logs
cat ~/Library/Application\ Support/SpeechToTextApp/transcriptions.log

# System logs (if app crashes)
log show --predicate 'process == "SpeechToTextApp"' --last 10m
```

## Reset Everything

If nothing works, reset to defaults:

```bash
# Remove settings
rm ~/Library/Application\ Support/SpeechToTextApp/settings.yaml

# Remove app data
rm -rf ~/Library/Application\ Support/SpeechToTextApp

# Re-download Whisper models (they're cached by the Python package)
rm -rf ~/.cache/whisper
```

Then restart the app.

## Getting Help

If you're still stuck:

1. Check [existing issues](https://github.com/Rakk301/speech-to-text-app/issues)
2. Open a [new issue](https://github.com/Rakk301/speech-to-text-app/issues/new) with:
   - macOS version
   - Steps to reproduce
   - Relevant log output
