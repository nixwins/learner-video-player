cask "learner-video-player" do
  version "1.0.0"
  sha256 "eaea2d92366b9be2a83e9f66a94ab755f3a53009c3a92a1886b9b4ee62e63162"

  url "https://github.com/nixwins/learner-video-player/releases/download/v#{version}/LearnerVideoPlayer-#{version}-arm64.zip"
  name "Learner Video Player"
  desc "Video player with clickable subtitles and translation for language learners"
  homepage "https://github.com/nixwins/learner-video-player"

  depends_on arch: :arm64
  depends_on formula: "ffmpeg"
  depends_on formula: "yt-dlp"

  app "Learner Video Player.app"

  # The app is signed ad-hoc (no paid Apple certificate), so Gatekeeper would
  # block the first start.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Learner Video Player.app"]
  end

  zap trash: [
    "~/Library/Preferences/dev.learner.learnerVideoPlayer.plist",
    "~/Library/Application Support/dev.learner.learnerVideoPlayer",
    "~/Library/Caches/dev.learner.learnerVideoPlayer",
  ]
end
