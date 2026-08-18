import SwiftUI
import AppKit
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
    public let reason: String
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
    @Published public var statusMessage: String = "请拖入 Assets.car 文件或 .app 应用程序包"
    @Published public var logs: [LogEntry] = []
    @Published public var isDragOver: Bool = false
    @Published public var lastResult: (outputDir: String, assetCount: Int, iconPath: String?)?

    private let discoveryService = CarDiscoveryService.shared
    private let exportManager = ExportManager.shared

    public init() {
        // 默认输出目录设为用户桌面下的 QxCarOutput
        let desktop = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first ?? "~"
        self.outputDirectory = (desktop as NSString).appendingPathComponent("QxCarOutput")
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
            self.statusMessage = "已识别: \(info.displayName) (\(info.fileSizeString))"
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
                isAppBundle: isApp,
                reason: isApp ? "该应用包内未找到 Assets.car 资源文件" : "该路径不是有效的 Assets.car 或未包含资源"
            )
            self.statusMessage = "未找到 Assets.car 资源文件"
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
        panel.prompt = "选择输出目录"

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
            statusMessage = "请先拖入包含有效 Assets.car 的文件或 .app"
            return
        }

        guard exportAssets || reverseIcon else {
            statusMessage = "请至少勾选一种导出模式"
            return
        }

        isExporting = true
        progress = 0.0
        statusMessage = "正在初始化导出任务..."
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
                self.statusMessage = "✨ 导出全部完成!"
            } catch {
                self.isExporting = false
                self.statusMessage = "导出失败: \(error.localizedDescription)"
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
        statusMessage = "请拖入 Assets.car 文件或 .app 应用程序包"
    }
}
