import Foundation

/// 导出任务调度器与全流程协调器
public final class ExportManager: @unchecked Sendable {
    public static let shared = ExportManager()

    private let assetExtractor = CarAssetExtractor()
    private let iconReverser = IconReverseEngineer()
    private let fileManager = FileManager.default

    public init() {}

    /**
     * 执行全量导出任务
     * @param config 导出配置
     * @param onEvent 进度与事件回调
     * @return 最终产物信息 (输出路径, 导出的素材数, 生成的 .icon 路径)
     */
    public func executeExport(
        config: ExportConfiguration,
        onEvent: @escaping @Sendable (ExportProgressEvent) -> Void
    ) async throws -> (outputDir: String, assetCount: Int, iconPath: String?) {
        let outputRoot = (config.outputDirectory as NSString).expandingTildeInPath
        try fileManager.createDirectory(atPath: outputRoot, withIntermediateDirectories: true)

        onEvent(.started("开始处理: \(config.targetInfo.displayName)"))
        onEvent(.log(.info, "目标 Assets.car: \(config.targetInfo.carPath)"))
        onEvent(.log(.info, "输出目标目录: \(outputRoot)"))

        var totalAssetsExported = 0
        var generatedIconPath: String?

        // 1. 导出素材资源至 ./outputDir/assets/
        if config.exportAssets {
            let assetsOutputDir = (outputRoot as NSString).appendingPathComponent("assets")
            onEvent(.progress(0.1, "正在提取全部素材资源到 assets/ ..."))
            
            do {
                let count = try assetExtractor.extractAllAssets(
                    carPath: config.targetInfo.carPath,
                    outputDirectory: assetsOutputDir,
                    progressCallback: { event in
                        onEvent(event)
                    }
                )
                totalAssetsExported = count
            } catch {
                onEvent(.log(.error, "素材导出出现异常: \(error.localizedDescription)"))
            }
        }

        // 2. 逆向图标为 ./outputDir/app.icon
        if config.reverseIcon {
            let stackName = config.selectedIconStack
            let iconDirName = config.iconOutputName.hasSuffix(".icon") ? config.iconOutputName : "\(config.iconOutputName).icon"
            let iconOutputPath = (outputRoot as NSString).appendingPathComponent(iconDirName)

            onEvent(.progress(0.6, "正在逆向图标堆栈 '\(stackName)' 为 \(iconDirName) ..."))

            do {
                let result = try iconReverser.reverseIcon(
                    carPath: config.targetInfo.carPath,
                    stackName: stackName,
                    outputIconPath: iconOutputPath,
                    validateWithActool: config.validateWithActool,
                    progressCallback: { event in
                        onEvent(event)
                    }
                )
                generatedIconPath = result.iconPath
            } catch {
                onEvent(.log(.error, "图标逆向失败: \(error.localizedDescription)"))
            }
        }

        onEvent(.progress(1.0, "全部任务处理完成!"))
        onEvent(.completed(
            outputDir: outputRoot,
            assetCount: totalAssetsExported,
            iconPath: generatedIconPath
        ))

        return (outputRoot, totalAssetsExported, generatedIconPath)
    }
}
