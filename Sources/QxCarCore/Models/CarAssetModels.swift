import Foundation

/// 资产文件与应用识别信息模型
public struct CarTargetInfo: Sendable, Identifiable {
    public var id: String { carPath }
    /// 应用或包显示名称（例如 "Safari"、"Calculator"、"Assets"）
    public let displayName: String
    /// Assets.car 文件实际绝对路径
    public let carPath: String
    /// 来源原始路径（可能是 .app 文件夹路径或直接是 .car 路径）
    public let sourcePath: String
    /// 是否来自 .app 应用程序包
    public let isAppBundle: Bool
    /// 文件大小（格式化字符串，例如 "2.4 MB"）
    public let fileSizeString: String
    /// 解析到的全部图标堆栈名称（例如 ["AppIcon", "AppIconUpdated"]）
    public let iconStacks: [String]
    /// 默认推荐的图标栈名称
    public var primaryIconStack: String? {
        if iconStacks.contains("AppIcon") { return "AppIcon" }
        if iconStacks.contains("AppIconUpdated") { return "AppIconUpdated" }
        return iconStacks.first
    }
    /// 包含的图片/资源预估数量
    public let estimatedAssetCount: Int

    public init(
        displayName: String,
        carPath: String,
        sourcePath: String,
        isAppBundle: Bool,
        fileSizeString: String,
        iconStacks: [String],
        estimatedAssetCount: Int
    ) {
        self.displayName = displayName
        self.carPath = carPath
        self.sourcePath = sourcePath
        self.isAppBundle = isAppBundle
        self.fileSizeString = fileSizeString
        self.iconStacks = iconStacks
        self.estimatedAssetCount = estimatedAssetCount
    }
}

/// 导出任务配置
public struct ExportConfiguration: Sendable {
    /// 目标 Assets.car 信息
    public let targetInfo: CarTargetInfo
    /// 输出根目录（绝对路径）
    public let outputDirectory: String
    /// 是否导出所有常规资产至 ./assets/
    public let exportAssets: Bool
    /// 是否逆向生成 .icon 格式图标
    public let reverseIcon: Bool
    /// 指定逆向的图标栈名称（例如 "AppIcon"）
    public let selectedIconStack: String
    /// 输出的 .icon 文件夹名称（例如 "AppIcon.icon"）
    public let iconOutputName: String
    /// 是否调用 actool 校验生成的 .icon
    public let validateWithActool: Bool

    public init(
        targetInfo: CarTargetInfo,
        outputDirectory: String,
        exportAssets: Bool = true,
        reverseIcon: Bool = true,
        selectedIconStack: String? = nil,
        iconOutputName: String? = nil,
        validateWithActool: Bool = true
    ) {
        self.targetInfo = targetInfo
        self.outputDirectory = outputDirectory
        self.exportAssets = exportAssets
        self.reverseIcon = reverseIcon
        self.selectedIconStack = selectedIconStack ?? targetInfo.primaryIconStack ?? "AppIcon"
        self.iconOutputName = iconOutputName ?? "\(targetInfo.displayName).icon"
        self.validateWithActool = validateWithActool
    }
}

/// 导出事件与日志通知
public enum ExportProgressEvent: Sendable {
    /// 阶段开始（阶段名称）
    case started(String)
    /// 进度更新（当前进度 0.0 ~ 1.0，描述文本）
    case progress(Double, String)
    /// 记录一条日志消息（类型，文本）
    case log(LogLevel, String)
    /// 导出完成（输出目录，生成的资产文件数，是否成功生成 .icon）
    case completed(outputDir: String, assetCount: Int, iconPath: String?)
    /// 发生错误
    case failed(String)
}

/// 日志等级
public enum LogLevel: String, Sendable {
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARNING"
    case error = "ERROR"
}

/// 逆向生成的 .icon 结果
public struct IconReverseResult: Sendable {
    /// .icon 最终生成路径
    public let iconPath: String
    /// 图层组数量
    public let groupCount: Int
    /// 总图层数量
    public let layerCount: Int
    /// actool 校验是否通过
    public let isValidated: Bool
    /// 校验警告或提示
    public let validationMessage: String?
}
