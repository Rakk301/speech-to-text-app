# SpeechToTextApp - Packaging & GitHub Setup Summary

## Project Context

**SpeechToTextApp** is a macOS-native speech-to-text utility that:
- Runs offline with a global hotkey trigger (⌘⇧S)
- Transcribes real-time microphone input using Whisper
- Applies optional LLM-based post-processing
- Pastes the final output at the cursor

### Architecture
- **Swift Frontend**: UI, system integration (hotkeys, audio capture, paste operations)
- **Python Backend**: ML inference (Whisper STT, LLM post-processing) managed by `uv`
- **Communication**: HTTP between Swift and Python server

### Repository Location
```
/Users/rakhshaanhussain/Personal Projects/Speech To Text App
```

### GitHub Details
- **Username**: Rakk301
- **Target Repo Name**: speech-to-text-app (not yet pushed)

---

## Goal

Package the application for distribution beyond Xcode and establish GitHub best practices for easy installation and contribution.

### Key Decisions Made
| Decision | Choice |
|----------|--------|
| Distribution Method | Homebrew Cask |
| Apple Developer Account | None (no notarization) |
| Python/uv Handling | Homebrew auto-installs via `depends_on formula: "uv"` |
| License | MIT |
| Target Audience | Developers/technical users |

---

## Task Checklist

### Step 1: Create License File ✅ COMPLETE
- File: `LICENSE`
- Content: MIT License with "Copyright (c) 2024 Rakhshaan Hussain"

### Step 2: Add uv Detection ✅ COMPLETE
- Simplified approach: Homebrew Cask handles `uv` installation automatically
- No in-app UI alerts needed
- Cask formula includes: `depends_on formula: "uv"`

### Step 3: Homebrew Cask Formula Setup ✅ COMPLETE
- File: `docs/homebrew/speechtotextapp.rb`
- Instructions included for creating a Homebrew tap
- Requires creating `homebrew-speechtotextapp` repo on GitHub

### Step 4: Update README.md ✅ COMPLETE
- Rewritten to be concise and user-focused
- Homebrew-first installation instructions
- Links to detailed documentation in `docs/`

### Step 5: Create/Update Documentation ✅ COMPLETE
Files in `docs/`:
- `getting-started.md` - Installation and first run
- `configuration.md` - Settings reference
- `architecture.md` - System design
- `development.md` - Building from source
- `troubleshooting.md` - Common issues
- `releasing.md` - Release process for maintainers
- `CONTRIBUTING.md` - Contribution guidelines

### Step 6: CI/CD Workflows 🔄 IN PROGRESS

#### build.yml ✅ COMPLETE
- File: `.github/workflows/build.yml`
- Triggers: Push/PR to `main`
- Actions: Checkout → Setup Xcode 15 → Install uv → Sync Python deps → Build app

#### release.yml ❌ NEEDS FIXING
- File: `.github/workflows/release.yml`
- **Current Issue**: Contains duplicate/incomplete "Create Release" steps (lines 58-76)

**Corrected release.yml content** (replace entire file):

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-release:
    name: Build and Release
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.0'

      - name: Install uv
        uses: astral-sh/setup-uv@v4

      - name: Install Python dependencies
        run: |
          cd stt-server-py
          uv sync

      - name: Build App for Release
        run: |
          xcodebuild -project SpeechToTextApp.xcodeproj \
            -scheme SpeechToTextApp \
            -configuration Release \
            -destination 'platform=macOS' \
            -archivePath $RUNNER_TEMP/SpeechToTextApp.xcarchive \
            archive

      - name: Export App
        run: |
          xcodebuild -exportArchive \
            -archivePath $RUNNER_TEMP/SpeechToTextApp.xcarchive \
            -exportPath $RUNNER_TEMP/export \
            -exportOptionsPlist ExportOptions.plist || \
          cp -R $RUNNER_TEMP/SpeechToTextApp.xcarchive/Products/Applications/SpeechToTextApp.app $RUNNER_TEMP/export/

      - name: Create ZIP
        run: |
          cd $RUNNER_TEMP/export
          zip -r SpeechToTextApp.zip SpeechToTextApp.app

      - name: Get SHA256
        id: sha
        run: |
          SHA=$(shasum -a 256 $RUNNER_TEMP/export/SpeechToTextApp.zip | awk '{print $1}')
          echo "sha256=$SHA" >> $GITHUB_OUTPUT

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: ${{ runner.temp }}/export/SpeechToTextApp.zip
          body: |
            ## Installation

            ### Homebrew (Recommended)
            ```bash
            brew install --cask speechtotextapp
            ```

            ### Manual Download
            1. Download `SpeechToTextApp.zip` below
            2. Unzip and move to Applications
            3. On first launch: System Settings → Privacy & Security → Open Anyway

            ## SHA256
            ```
            ${{ steps.sha.outputs.sha256 }}
            ```
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Step 7: GitHub Templates ⏳ PENDING
Need to create:
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

---

## Immediate Next Actions

1. **Fix release.yml**: Replace `.github/workflows/release.yml` with the corrected content above

2. **Create GitHub Templates** (Step 7):
   - Bug report template
   - Feature request template
   - PR template

3. **Optional Enhancements** (discussed but not prioritized):
   - Automated changelog generation
   - Homebrew formula auto-update on release

---

## File Structure Reference

```
Speech To Text App/
├── .github/
│   └── workflows/
│       ├── build.yml          ✅ Complete
│       └── release.yml        ❌ Needs fix
├── docs/
│   ├── homebrew/
│   │   └── speechtotextapp.rb ✅ Complete
│   ├── architecture.md        ✅ Complete
│   ├── configuration.md       ✅ Complete
│   ├── CONTRIBUTING.md        ✅ Complete
│   ├── development.md         ✅ Complete
│   ├── getting-started.md     ✅ Complete
│   ├── releasing.md           ✅ Complete
│   └── troubleshooting.md     ✅ Complete
├── Swift/                      (app source)
├── stt-server-py/              (Python backend)
├── LICENSE                    ✅ Complete (MIT)
├── README.md                  ✅ Complete
└── SpeechToTextApp.xcodeproj/
```

---

## Notes for Continuation

- **Branch**: `feat/packaging`
- **No Apple Developer Account**: App is unsigned, users must allow via "Open Anyway"
- **uv dependency**: Handled entirely by Homebrew Cask, no in-app checks
- **macOS requirement**: Sonoma (14.0) or later


