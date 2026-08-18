import SwiftUI
import AppKit

enum QxCarWindowMetrics {
    static let width: CGFloat = 440
    static let height: CGFloat = 270
    static var size: NSSize { NSSize(width: width, height: height) }
}

@main
struct QxCarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: QxCarWindowMetrics.width, height: QxCarWindowMetrics.height)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.async {
            self.configureLiquidGlassWindow()
        }
    }

    func configureLiquidGlassWindow() {
        for window in NSApplication.shared.windows {
            window.title = "QxCar"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .none
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            window.contentMinSize = QxCarWindowMetrics.size
            window.contentMaxSize = QxCarWindowMetrics.size
            window.setContentSize(QxCarWindowMetrics.size)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
