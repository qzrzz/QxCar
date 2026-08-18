import Foundation
import QxCarCoreBridge

/// Assets.car 文件发现与智能分析服务
public final class CarDiscoveryService: @unchecked Sendable {
    public static let shared = CarDiscoveryService()

    private let fileManager = FileManager.default

    public init() {}

    /**
     * 智能定位与分析目标路径
     * @param rawPath 用户拖入的文件、文件夹或 .app 路径
     * @return 解析完成的 CarTargetInfo，如果未找到则返回 nil
     */
    public func discover(from rawPath: String) -> CarTargetInfo? {
        let cleanedPath = (rawPath as NSString).expandingTildeInPath
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: cleanedPath, isDirectory: &isDir) else {
            return nil
        }

        var carPath: String?
        var displayName: String = (cleanedPath as NSString).lastPathComponent
        let isAppBundle: Bool = cleanedPath.hasSuffix(".app") || (cleanedPath as NSString).pathExtension == "app"

        if isDir.boolValue {
            if isAppBundle {
                displayName = (displayName as NSString).deletingPathExtension
                // 优先查找 Contents/Resources/Assets.car
                let standardCar = (cleanedPath as NSString).appendingPathComponent("Contents/Resources/Assets.car")
                if fileManager.fileExists(atPath: standardCar) {
                    carPath = standardCar
                }
            }

            // 如果没找到，进行浅层搜索
            if carPath == nil {
                carPath = findShallowestCar(in: cleanedPath)
            }
        } else if cleanedPath.hasSuffix(".car") {
            carPath = cleanedPath
            displayName = (displayName as NSString).deletingPathExtension
            if displayName.lowercased() == "assets" {
                // 向上追溯一级目录名称，例如 "MyApp/Assets.car" -> "MyApp"
                let parentName = ((cleanedPath as NSString).deletingLastPathComponent as NSString).lastPathComponent
                if !parentName.isEmpty && parentName != "/" && parentName != "Resources" && parentName != "Contents" {
                    displayName = parentName
                }
            }
        }

        guard let foundCarPath = carPath, fileManager.fileExists(atPath: foundCarPath) else {
            return nil
        }

        // 获取文件大小
        let fileSizeString = getFormattedFileSize(path: foundCarPath)

        // 解析包含的图标堆栈与素材数量
        var iconStacks: [String] = []
        var estimatedAssetCount: Int = 0

        // 使用 QxCarCoreUIBridge 快速读取
        if let catalog = try? QxCarCoreUIBridge.openCatalog(withPath: foundCarPath) {
            let stacks = QxCarCoreUIBridge.getIconStackNames(fromCatalog: catalog)
            iconStacks = stacks
            let allImages = QxCarCoreUIBridge.getAllImageNames(fromCatalog: catalog)
            estimatedAssetCount = allImages.count
        }

        // 若 CoreUI 未完全抓到图标栈，使用 assetutil 进行补充扫描
        if iconStacks.isEmpty {
            let assetUtilInfo = runAssetUtilInfo(carPath: foundCarPath)
            if !assetUtilInfo.iconStacks.isEmpty {
                iconStacks = assetUtilInfo.iconStacks
            }
            if estimatedAssetCount == 0 {
                estimatedAssetCount = assetUtilInfo.totalAssets
            }
        }

        return CarTargetInfo(
            displayName: displayName,
            carPath: foundCarPath,
            sourcePath: cleanedPath,
            isAppBundle: isAppBundle,
            fileSizeString: fileSizeString,
            iconStacks: iconStacks,
            estimatedAssetCount: estimatedAssetCount
        )
    }

    /// 在指定目录中寻找最浅层级的 Assets.car
    private func findShallowestCar(in rootPath: String) -> String? {
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: rootPath),
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var candidates: [(path: String, depth: Int)] = []

        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == "Assets.car" {
                let rel = fileURL.path.replacingOccurrences(of: rootPath, with: "")
                let depth = rel.components(separatedBy: "/").count
                candidates.append((path: fileURL.path, depth: depth))
            }
            // 限制最大遍历深度，防止卡顿
            if enumerator.level > 5 {
                enumerator.skipDescendants()
            }
        }

        return candidates.min(by: { $0.depth < $1.depth })?.path
    }

    /// 格式化文件大小
    private func getFormattedFileSize(path: String) -> String {
        guard let attrs = try? fileManager.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64 else {
            return "未知大小"
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    /// 运行 `xcrun assetutil --info` 解析元数据补充
    private func runAssetUtilInfo(carPath: String) -> (iconStacks: [String], totalAssets: Int) {
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
                return ([], 0)
            }

            var stacks = Set<String>()
            var count = 0

            for item in json.dropFirst() {
                count += 1
                if let type = item["AssetType"] as? String, type == "IconImageStack",
                   let name = item["Name"] as? String {
                    stacks.insert(name)
                }
            }

            return (Array(stacks).sorted(), count)
        } catch {
            return ([], 0)
        }
    }
}
