# Configuration

SpeechToTextApp uses a YAML configuration file stored at:

```
~/Library/Application Support/SpeechToTextApp/settings.yaml
```

You can edit settings via the app's Settings UI or by editing the YAML file directly.

## Settings Reference

### Whisper (Speech-to-Text)

```yaml
whisper:
  model: "small"      # tiny, base, small, medium, large
  language: "en"      # Language code or "auto" for detection
  task: "transcribe"  # "transcribe" or "translate" (to English)
  temperature: 0.0    # 0.0-1.0, higher = more creative/random
```

| Option | Values | Description |
|--------|--------|-------------|
| `model` | tiny, base, small, medium, large | Larger models are more accurate but slower |
| `language` | "auto", "en", "es", "fr", etc. | Source language, or auto-detect |
| `task` | transcribe, translate | Translate converts to English |
| `temperature` | 0.0 - 1.0 | Lower = more deterministic |

### Hotkey

```yaml
hotkey:
  key_code: 37           # macOS key code (37 = L)
  modifiers: ["option"]  # command, option, control, shift
```

Common key codes:
- `37` = L
- `0` = A
- `49` = Space
- `36` = Return

Use the Settings UI to record a new hotkey — it will set these values automatically.

### Server

```yaml
server:
  host: "localhost"
  port: 3001
  uv_path: "/opt/homebrew/bin/uv"
```

| Option | Description |
|--------|-------------|
| `host` | Server bind address |
| `port` | Server port (0 = auto-select) |
| `uv_path` | Path to `uv` executable |

### Audio

```yaml
audio:
  sample_rate: 16000  # Required: 16kHz for Whisper
  channels: 1         # Required: mono
  format: wav
```

These should not be changed — Whisper requires 16kHz mono audio.

### LLM Post-Processing (Optional)

```yaml
llm:
  enabled: true
  base_url: "http://localhost:11434"
  model: "llama3.2"
  temperature: 0.1
  max_tokens: 100
  prompt: null  # Custom prompt, or null for default
```

Requires [Ollama](https://ollama.ai) running locally. When enabled, transcribed text is cleaned up by the LLM before pasting.

| Option | Description |
|--------|-------------|
| `enabled` | true/false to toggle |
| `base_url` | Ollama API URL |
| `model` | Ollama model name |
| `temperature` | 0.0-1.0, lower = more consistent |
| `max_tokens` | Maximum response length |
| `prompt` | Custom system prompt (null = default) |

### Logging

```yaml
logging:
  enabled: true
  log_file: "transcriptions.log"
  max_file_size: "10MB"
  backup_count: 5
```

Logs are stored in `~/Library/Application Support/SpeechToTextApp/`.

## Live Reloading

Settings changes are applied automatically:

| Change | Behavior |
|--------|----------|
| Whisper model/settings | Model reloads via API (may take a moment) |
| Hotkey | Applies immediately |
| Server host/port | Server restarts |
| LLM settings | Applies on next transcription |

## Full Example

```yaml
stt:
  provider: "whisper"

server:
  host: "localhost"
  port: 3001
  uv_path: "/opt/homebrew/bin/uv"

audio:
  sample_rate: 16000
  channels: 1
  format: wav

whisper:
  model: "small"
  language: "auto"
  task: "transcribe"
  temperature: 0.0

llm:
  enabled: false
  base_url: "http://localhost:11434"
  model: "llama3.2"
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
