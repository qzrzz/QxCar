import Foundation
import QxCarCoreBridge

/// Assets.car 全量素材资产提取服务
public final class CarAssetExtractor: @unchecked Sendable {
    private let fileManager = FileManager.default

    public init() {}

    /**
     * 导出 Assets.car 中的所有资源到目标文件夹
     * @param carPath Assets.car 文件绝对路径
     * @param outputDirectory 输出资产根目录 (例如 ./outputDir/assets/)
     * @param progressCallback 进度与日志回调
     * @return 成功导出的资产文件数量
     */
    public func extractAllAssets(
        carPath: String,
        outputDirectory: String,
        progressCallback: ((ExportProgressEvent) -> Void)? = nil
    ) throws -> Int {
        try fileManager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)

        progressCallback?(.log(.info, "正在打开 Catalog: \(carPath)..."))
        let catalog = try QxCarCoreUIBridge.openCatalog(withPath: carPath)

        // 获取资产清单
        let manifest = getAssetManifest(carPath: carPath)
        let allImageNames = QxCarCoreUIBridge.getAllImageNames(fromCatalog: catalog)

        var exportedCount = 0
        var colorList: [[String: Any]] = []

        // 处理 manifest 中的元素
        let totalItems = manifest.count + (allImageNames.count)
        var currentIndex = 0

        // 1. 根据 manifest 提取具体资源
        for item in manifest {
            currentIndex += 1
            let progress = Double(currentIndex) / Double(max(totalItems, 1))
            let assetType = item["AssetType"] as? String ?? "Unknown"
            let name = item["Name"] as? String ?? "unnamed"
            let renditionName = item["RenditionName"] as? String ?? "\(name).png"
            let scale = (item["Scale"] as? Double) ?? 1.0

            progressCallback?(.progress(progress, "正在提取: \(name) (\(assetType))"))

            if assetType == "Color" {
                colorList.append(item)
                continue
            }

            if assetType == "IconImageStack" {
                // 图标栈由 IconReverseEngineer 处理
                continue
            }

            // 目标文件路径
            let targetPath = (outputDirectory as NSString).appendingPathComponent(renditionName)
            if !fileManager.fileExists(atPath: targetPath) {
                let success = QxCarCoreUIBridge.exportAsset(
                    fromCatalog: catalog,
                    name: name,
                    scale: scale,
                    outputPath: targetPath
                )
                if success {
                    exportedCount += 1
                }
            }
        }

        // 2. 补充提取 allImageNames 中可能遗漏的资产
        for imgName in allImageNames {
            currentIndex += 1
            let progress = Double(currentIndex) / Double(max(totalItems, 1))
            progressCallback?(.progress(progress, "正在提取: \(imgName)"))

            let safeName = imgName.replacingOccurrences(of: "/", with: "__")
            let targetPng1x = (outputDirectory as NSString).appendingPathComponent("\(safeName).png")
            let targetPng2x = (outputDirectory as NSString).appendingPathComponent("\(safeName)@2x.png")
            let targetPng3x = (outputDirectory as NSString).appendingPathComponent("\(safeName)@3x.png")
            let targetSvg = (outputDirectory as NSString).appendingPathComponent("\(safeName).svg")
            let targetPdf = (outputDirectory as NSString).appendingPathComponent("\(safeName).pdf")

            if !fileManager.fileExists(atPath: targetPng1x) &&
               !fileManager.fileExists(atPath: targetPng2x) &&
               !fileManager.fileExists(atPath: targetSvg) &&
               !fileManager.fileExists(atPath: targetPdf) {
                
                // 尝试提取 SVG
                if QxCarCoreUIBridge.exportAsset(fromCatalog: catalog, name: imgName, scale: 1.0, outputPath: targetSvg) {
                    exportedCount += 1
                    continue
                }
                // 尝试提取 PDF
                if QxCarCoreUIBridge.exportAsset(fromCatalog: catalog, name: imgName, scale: 1.0, outputPath: targetPdf) {
                    exportedCount += 1
                    continue
                }
                // 尝试提取 1x, 2x, 3x PNG
                if QxCarCoreUIBridge.exportAsset(fromCatalog: catalog, name: imgName, scale: 1.0, outputPath: targetPng1x) {
                    exportedCount += 1
                }
                if QxCarCoreUIBridge.exportAsset(fromCatalog: catalog, name: imgName, scale: 2.0, outputPath: targetPng2x) {
                    exportedCount += 1
                }
                if QxCarCoreUIBridge.exportAsset(fromCatalog: catalog, name: imgName, scale: 3.0, outputPath: targetPng3x) {
                    exportedCount += 1
                }
            }
        }

        // 3. 写入 colors.json（若有提取到颜色定义）
        if !colorList.isEmpty {
            let colorsPath = (outputDirectory as NSString).appendingPathComponent("colors.json")
            if let data = try? JSONSerialization.data(withJSONObject: colorList, options: [.prettyPrinted, .sortedKeys]) {
                try? data.write(to: URL(fileURLWithPath: colorsPath))
                exportedCount += 1
                progressCallback?(.log(.info, "已保存颜色资产表: colors.json (\(colorList.count) 个颜色)"))
            }
        }

        // 4. 写入全量资产清单 asset-manifest.json
        if !manifest.isEmpty {
            let manifestPath = (outputDirectory as NSString).appendingPathComponent("asset-manifest.json")
            if let data = try? JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted]) {
                try? data.write(to: URL(fileURLWithPath: manifestPath))
                progressCallback?(.log(.info, "已生成资产元数据清单: asset-manifest.json"))
            }
        }

        progressCallback?(.log(.success, "素材资产导出完成，共导出 \(exportedCount) 个资源文件"))
        return exportedCount
    }

    /// 使用 `assetutil --info` 获取结构化清单
    private func getAssetManifest(carPath: String) -> [[String: Any]] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["assetutil", "--info", carPath]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return []
            }
            return Array(json.dropFirst())
        } catch {
            return []
        }
    }
}
