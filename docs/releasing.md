# Releasing Guide

This guide covers how to create a new release of SpeechToTextApp.

## Version Numbering

We use [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH** (e.g., `1.2.3`)
- **MAJOR** — Breaking changes
- **MINOR** — New features, backwards compatible
- **PATCH** — Bug fixes, backwards compatible

## Release Checklist

### 1. Prepare the Release

- [ ] Update version in Xcode project (General → Version)
- [ ] Update `CHANGELOG.md` with changes since last release
- [ ] Commit changes: `git commit -m "chore: prepare v1.x.x release"`

### 2. Build the App

1. Open `SpeechToTextApp.xcodeproj` in Xcode
2. Select **Product → Archive**
3. In the Organizer, select the archive
4. Click **Distribute App**
5. Choose **Copy App** (we're not notarizing)
6. Export to a folder

### 3. Create ZIP

```bash
cd /path/to/exported
zip -r SpeechToTextApp.zip SpeechToTextApp.app
```

### 4. Get SHA256 Hash

```bash
shasum -a 256 SpeechToTextApp.zip
```

Save this hash — you'll need it for Homebrew.

### 5. Create Git Tag

```bash
git tag -a v1.x.x -m "Release v1.x.x"
git push origin v1.x.x
```

### 6. Create GitHub Release

1. Go to [GitHub Releases](https://github.com/Rakk301/speech-to-text-app/releases)
2. Click **Draft a new release**
3. Select the tag you just created
4. Title: `v1.x.x`
5. Description: Copy from CHANGELOG.md
6. Attach `SpeechToTextApp.zip`
7. Click **Publish release**

### 7. Update Homebrew Cask

Update the Cask formula in your tap repository:

1. Edit `Casks/speechtotextapp.rb`:
   ```ruby
   version "1.x.x"
   sha256 "YOUR_SHA256_HASH_HERE"
   ```

2. Commit and push:
   ```bash
   git commit -am "Update to v1.x.x"
   git push
   ```

Users can now install/upgrade via:
```bash
brew upgrade --cask speechtotextapp
```

## Setting Up Your Homebrew Tap

If you haven't set up your tap yet:

### 1. Create the Tap Repository

Create a new GitHub repository named `homebrew-speechtotextapp`.

### 2. Add the Cask Formula

```bash
git clone https://github.com/Rakk301/homebrew-speechtotextapp.git
cd homebrew-speechtotextapp
mkdir Casks
cp /path/to/speech-to-text-app/docs/homebrew/speechtotextapp.rb Casks/
```

### 3. Update and Push

Edit `Casks/speechtotextapp.rb`:
- Set correct `version`
- Set correct `sha256`

```bash
git add .
git commit -m "Add speechtotextapp cask"
git push
```

### 4. Test Installation

```bash
brew tap Rakk301/speechtotextapp
brew install --cask speechtotextapp
```

## Automating Releases (Future)

See the CI/CD setup for automating:
- Build verification on PRs
- Tag-triggered releases
- Automatic changelog generation
- Homebrew formula updates

## Troubleshooting Releases

### Archive fails to build

- Check all Swift files compile without errors
- Ensure signing settings are correct (can be "Sign to Run Locally")

### Users report "damaged" app

The app was modified after download. Users should:
```bash
xattr -cr /Applications/SpeechToTextApp.app
```

### Homebrew formula doesn't update

Users may need to:
```bash
brew update
brew upgrade --cask speechtotextapp
```

Or force reinstall:
```bash
brew reinstall --cask speechtotextapp
```
