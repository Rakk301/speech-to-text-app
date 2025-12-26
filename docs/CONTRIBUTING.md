# Contributing

Thank you for your interest in contributing to SpeechToTextApp! This guide will help you get started.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/speech-to-text-app.git
   cd speech-to-text-app
   ```
3. **Set up the development environment** — See [Development Guide](docs/development.md)

## Making Changes

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes

- Keep changes focused and atomic
- Follow the code style guidelines below
- Update documentation if needed
- Add/update tests if applicable

### 3. Test Your Changes

**Swift changes:**
- Build and run in Xcode
- Test the affected functionality manually

**Python changes:**
- Run the server manually and test endpoints
- Verify transcription still works

```bash
cd stt-server-py
uv run python transcription_server.py settings.yaml --port 3001
```

### 4. Commit Your Changes

Write clear commit messages:

```bash
# Good
git commit -m "Add support for custom prompts in LLM processing"
git commit -m "Fix hotkey not registering on app restart"

# Bad
git commit -m "Fixed stuff"
git commit -m "WIP"
```

### 5. Push and Create a Pull Request

```bash
git push origin feature/your-feature-name
```

Then open a Pull Request on GitHub with:
- Clear description of what changed and why
- Steps to test the changes
- Screenshots if UI changes are involved

## Code Style

### Swift

- **One file per component** — Each Swift file should have a single responsibility
- **Use Logger** — All logging through the `Logger` class
- **Prefer async/await** — For asynchronous operations
- **Follow existing patterns** — Look at similar code in the codebase

Example:
```swift
// Good
logger.log("Starting transcription", level: .info)

// Bad
print("Starting transcription")
```

### Python

- **Type hints** — Add type hints to all function signatures
- **Use logging** — Not `print()` statements
- **Keep it simple** — CLI scripts should be easy to test independently

Example:
```python
# Good
def transcribe_audio(audio_path: str, model: str = "small") -> str:
    logger.info(f"Transcribing {audio_path} with model {model}")
    ...

# Bad
def transcribe_audio(audio_path, model="small"):
    print(f"Transcribing {audio_path}")
    ...
```

## Architecture Guidelines

- **Swift handles system integration** — Hotkeys, audio, clipboard, UI
- **Python handles ML** — Whisper, LLM, audio processing
- **Communication via HTTP** — Clean separation between Swift and Python

See [Architecture](docs/architecture.md) for details.

## What to Contribute

### Good First Issues

Look for issues labeled `good first issue` — these are great for newcomers.

### Ideas Welcome

- Bug fixes
- Documentation improvements
- Performance optimizations
- New features (discuss in an issue first)

### Please Avoid

- Large refactors without prior discussion
- Breaking changes to the configuration format
- Adding heavy dependencies without justification

## Questions?

- Open an issue for bugs or feature requests
- Start a discussion for questions or ideas

Thank you for contributing!
