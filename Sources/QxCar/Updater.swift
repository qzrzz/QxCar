import Combine
import Sparkle
import SwiftUI

/// 应用级 Sparkle 更新管理器（对齐 QCopy / Qjiao）。
///
/// 单例持有更新生命周期；菜单「检查更新」复用此实例。
/// Feed URL 与公钥来自 Info.plist 的 `SUFeedURL` / `SUPublicEDKey`。
@MainActor
final class Updater: ObservableObject {
    static let shared = Updater()

    private let controller: SPUStandardUpdaterController

    /// 正在检查时禁用菜单项，避免重复触发。
    @Published private(set) var canCheckForUpdates = false

    /// 是否按 Sparkle 计划自动检查。值由 Sparkle 持久化在 UserDefaults。
    @Published var automaticallyChecksForUpdates: Bool {
        didSet {
            controller.updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates
        }
    }

    /// Debug 在 updater 尚未启动时仍可点（首次点击再武装）；Release 跟随 Sparkle 会话状态。
    var isCheckEnabled: Bool {
        canCheckForUpdates || !didStartUpdater
    }

    private var didStartUpdater: Bool

    private init() {
        // Debug 不自动启动：避免把 Dev.app 换成 Release，也不弹出后台检查。
        // 菜单「检查更新」会按需启动。
        #if DEBUG
        let startImmediately = false
        #else
        let startImmediately = true
        #endif

        controller = SPUStandardUpdaterController(
            startingUpdater: startImmediately,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        didStartUpdater = startImmediately
        automaticallyChecksForUpdates = controller.updater.automaticallyChecksForUpdates
        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)

        if startImmediately && automaticallyChecksForUpdates {
            controller.updater.checkForUpdatesInBackground()
        }
    }

    /// 用户可见的检查更新（进度窗与确认提示）。
    func checkForUpdates() {
        startUpdaterIfNeeded()
        controller.checkForUpdates(nil)
    }

    private func startUpdaterIfNeeded() {
        guard !didStartUpdater else { return }
        controller.startUpdater()
        didStartUpdater = true
    }
}

/// 应用菜单中的「检查更新…」命令。
struct CheckForUpdatesView: View {
    @ObservedObject var updater: Updater
    let title: String

    var body: some View {
        Button(title) {
            updater.checkForUpdates()
        }
        .disabled(!updater.isCheckEnabled)
    }
}
