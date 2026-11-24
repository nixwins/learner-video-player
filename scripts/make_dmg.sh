#!/usr/bin/env bash
# Builds two release files for macOS:
#   - a disk image with the app plus ffmpeg and yt-dlp inside (manual install)
#   - a slim zip without them (used by the Homebrew cask, which installs
#     ffmpeg and yt-dlp as dependencies)
# Usage: ./scripts/make_dmg.sh
set -euo pipefail
cd "$(dirname "$0")/.."

case "$(uname -m)" in
  arm64) ARCH=arm64; FFMPEG_ARCH=arm64 ;;
  x86_64) ARCH=x86_64; FFMPEG_ARCH=amd64 ;;
  *) echo "Unsupported CPU: $(uname -m)" >&2; exit 1 ;;
esac

VERSION=$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)
APP_NAME="Learner Video Player"
VENDOR="build/vendor/$ARCH"
STAGE="build/dmg/stage"
DMG="build/dmg/LearnerVideoPlayer-$VERSION-$ARCH.dmg"
ZIP="build/dmg/LearnerVideoPlayer-$VERSION-$ARCH.zip"

echo "==> Downloading ffmpeg and yt-dlp ($ARCH)"
mkdir -p "$VENDOR"
if [ ! -x "$VENDOR/ffmpeg" ]; then
  curl -fL -o "$VENDOR/ffmpeg.zip" \
    "https://ffmpeg.martin-riedl.de/redirect/latest/macos/$FFMPEG_ARCH/release/ffmpeg.zip"
  unzip -oq "$VENDOR/ffmpeg.zip" -d "$VENDOR"
  rm "$VENDOR/ffmpeg.zip"
fi
if [ ! -x "$VENDOR/yt-dlp" ]; then
  curl -fL -o "$VENDOR/yt-dlp" \
    "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos"
fi
chmod +x "$VENDOR/ffmpeg" "$VENDOR/yt-dlp"

echo "==> Building the app"
flutter build macos --release
BUILT="build/macos/Build/Products/Release/learner_video_player.app"

echo "==> Assembling $APP_NAME.app"
rm -rf "$STAGE"
mkdir -p "$STAGE"
APP="$STAGE/$APP_NAME.app"
cp -R "$BUILT" "$APP"
mkdir -p "$APP/Contents/Resources/bin"
cp "$VENDOR/ffmpeg" "$VENDOR/yt-dlp" "$APP/Contents/Resources/bin/"

# Without a paid Apple certificate the best we can do is an ad-hoc signature.
# It is still required: Apple Silicon refuses to run unsigned code.
codesign --force --sign - "$APP/Contents/Resources/bin/ffmpeg"
codesign --force --sign - "$APP/Contents/Resources/bin/yt-dlp"
codesign --force --sign - --entitlements macos/Runner/Release.entitlements "$APP"
codesign --verify --strict "$APP"

echo "==> Creating the slim zip for Homebrew"
SLIM="build/dmg/slim"
rm -rf "$SLIM" "$ZIP"
mkdir -p "$SLIM"
cp -R "$BUILT" "$SLIM/$APP_NAME.app"
codesign --force --sign - --entitlements macos/Runner/Release.entitlements "$SLIM/$APP_NAME.app"
codesign --verify --strict "$SLIM/$APP_NAME.app"
ditto -c -k --keepParent "$SLIM/$APP_NAME.app" "$ZIP"
rm -rf "$SLIM"

ln -s /Applications "$STAGE/Applications"

echo "==> Creating the disk image"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
echo "Done:"
echo "  $DMG ($(du -h "$DMG" | cut -f1))"
echo "  $ZIP ($(du -h "$ZIP" | cut -f1))"
echo "  zip sha256: $(shasum -a 256 "$ZIP" | cut -d' ' -f1)"
