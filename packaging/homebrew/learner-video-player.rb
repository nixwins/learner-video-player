cask "learner-video-player" do
  version "1.2.0"
  sha256 "8c989ef45c88ffc5bb9fca11764762acf0938c7348e5c578c56d24bfda975b78"

  url "https://github.com/nixwins/learner-video-player/releases/download/v#{version}/LearnerVideoPlayer-#{version}-arm64.zip"
  name "Learner Video Player"
  desc "Video player with clickable subtitles and translation for language learners"
  homepage "https://github.com/nixwins/learner-video-player"

  depends_on arch: :arm64
  depends_on formula: "ffmpeg"
  depends_on formula: "yt-dlp"

  app "LearnerVideoPlayer.app"

  # The app is signed ad-hoc (no paid Apple certificate), so Gatekeeper would
  # block the first start.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/LearnerVideoPlayer.app"]
  end

  zap trash: [
    "~/Library/Preferences/dev.learner.learnerVideoPlayer.plist",
    "~/Library/Application Support/dev.learner.learnerVideoPlayer",
    "~/Library/Caches/dev.learner.learnerVideoPlayer",
  ]
end
