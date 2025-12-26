# Homebrew Cask formula for SpeechToTextApp
#
# To use this formula, you need to create a Homebrew tap:
#   1. Create a new GitHub repo named: homebrew-speechtotextapp
#   2. Copy this file to: Casks/speechtotextapp.rb in that repo
#   3. Users can then install via:
#      brew tap Rakk301/speechtotextapp
#      brew install --cask speechtotextapp
#
# Before publishing, update:
#   - version: Match your GitHub release tag (without 'v' prefix)
#   - sha256: Run `shasum -a 256 SpeechToTextApp.zip` on your release artifact

cask "speechtotextapp" do
  version "0.1.0"
  sha256 "REPLACE_WITH_SHA256_OF_YOUR_ZIP"

  url "https://github.com/Rakk301/speech-to-text-app/releases/download/v#{version}/SpeechToTextApp.zip"
  name "SpeechToTextApp"
  desc "macOS speech-to-text utility with Whisper and optional LLM post-processing"
  homepage "https://github.com/Rakk301/speech-to-text-app"

  depends_on formula: "uv"
  depends_on macos: ">= :sonoma"

  app "SpeechToTextApp.app"

  caveats <<~EOS
    On first launch, you may need to allow the app in:
      System Settings → Privacy & Security → Open Anyway

    Grant these permissions when prompted:
      - Microphone access (for speech recording)
      - Accessibility access (for global hotkey and paste-at-cursor)
  EOS

  zap trash: [
    "~/Library/Application Support/SpeechToTextApp",
  ]
end
