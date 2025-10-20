# Configuration

The app and Python server share a YAML-based configuration. By default, the Swift app writes the file to:

- `~/Library/Application Support/SpeechToTextApp/settings.yaml`

The Python server accepts a path to a YAML file (default `settings.yaml` in its working directory). When launched by the app, it is passed the App Support path.

## Example (stt-server-py/settings.yaml)
```yaml
stt:
  provider: "whisper"

server:
  host: "localhost"
  port: 3001
  uv_path: "/opt/homebrew/bin/uv"
  script_path: "transcription_server.py"

audio:
  sample_rate: 16000
  channels: 1
  format: wav
  chunk_duration: 3

whisper:
  model: "small"
  language: "en"
  task: "transcribe"
  temperature: 0.0

llm:
  base_url: "http://localhost:11434"
  enabled: true
  model: "g3-1b"
  temperature: 0.1
  max_tokens: 100
  prompt: null

hotkey:
  key_code: 37
  modifiers: ["option"]

logging:
  enabled: true
  log_file: "transcriptions.log"
  max_file_size: "10MB"
  backup_count: 5
```

## Key Sections
- whisper: model, language, task, temperature
- hotkey: key_code, modifiers
- server: host, port, uv_path (used by embedded mode)
- audio: sample_rate, channels, format, chunk_duration
- llm: enabled, model, base_url, temperature, max_tokens, prompt
- logging: enabled, log_file, max_file_size, backup_count

## Live Updates
- Whisper changes trigger model reload via `/reload_model` (fallback: restart)
- Server host/port changes trigger server restart
- Hotkey changes apply immediately in Swift

