# Learner Video Player

A desktop video player for people who learn English by watching movies and series.

**Click any word in the subtitles → the video pauses → a Google Translate panel slides in on the right, inside the same window, with that word translated into your language.**

- Plays `mp4`, `mov` and `avi` files
- Pick the audio track and the subtitles
- Load your own `.srt` subtitle file (or drag it onto the window)
- Every subtitle word is clickable
- Translates from English into the language you choose (Kazakh by default, your choice is remembered)

Works on **macOS**. Windows is not supported yet: the embedded translation panel uses a web view that currently exists only for macOS.

---

## Table of contents

1. [What you need](#1-what-you-need)
2. [Install on macOS, step by step](#2-install-on-macos-step-by-step)
3. [Download and start the app](#3-download-and-start-the-app)
4. [How to use it](#4-how-to-use-it)
5. [Troubleshooting](#5-troubleshooting)
6. [For developers](#6-for-developers)

---

## 1. What you need

| Thing | Why | Free? |
| --- | --- | --- |
| A Mac (macOS 10.15 or newer) | To run the app | – |
| Internet connection | To download tools once, and for Google Translate while watching | – |
| About 10 GB of free disk space | Xcode and Flutter are big | – |
| **Flutter** | The framework the app is built with | Yes |
| **Xcode** | Builds the native app | Yes |
| **Git** | Downloads the project | Yes |

You do **not** need to know how to program. You will copy and paste a few commands.

> **What is the Terminal?** It is a window where you type commands.
> On a Mac press `Cmd + Space`, type `Terminal` and press `Enter`.
> Every grey box below that looks like code is a command: copy it, paste it into the Terminal, press `Enter`, and wait until it finishes.

---

## 2. Install on macOS, step by step

### Step 1. Install Xcode

1. Open the **App Store**, search for **Xcode** and click **Get**. It is large (several GB), so it takes a while.
2. When it has installed, open **Terminal** and run these two commands (the first asks for your Mac password; you will not see the characters while typing, that is normal):

```bash
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept
```

### Step 2. Install Homebrew (a tool that installs other tools)

Skip this step if you already have Homebrew (check with `brew --version`).

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

When it finishes, it prints a section called **Next steps** with two or three commands. **Copy and run those commands too**, otherwise the `brew` command will not be found.

### Step 3. Install Git, CocoaPods and Flutter

```bash
brew install git cocoapods
brew install --cask flutter
```

### Step 4. Check that everything is ready

```bash
flutter doctor
```

You should see green check marks next to **Flutter** and **Xcode - develop for iOS and macOS**.
Other lines (Android, Chrome) can be ignored: this app only needs macOS.

If something under macOS is red, see [Troubleshooting](#6-troubleshooting).

---

## 3. Download and start the app

### Step 1. Download the project

```bash
cd ~
git clone https://github.com/nixwins/learner-video-player.git
cd learner-video-player
```

### Step 2. Install the project's packages and run the checks

```bash
chmod +x setup.sh
./setup.sh
```

This downloads the libraries the app uses, switches off a macOS setting that would stop the player from reading your video files (see [the note below](#a-note-about-the-macos-sandbox)), and runs the automatic tests. At the end you should see `All tests passed!` and `Ready.`

The first run takes a few minutes. You only need to do this step once.

### Step 3. Start the app

```bash
flutter run -d macos
```

The first start takes a few minutes because the app is being built. Next starts are much faster. A window called **learner_video_player** will open.

To stop the app, close its window, or press `q` in the Terminal.

### Starting it again later

Open Terminal, go to the project folder and run it again:

```bash
cd ~/learner-video-player
flutter run -d macos
```

### Updating to a newer version

```bash
cd ~/learner-video-player
git pull
flutter pub get
flutter run -d macos
```

### A note about the macOS sandbox

By default macOS apps are "sandboxed" and may only read files you explicitly allow. A video player has to read the video **and** the subtitle file next to it, so `setup.sh` turns the App Sandbox **off** for this project. This is fine for an app you build and run yourself. It would have to be redone properly before publishing to the Mac App Store.

---

## 4. How to use it

### Open a video

- Click the **folder icon** at the bottom left and choose a video file, **or**
- **Drag and drop** a video file onto the window.

### Pause and play

- Click the **play / pause button**, press **Space**, or click the video.
- The control bar hides itself while the video plays. Move the mouse to show it again.

### Choose the audio track

Click the **music note** button in the control bar and pick a track (for example the original English one).

### Subtitles

Click the **CC** button in the control bar:

- Pick one of the subtitle tracks that are inside the video file, or
- choose **Off** to hide them, or
- choose **Load file…** and select an `.srt` file. You can also **drag an `.srt` file onto the window**.

### Translate a word

1. Make sure subtitles are on.
2. **Click any word** in the subtitle.
3. The video pauses and a **translation panel opens on the right**, in the same window (English → your language). The video shrinks to make room, and the word stays highlighted in the subtitle.
4. Drag the thin divider between the video and the panel to change the panel width. The app remembers it.
5. Click a different word to translate it, or close the panel with the **×** button or the **Esc** key.
6. Press **Space** (or click the video) to continue watching.

### Change the language you translate into

Click the **translate** button (the one with the two letters) in the control bar and pick a language. The app remembers it next time.

### Keyboard shortcuts

| Key | Action |
| --- | --- |
| `Space` | Play / pause |
| `Esc` | Close the translation panel |

### Not supported yet

- Volume slider and full screen
- Picture-based subtitles (PGS / VobSub, common on Blu-ray rips). They are images, not text, so words cannot be clicked. Use a text subtitle track or an `.srt` file instead.

---

## 5. Troubleshooting

**`zsh: command not found: flutter`**
Flutter is not on your PATH. Close the Terminal and open a new one. If it still fails, run `brew install --cask flutter` again and read what Homebrew prints at the end.

**`zsh: command not found: brew`**
Homebrew's "Next steps" commands (end of [Step 2](#step-2-install-homebrew-a-tool-that-installs-other-tools)) were not run. Run them, then open a new Terminal window.

**`zsh: permission denied: ./setup.sh`**
Run `chmod +x setup.sh` once, then `./setup.sh` again.

**`flutter doctor` says Xcode is incomplete, or asks to accept the license**
Run:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept
```

**`flutter doctor` says CocoaPods is not installed**
Run `brew install cocoapods`.

**The build fails with a CocoaPods / `pod install` error**

```bash
cd macos
pod repo update
cd ..
flutter clean
flutter pub get
flutter run -d macos
```

**The video does not play, or there is no sound**
Make sure the file is a normal `mp4`, `mov` or `avi`. Try another file to check that it is not the file itself.

**Subtitles do not appear**
Open the **Subtitles** menu and choose a track, or choose **Load file…** and pick an `.srt`. Put the subtitle file next to the video with the same name (`movie.mp4` + `movie.srt`) if you want to find it easily.

**The translation panel shows "Could not load the translation"**
It needs an internet connection. Check it and press **Retry**.

**Clicking a word does nothing**
Subtitles in the video may be picture-based. Switch to another subtitle track or load an `.srt` file.

**Anything else**
Run the app with `flutter run -d macos` and look at the messages in the Terminal. Copy them into a new issue at <https://github.com/nixwins/learner-video-player/issues>.

---

## 6. For developers

### Commands

```bash
flutter pub get      # install packages
flutter analyze      # static analysis
flutter test         # run unit and widget tests
```

### Architecture (feature-first, 3 layers)

`presentation → domain ← data`. The `domain` layer is plain Dart code plus interfaces.

```
lib/
  core/            shared: Choice, languages, media types, duration format, OptionMenuButton
  features/
    player/        PlayerGateway (domain) ← MediaKitPlayerGateway (data); page, controls, menus
    subtitles/     tokenizeSubtitle (domain); ClickableSubtitle (presentation)
    translation/   buildTranslateUri, TranslateWord, TranslationLauncher (domain);
                   WebviewTranslationLauncher (data); TranslationPanel (presentation)
    settings/      SettingsRepository (domain) ← PrefsSettingsRepository (data); native language
  main.dart        composition root: the only place that wires concrete implementations
```

### Libraries

| Library | Used for |
| --- | --- |
| `media_kit` (libmpv) | Playback, audio tracks, subtitle tracks and the text of the current subtitle |
| `webview_flutter` | The translation panel (embedded web view) |
| `flutter_riverpod` | State management and dependency injection |
| `shared_preferences` | Remembering the chosen language |
| `file_selector` | Open-file dialogs |
| `desktop_drop` | Drag and drop |

Each third-party library is used in exactly one file (or one thin layer), so it can be replaced without touching the UI.

### Known limits

- Picture-based subtitles (PGS / VobSub) cannot be clicked (no OCR).
- Whether a `.srt` next to the video is picked up automatically depends on mpv; if it is not, load it manually.
- No volume slider and no full screen yet.
- macOS only: `webview_flutter` has no Windows implementation.
