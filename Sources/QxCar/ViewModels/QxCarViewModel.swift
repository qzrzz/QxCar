import SwiftUI
import AppKit
import Combine
import QxCarCore

/// 日志条目模型
public struct LogEntry: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let level: LogLevel
    public let message: String

    public var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

/// 未找到资源的目标信息模型（用于界面直接呈现提示卡片）
public struct NotFoundTargetInfo: Sendable {
    public let path: String
    public let displayName: String
    public let isAppBundle: Bool

    /// 动态返回当前生效语言下的未找到原因说明
    @MainActor
    public var reason: String {
        isAppBundle
            ? LanguageManager.shared.string(.errAppBundleNoCar)
            : LanguageManager.shared.string(.errInvalidCarPath)
    }

    public init(path: String, displayName: String, isAppBundle: Bool) {
        self.path = path
        self.displayName = displayName
        self.isAppBundle = isAppBundle
    }
}

@MainActor
public final class QxCarViewModel: ObservableObject {
    @Published public var targetInfo: CarTargetInfo?
    @Published public var notFoundInfo: NotFoundTargetInfo?
    @Published public var outputDirectory: String
    @Published public var exportAssets: Bool = true
    @Published public var reverseIcon: Bool = true
    @Published public var selectedIconStack: String = "AppIcon"
    @Published public var iconOutputName: String = ""

    @Published public var isExporting: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var statusMessage: String
    @Published public var logs: [LogEntry] = []
    @Published public var isDragOver: Bool = false
    @Published public var lastResult: (outputDir: String, assetCount: Int, iconPath: String?)?

    private let discoveryService = CarDiscoveryService.shared
    private let exportManager = ExportManager.shared
    private var languageCancellable: AnyCancellable?

