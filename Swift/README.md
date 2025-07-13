# Swift Components for Speech-to-Text App

This directory contains the Swift components for the macOS speech-to-text application.

## 📁 File Structure

- **SpeechToTextApp.swift** - Main app coordinator and lifecycle management
- **AudioRecorder.swift** - AVAudioEngine wrapper for microphone recording
- **HotkeyManager.swift** - Global hotkey registration (⌘⇧S)
- **PasteManager.swift** - Clipboard operations and cursor positioning
- **PythonBridge.swift** - Subprocess communication with Python scripts
- **Logger.swift** - Timestamped logging system
- **Info.plist** - App configuration and permissions

## 🏗️ Architecture

The app follows a component-based architecture where each Swift file has a single responsibility:

1. **SpeechToTextApp** coordinates all components and manages the app lifecycle
2. **AudioRecorder** handles microphone recording with Whisper-compatible settings
3. **HotkeyManager** registers and handles the global hotkey
4. **PasteManager** manages clipboard operations and text insertion
5. **PythonBridge** executes Python scripts for ML processing
6. **Logger** provides timestamped logging for debugging

## 🔧 Building the Project

### Prerequisites
- Xcode 13+ 
- macOS 12.0+
- Python 3.8+ with required dependencies

### Setup
1. Create a new Xcode project (macOS App)
2. Add all Swift files to the project
3. Add the Info.plist file
4. Configure build settings:
   - Set deployment target to macOS 12.0+
   - Enable App Sandbox (optional)
   - Add required frameworks:
     - AVFoundation
     - Carbon
     - AppKit
     - Foundation

### Required Permissions
The app requires the following permissions:
- **Microphone** - For audio recording
- **Accessibility** - For global hotkeys and cursor positioning
- **Apple Events** - For controlling other apps to paste text

### Dependencies
- **AVFoundation** - Audio recording and playback
- **Carbon** - Global hotkey management
- **AppKit** - macOS UI components
- **Foundation** - Basic functionality

## 🚀 Usage

1. Build and run the app
2. Grant microphone and accessibility permissions when prompted
3. Press ⌘⇧S to start recording
4. Speak into the microphone
5. Press ⌘⇧S again to stop recording
6. The transcribed text will be pasted at the cursor position

## 🔍 Debugging

The app includes comprehensive logging:
- Check the log file in `~/Documents/Logs/transcriptions.log`
- Console output for real-time debugging
- Error handling with user-friendly alerts

## 📝 Notes

- Audio is recorded at 16kHz mono for optimal Whisper compatibility
- Temporary audio files are automatically cleaned up
- The app runs as a menu bar application (LSUIElement = true)
- Global hotkey requires accessibility permissions
- Python scripts should be placed in the `Python/` directory relative to the app bundle 