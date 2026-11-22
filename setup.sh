#!/usr/bin/env bash
# One-time project setup. Run on your Mac:  ./setup.sh
set -euo pipefail
cd "$(dirname "$0")"

command -v flutter >/dev/null || { echo "flutter is not in PATH"; exit 1; }

if [ ! -f pubspec.yaml ]; then
  # Generate platform folders + pubspec with the SDK constraints of YOUR
  # Flutter version, without touching lib/ and test/.
  tmp="$(mktemp -d)"
  flutter create --platforms=macos,windows --org dev.learner \
    --project-name learner_video_player "$tmp/app"
  cp -R "$tmp/app/macos" "$tmp/app/windows" .
  cp "$tmp/app/pubspec.yaml" "$tmp/app/analysis_options.yaml" \
     "$tmp/app/.gitignore" "$tmp/app/.metadata" .
  rm -rf "$tmp"

  flutter pub add media_kit media_kit_video media_kit_libs_video \
    flutter_riverpod shared_preferences file_selector desktop_drop \
    desktop_webview_window
fi

# macOS: a video player needs to read arbitrary files (video + sibling .srt),
# so the App Sandbox is turned off (fine for development / direct download;
# the Mac App Store would need sandbox + security-scoped bookmarks).
if [ "$(uname)" = "Darwin" ]; then
  for f in macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements; do
    /usr/libexec/PlistBuddy -c "Set :com.apple.security.app-sandbox false" "$f"
  done
fi

if ! command -v yt-dlp >/dev/null; then
  echo "Note: YouTube links need yt-dlp. Install it with: brew install yt-dlp"
fi

flutter pub get
dart format lib test
flutter analyze || echo "(analyze reported issues above, fix or send them to Claude)"
flutter test

echo
echo "Ready. Run:  flutter run -d macos     (or: flutter run -d windows)"
