import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private static let preferredSize = NSSize(width: 1280, height: 800)

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    let available = (self.screen ?? NSScreen.main)?.visibleFrame.size
    let size = NSSize(
      width: min(Self.preferredSize.width, available?.width ?? Self.preferredSize.width),
      height: min(Self.preferredSize.height, available?.height ?? Self.preferredSize.height)
    )
    self.setContentSize(size)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
