cask "learner-video-player" do
  version "1.1.0"
  sha256 "8ccda72193ce43dfa3f5e14438df5e62597896e13b20ceec7affc2f81c14163c"

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