    public init() {
        // 默认输出目录设为用户桌面下的 QxCarOutput
        let desktop = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first ?? "~"
        self.outputDirectory = (desktop as NSString).appendingPathComponent("QxCarOutput")
        self.statusMessage = LanguageManager.shared.string(.msgInitialPrompt)

        // 监听语言变化，实时刷新状态文本
        self.languageCancellable = LanguageManager.shared.$currentLanguage
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshLocalizedStatus()
                }
            }
    }

    /**
     * 处理拖入的文件路径
     */
    public func handleDroppedPaths(_ paths: [String]) {
        guard let first = paths.first else { return }
        appendLog(.info, "分析拖入路径: \(first)")

        if let info = discoveryService.discover(from: first) {
            self.targetInfo = info
            self.notFoundInfo = nil
            self.selectedIconStack = info.primaryIconStack ?? "AppIcon"
            self.iconOutputName = "\(info.displayName).icon"
            self.statusMessage = LanguageManager.shared.format(.msgIdentifiedFormat, info.displayName, info.fileSizeString)
            self.lastResult = nil
            appendLog(.success, "成功定位 Assets.car: \(info.carPath)")
            if !info.iconStacks.isEmpty {
                appendLog(.info, "发现图标堆栈: \(info.iconStacks.joined(separator: ", "))")
            }
        } else {
            let cleanPath = (first as NSString).expandingTildeInPath
            let isApp = cleanPath.hasSuffix(".app") || (cleanPath as NSString).pathExtension == "app"
            let name = (cleanPath as NSString).lastPathComponent
            let displayName = isApp ? (name as NSString).deletingPathExtension : name

            self.targetInfo = nil
            self.notFoundInfo = NotFoundTargetInfo(
                path: cleanPath,
                displayName: displayName,
                isAppBundle: isApp
            )
            self.statusMessage = LanguageManager.shared.string(.msgCarNotFound)
            appendLog(.error, "未找到 Assets.car: \(first)")
        }
    }

    /**
     * 打开原生选择文件夹对话框
     */
    public func selectOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = LanguageManager.shared.string(.selectOutputFolderPrompt)

        if panel.runModal() == .OK, let url = panel.url {
            self.outputDirectory = url.path
            appendLog(.info, "已更改输出目录为: \(url.path)")
        }
    }

    /**
     * 开始导出与逆向流程
     */
    public func startExport() {
        guard let info = targetInfo else {
            statusMessage = LanguageManager.shared.string(.msgPleaseDropFirst)
            return
        }

        guard exportAssets || reverseIcon else {
            statusMessage = LanguageManager.shared.string(.msgSelectExportMode)
            return
        }

        isExporting = true
        progress = 0.0
        statusMessage = LanguageManager.shared.string(.msgInitializingExport)
        lastResult = nil

        let config = ExportConfiguration(
            targetInfo: info,
            outputDirectory: outputDirectory,
            exportAssets: exportAssets,
            reverseIcon: reverseIcon,
            selectedIconStack: selectedIconStack,
            iconOutputName: iconOutputName.isEmpty ? "\(info.displayName).icon" : iconOutputName,
            validateWithActool: true
        )

        Task {
            do {
                let res = try await exportManager.executeExport(config: config) { [weak self] event in
                    Task { @MainActor [weak self] in
                        self?.handleExportEvent(event)
                    }
                }
                self.lastResult = res
                self.isExporting = false
                self.statusMessage = LanguageManager.shared.string(.msgExportSuccess)
            } catch {
                self.isExporting = false
                self.statusMessage = LanguageManager.shared.format(.msgExportFailedPrefix, error.localizedDescription)
                self.appendLog(.error, "导出流程异常: \(error.localizedDescription)")
            }
        }
    }

    private func handleExportEvent(_ event: ExportProgressEvent) {
        switch event {
        case .started(let msg):
            statusMessage = msg
        case .progress(let p, let msg):
            progress = p
            statusMessage = msg
        case .log(let level, let msg):
            appendLog(level, msg)
        case .completed(let outDir, let assetCount, let iconPath):
            appendLog(.success, "🎉 导出任务圆满完成! 输出位置: \(outDir)")
            if assetCount > 0 {
                appendLog(.info, "• 素材资源已保存至: \(outDir)/assets/ (\(assetCount) 个文件)")
            }
            if let ip = iconPath {
                appendLog(.info, "• Liquid Glass 图标包已生成: \(ip)")
            }
        case .failed(let err):
            appendLog(.error, err)
        }
    }

    public func openOutputDirInFinder() {
        let dir = lastResult?.outputDir ?? outputDirectory
        let url = URL(fileURLWithPath: (dir as NSString).expandingTildeInPath)
        NSWorkspace.shared.open(url)
    }

    public func openIconInIconComposer() {
        if let iconPath = lastResult?.iconPath {
            let url = URL(fileURLWithPath: iconPath)
            NSWorkspace.shared.open(url)
        }
    }

    public func appendLog(_ level: LogLevel, _ message: String) {
        let entry = LogEntry(timestamp: Date(), level: level, message: message)
        logs.append(entry)
    }

    public func clearLogs() {
        logs.removeAll()
    }

    public func reset() {
        targetInfo = nil
        notFoundInfo = nil
        lastResult = nil
        progress = 0.0
        statusMessage = LanguageManager.shared.string(.msgInitialPrompt)
    }

    /// 当界面语言发生变更时，自动刷新当前静态状态提示
    private func refreshLocalizedStatus() {
        if isExporting { return }
        if let info = targetInfo {
            statusMessage = LanguageManager.shared.format(.msgIdentifiedFormat, info.displayName, info.fileSizeString)
        } else if notFoundInfo != nil {
            statusMessage = LanguageManager.shared.string(.msgCarNotFound)
        } else if lastResult != nil {
            statusMessage = LanguageManager.shared.string(.msgExportSuccess)
        } else {
            statusMessage = LanguageManager.shared.string(.msgInitialPrompt)
        }
    }
}
