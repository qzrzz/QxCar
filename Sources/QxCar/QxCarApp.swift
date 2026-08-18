import SwiftUI
import AppKit
import QxCarCore

enum QxCarWindowMetrics {
    static let width: CGFloat = 440
    static let height: CGFloat = 270
    static var size: NSSize { NSSize(width: width, height: height) }
}

@main
struct QxCarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var updater = Updater.shared
    @StateObject private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.currentLanguage.locale)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: QxCarWindowMetrics.width, height: QxCarWindowMetrics.height)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updater, title: languageManager.string(.menuCheckForUpdates))
            }
            CommandGroup(after: .appSettings) {
                Menu(languageManager.string(.menuLanguage)) {
                    Picker(languageManager.string(.menuLanguage), selection: $languageManager.selectedLanguage) {
                        Text(L10n.menuItemTitle(for: .system, currentUiLang: languageManager.currentLanguage))
                            .tag(AppLanguage.system)
                        Divider()
                        ForEach(AppLanguage.allConcreteCases, id: \.self) { lang in
                            Text(lang.nativeDisplayName)
                                .tag(lang)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            CommandMenu(languageManager.string(.menuLanguage)) {
                Picker(languageManager.string(.menuLanguage), selection: $languageManager.selectedLanguage) {
                    Text(L10n.menuItemTitle(for: .system, currentUiLang: languageManager.currentLanguage))
                        .tag(AppLanguage.system)
                    Divider()
                    ForEach(AppLanguage.allConcreteCases, id: \.self) { lang in
                        Text(lang.nativeDisplayName)
                            .tag(lang)
                    }
                }
                .pickerStyle(.inline)
            }
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
