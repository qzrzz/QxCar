import Foundation
import QxCarCoreBridge

/// Liquid Glass .icon 逆向与 icon.json 重构引擎
public final class IconReverseEngineer: @unchecked Sendable {
    private let fileManager = FileManager.default

    public init() {}

    private let blendModeMap: [Int: String] = [
        0: "normal", 1: "multiply", 2: "screen", 3: "overlay", 4: "darken",
        5: "lighten", 6: "color-dodge", 7: "color-burn", 8: "soft-light",
        9: "hard-light", 10: "difference", 11: "exclusion", 12: "hue",
        13: "saturation", 14: "color", 15: "luminosity",
        26: "plus-darker", 27: "plus-lighter"
    ]

    private let shadowStyleMap: [Int: String] = [
        0: "none", 3: "neutral"
    ]

    private let specularPlacementMap: [Int: String] = [
        1: "inside", 2: "outside"
    ]

    private let colorSpaceMap: [String: String] = [
        "kCGColorSpaceDisplayP3": "display-p3",
        "kCGColorSpaceSRGB": "srgb",
        "kCGColorSpaceExtendedSRGB": "srgb",
        "kCGColorSpaceGenericRGB": "srgb",
        "kCGColorSpaceGenericGrayGamma2_2": "gray",
        "kCGColorSpaceLinearGray": "gray",
        "kCGColorSpaceGenericGray": "gray"
    ]

    private let appearanceTags: [(key: String, tag: String?)] = [
        ("Default", nil),
        ("NSAppearanceNameAqua", nil),
        ("UIAppearanceAny", nil),
        ("UIAppearanceLight", nil),
        ("NSAppearanceNameDarkAqua", "dark"),
        ("UIAppearanceDark", "dark"),
        ("ISAppearanceTintable", "tinted")
    ]

    private let basePreference = ["Default", "NSAppearanceNameAqua", "UIAppearanceAny", "UIAppearanceLight"]
    private let canvasSize: Double = 1024.0

    /**
     * 逆向生成 .icon 包
     * @param carPath Assets.car 路径
     * @param stackName 图标栈名称 (如 "AppIcon")
     * @param outputIconPath 目标 .icon 文件夹路径
     * @param validateWithActool 是否调用 actool 进行校验
     * @param progressCallback 进度通知回调
     * @return 逆向结果
     */
    public func reverseIcon(
        carPath: String,
        stackName: String,
        outputIconPath: String,
        validateWithActool: Bool = true,
        progressCallback: ((ExportProgressEvent) -> Void)? = nil
    ) throws -> IconReverseResult {
        let tempExtractDir = (NSTemporaryDirectory() as NSString).appendingPathComponent("qxcar_extract_\(UUID().uuidString)")
        defer {
            try? fileManager.removeItem(atPath: tempExtractDir)
        }

        try fileManager.createDirectory(atPath: tempExtractDir, withIntermediateDirectories: true)

        progressCallback?(.log(.info, "正在通过 CoreUI 提取 '\(stackName)' 图层结构与矢量素材..."))

        let catalog = try QxCarCoreUIBridge.openCatalog(withPath: carPath)

        guard let extractedData = QxCarCoreUIBridge.dumpIconStack(
            fromCatalog: catalog,
            iconName: stackName,
            outputDir: tempExtractDir
        ) else {
            throw NSError(domain: "QxCar", code: 3, userInfo: [NSLocalizedDescriptionKey: "未找到图标栈 '\(stackName)' 或提取失败"])
        }

        // 保存 extracted.json
        let extractedJsonPath = (tempExtractDir as NSString).appendingPathComponent("extracted.json")
        let rawJsonData = try JSONSerialization.data(withJSONObject: extractedData, options: [.prettyPrinted, .sortedKeys])
        try rawJsonData.write(to: URL(fileURLWithPath: extractedJsonPath))

        progressCallback?(.progress(0.4, "正在根据 Liquid Glass 材质模型重构 icon.json..."))

        // 重构 .icon 包
        let (groupCount, layerCount) = try assembleIcon(
            extractedData: extractedData,
            extractDir: tempExtractDir,
            outputIconPath: outputIconPath,
            progressCallback: progressCallback
        )

        progressCallback?(.progress(0.8, "正在校验生成的 .icon 结构..."))

        var isValidated = false
        var validationMsg: String?

        if validateWithActool {
            let valResult = runActoolValidation(iconPath: outputIconPath)
            isValidated = valResult.isValid
            validationMsg = valResult.message
            if isValidated {
                progressCallback?(.log(.success, "✓ actool 校验通过，.icon 结构完全兼容 Icon Composer 与 Xcode"))
            } else {
                progressCallback?(.log(.warning, "⚠ actool 提示: \(validationMsg ?? "未通过标准校验") (仍可在 Icon Composer 中查看与编辑)"))
            }
        } else {
            isValidated = true
        }

        progressCallback?(.log(.success, "成功逆向生成 .icon 包: \(outputIconPath) (\(groupCount) 组, \(layerCount) 层)"))

        return IconReverseResult(
            iconPath: outputIconPath,
            groupCount: groupCount,
            layerCount: layerCount,
            isValidated: isValidated,
            validationMessage: validationMsg
        )
    }

    /// 核心重构逻辑：将 CoreUI 导出的图层树转化为规范的 .icon/icon.json + Assets/
    private func assembleIcon(
        extractedData: [String: Any],
        extractDir: String,
        outputIconPath: String,
        progressCallback: ((ExportProgressEvent) -> Void)?
    ) throws -> (groupCount: Int, layerCount: Int) {
        let assetsDir = (outputIconPath as NSString).appendingPathComponent("Assets")
        try? fileManager.removeItem(atPath: outputIconPath)
        try fileManager.createDirectory(atPath: assetsDir, withIntermediateDirectories: true)

        // 选定基准外观（Default / Light）
        var baseKey: String?
        for pref in basePreference {
            if let dict = extractedData[pref] as? [String: Any], dict["groups"] != nil {
                baseKey = pref
                break
            }
        }
        if baseKey == nil {
            baseKey = extractedData.keys.first(where: {
                if let dict = extractedData[$0] as? [String: Any], dict["groups"] != nil { return true }
                return false
            })
        }

        guard let chosenBaseKey = baseKey, let baseDict = extractedData[chosenBaseKey] as? [String: Any] else {
            throw NSError(domain: "QxCar", code: 4, userInfo: [NSLocalizedDescriptionKey: "未找到有效的基准外观图层数据"])
        }

        let baseGroups = (baseDict["groups"] as? [[String: Any]]) ?? []

        // 构建各外观的 group 与 layer 索引表
        var otherAppearances: [(key: String, tag: String)] = []
        var appearanceIndex: [String: [String: [String: Any]]] = [:] // key -> "gi_li" -> layerDict
        var otherGroupLists: [(tag: String, groups: [[String: Any]])] = []

        for (k, tagOpt) in appearanceTags {
            guard k != chosenBaseKey, let dict = extractedData[k] as? [String: Any] else { continue }
            if let tag = tagOpt {
                otherAppearances.append((k, tag))
                let rgroups = (dict["groups"] as? [[String: Any]])?.filter { ($0["class"] as? String) == "CUINamedIconLayerGroup" } ?? []
                otherGroupLists.append((tag, rgroups))
            }
            // 建立层索引
            var layerMap: [String: [String: Any]] = [:]
            if let grps = dict["groups"] as? [[String: Any]] {
                for (gi, g) in grps.enumerated() {
                    if (g["class"] as? String) != "CUINamedIconLayerGroup" { continue }
                    if let layers = g["layers"] as? [[String: Any]] {
                        for (li, l) in layers.enumerated() {
                            layerMap["\(gi)_\(li)"] = l
                        }
                    }
                }
            }
            appearanceIndex[k] = layerMap
        }

        var groupsOut: [[String: Any]] = []
        var bottomFill: [String: Any]?
        var usesRefraction = false
        var usesSpecularLocation = false
        var baseRealGroupIndex = -1

        for (gi, g) in baseGroups.enumerated() {
            guard (g["class"] as? String) == "CUINamedIconLayerGroup" else {
                continue
            }
            baseRealGroupIndex += 1

            let peerGroups = otherGroupLists.map { item -> (tag: String, group: [String: Any]?) in
                if baseRealGroupIndex < item.groups.count {
                    return (item.tag, item.groups[baseRealGroupIndex])
                }
                return (item.tag, nil)
            }

            var layersOut: [[String: Any]] = []
            let rawLayers = (g["layers"] as? [[String: Any]]) ?? []

            for (li, l) in rawLayers.enumerated() {
                let savedSvg = l["savedSVG"] as? String
                let savedImage = l["savedImage"] as? String
                guard let savedFile = (savedSvg ?? savedImage) else { continue }

                let ext = (savedFile as NSString).pathExtension
                let rawName = (l["name"] as? String) ?? "layer"
                let cleanBase = (rawName as NSString).lastPathComponent
                let cleanFileName = "\(cleanBase).\(ext)"

                let srcPath = (extractDir as NSString).appendingPathComponent(savedFile)
                let dstPath = (assetsDir as NSString).appendingPathComponent(cleanFileName)
                try? fileManager.copyItem(atPath: srcPath, toPath: dstPath)

                let f0 = parseFill(from: l)
                if f0 != nil && bottomFill == nil {
                    bottomFill = f0
                }

                // 各外观的颜色覆盖
                var fillOverrides: [[String: Any]] = []
                for (k, tag) in otherAppearances {
                    if let peerLayer = appearanceIndex[k]?["\(gi)_\(li)"],
                       let fa = parseFill(from: peerLayer),
                       !areFillsEqual(fa, f0) {
                        fillOverrides.append(["appearance": tag, "value": fa])
                    }
                }

                var layerOut: [String: Any] = [
                    "image-name": cleanFileName,
                    "name": cleanBase
                ]

                if let frameStr = l["frame"] as? String, let pos = parsePosition(frameStr: frameStr) {
                    layerOut["position"] = pos
                }

                // 填充配置
                if f0 == nil {
                    if !fillOverrides.isEmpty {
                        layerOut["fill-specializations"] = fillOverrides
                    }
                } else if !fillOverrides.isEmpty {
                    var specs: [[String: Any]] = [["value": f0!]]
                    specs.append(contentsOf: fillOverrides)
                    layerOut["fill-specializations"] = specs
                } else if let baseF = f0 {
                    layerOut["fill"] = baseF
                }

                // 图层特化属性提取 (blend-mode, opacity, glass)
                applyLayerSpecializations(
                    layerOut: &layerOut,
                    baseLayer: l,
                    gi: gi,
                    li: li,
                    otherAppearances: otherAppearances,
                    appearanceIndex: appearanceIndex
                )

                layersOut.append(layerOut)
            }

            // 图层在 compiled car 中为 back-to-front，在 .icon 中为 front-to-back -> 反转
            layersOut.reverse()

            let shadowStyle = (g["shadowStyle"] as? Int) ?? 0
            let shadowKind = shadowStyleMap[shadowStyle] ?? "neutral"
            let shadowOpacity = roundTo((g["shadowOpacity"] as? Double) ?? 0.5, places: 4)

            var grpOut: [String: Any] = [
                "hidden": false,
                "layers": layersOut,
                "shadow": [
                    "kind": shadowKind,
                    "opacity": shadowOpacity
                ]
            ]

            // 组属性与材质特化
            applyGroupSpecializations(
                grpOut: &grpOut,
                baseGroup: g,
                peers: peerGroups,
                usesRefraction: &usesRefraction,
                usesSpecularLocation: &usesSpecularLocation
            )

            groupsOut.append(grpOut)
        }

        // 组在 compiled car 中为 back-to-front，在 .icon 中为 front-to-back -> 反转
        groupsOut.reverse()

        // 顶部画布填充背景
        var topFill = deriveCanvasFill(extractedData: extractedData, baseKey: chosenBaseKey, otherAppearances: otherAppearances)
        if topFill == nil {
            if let bf = bottomFill, let solid = bf["solid"] as? String {
                topFill = ["automatic-gradient": solid]
            } else if let bf = bottomFill, let linear = bf["linear-gradient"] as? [String], let last = linear.last {
                topFill = ["automatic-gradient": last]
            } else {
                topFill = ["automatic-gradient": "srgb:0.50000,0.50000,0.50000,1.00000"]
            }
        }

        var features: [String] = []
        if usesRefraction { features.append("refractivity") }
        if usesSpecularLocation { features.append("specular-location") }

        var iconDict: [String: Any] = [:]
        if !features.isEmpty {
            iconDict["features"] = features
        }
        if let tf = topFill {
            iconDict["fill"] = tf
        }
        iconDict["groups"] = groupsOut
        iconDict["supported-platforms"] = [
            "circles": ["watchOS"],
            "squares": "shared"
        ]

        let iconJsonPath = (outputIconPath as NSString).appendingPathComponent("icon.json")
        let finalJsonData = try JSONSerialization.data(withJSONObject: iconDict, options: [.prettyPrinted, .sortedKeys])
        try finalJsonData.write(to: URL(fileURLWithPath: iconJsonPath))

        let totalLayers = groupsOut.reduce(0) { $0 + (($1["layers"] as? [Any])?.count ?? 0) }
        return (groupsOut.count, totalLayers)
    }

    // MARK: - Attribute Helpers

    private func applyLayerSpecializations(
        layerOut: inout [String: Any],
        baseLayer: [String: Any],
        gi: Int,
        li: Int,
        otherAppearances: [(key: String, tag: String)],
        appearanceIndex: [String: [String: [String: Any]]]
    ) {
        // blend-mode
        let baseBlend = blendModeMap[(baseLayer["blendMode"] as? Int) ?? 0] ?? "normal"
        var blendDiffs: [(tag: String, val: String)] = []
        for (k, tag) in otherAppearances {
            if let peer = appearanceIndex[k]?["\(gi)_\(li)"] {
                let v = blendModeMap[(peer["blendMode"] as? Int) ?? 0] ?? "normal"
                if v != baseBlend { blendDiffs.append((tag, v)) }
            }
        }
        if !blendDiffs.isEmpty {
            var specs: [[String: Any]] = [["value": baseBlend]]
            for d in blendDiffs { specs.append(["appearance": d.tag, "value": d.val]) }
            layerOut["blend-mode-specializations"] = specs
        } else if baseBlend != "normal" {
            layerOut["blend-mode"] = baseBlend
        }

        // opacity
        let baseOpacity = roundTo((baseLayer["opacity"] as? Double) ?? 1.0, places: 4)
        var opacityDiffs: [(tag: String, val: Double)] = []
        for (k, tag) in otherAppearances {
            if let peer = appearanceIndex[k]?["\(gi)_\(li)"] {
                let v = roundTo((peer["opacity"] as? Double) ?? 1.0, places: 4)
                if abs(v - baseOpacity) > 1e-4 { opacityDiffs.append((tag, v)) }
            }
        }
        if !opacityDiffs.isEmpty {
            var specs: [[String: Any]] = [["value": baseOpacity]]
            for d in opacityDiffs { specs.append(["appearance": d.tag, "value": d.val]) }
            layerOut["opacity-specializations"] = specs
        } else if abs(baseOpacity - 1.0) > 1e-4 {
            layerOut["opacity"] = baseOpacity
        }

        // glass (hasLightingEffects)
        let baseGlass = (baseLayer["hasLightingEffects"] as? Bool) ?? false
        var glassDiffs: [(tag: String, val: Bool)] = []
        for (k, tag) in otherAppearances {
            if let peer = appearanceIndex[k]?["\(gi)_\(li)"] {
                let v = (peer["hasLightingEffects"] as? Bool) ?? false
                if v != baseGlass { glassDiffs.append((tag, v)) }
            }
        }
        if !glassDiffs.isEmpty {
            var specs: [[String: Any]] = [["value": baseGlass]]
            for d in glassDiffs { specs.append(["appearance": d.tag, "value": d.val]) }
            layerOut["glass-specializations"] = specs
        } else {
            layerOut["glass"] = baseGlass
        }
    }

    private func applyGroupSpecializations(
        grpOut: inout [String: Any],
        baseGroup: [String: Any],
        peers: [(tag: String, group: [String: Any]?)],
        usesRefraction: inout Bool,
        usesSpecularLocation: inout Bool
    ) {
        // blend-mode
        let baseBlend = blendModeMap[(baseGroup["blendMode"] as? Int) ?? 0] ?? "normal"
        specializeProperty(grp: &grpOut, key: "blend-mode", baseVal: baseBlend, peers: peers) {
            blendModeMap[($0["blendMode"] as? Int) ?? 0] ?? "normal"
        }

        // lighting
        let baseLighting = ((baseGroup["gathersSpecularByElement"] as? Bool) == true) ? "individual" : "combined"
        specializeProperty(grp: &grpOut, key: "lighting", baseVal: baseLighting, peers: peers) {
            (($0["gathersSpecularByElement"] as? Bool) == true) ? "individual" : "combined"
        }

        // specular
        let baseSpecular = parseSpecular(from: baseGroup)
        specializePropertyAny(grp: &grpOut, key: "specular", baseVal: baseSpecular, peers: peers) {
            self.parseSpecular(from: $0)
        }
        if (baseSpecular as? String) == "inside" || (baseSpecular as? String) == "outside" {
            usesSpecularLocation = true
        }

        // translucency
        let baseTranslucency = parseTranslucency(from: baseGroup)
        specializePropertyAny(grp: &grpOut, key: "translucency", baseVal: baseTranslucency, peers: peers) {
            self.parseTranslucency(from: $0)
        }

        // refractivity
        if let baseRefract = parseRefractivity(from: baseGroup) {
            usesRefraction = true
            specializePropertyAny(grp: &grpOut, key: "refractivity", baseVal: baseRefract, peers: peers) {
                self.parseRefractivity(from: $0)
            }
        }

        // blur
        let baseBlur = (baseGroup["blurStrength"] as? Double).flatMap { $0 > 0 ? roundTo($0, places: 4) : nil }
        if let b = baseBlur {
            specializePropertyAny(grp: &grpOut, key: "blur-material", baseVal: b, peers: peers) {
                ($0["blurStrength"] as? Double).flatMap { $0 > 0 ? self.roundTo($0, places: 4) : nil }
            }
        }
    }

    private func parseSpecular(from g: [String: Any]) -> Any {
        guard (g["hasSpecular"] as? Bool) == true else { return false }
        let plc = (g["specularPlacement"] as? Int) ?? 0
        return specularPlacementMap[plc] ?? (true as Any)
    }

    private func parseTranslucency(from g: [String: Any]) -> [String: Any] {
        let val = roundTo((g["translucency"] as? Double) ?? 1.0, places: 4)
        return ["enabled": val < 1.0, "value": val]
    }

    private func parseRefractivity(from g: [String: Any]) -> [String: Any]? {
        let s = roundTo((g["refractionStrength"] as? Double) ?? 0, places: 4)
        let h = roundTo((g["refractionHeight"] as? Double) ?? 0, places: 4)
        if s > 0 || h > 0 {
            return ["enabled": true, "strength": s, "depth": h]
        }
        return nil
    }

    private func specializeProperty<T: Equatable>(
        grp: inout [String: Any],
        key: String,
        baseVal: T,
        peers: [(tag: String, group: [String: Any]?)],
        extract: ([String: Any]) -> T
    ) {
        var diffs: [(tag: String, val: T)] = []
        for (tag, pg) in peers {
            if let g = pg {
                let v = extract(g)
                if v != baseVal { diffs.append((tag, v)) }
            }
        }
        if !diffs.isEmpty {
            var specs: [[String: Any]] = [["value": baseVal]]
            for d in diffs { specs.append(["appearance": d.tag, "value": d.val]) }
            grp["\(key)-specializations"] = specs
        } else {
            grp[key] = baseVal
        }
    }

    private func specializePropertyAny(
        grp: inout [String: Any],
        key: String,
        baseVal: Any?,
        peers: [(tag: String, group: [String: Any]?)],
        extract: ([String: Any]) -> Any?
    ) {
        guard let base = baseVal else { return }
        var diffs: [(tag: String, val: Any)] = []
        for (tag, pg) in peers {
            if let g = pg, let v = extract(g) {
                if !areAnyEqual(v, base) { diffs.append((tag, v)) }
            }
        }
        if !diffs.isEmpty {
            var specs: [[String: Any]] = [["value": base]]
            for d in diffs { specs.append(["appearance": d.tag, "value": d.val]) }
            grp["\(key)-specializations"] = specs
        } else {
            grp[key] = base
        }
    }

    // MARK: - Frame, Color & Gradient Parsing

    private func parsePosition(frameStr: String) -> [String: Any]? {
        let nums = frameStr.components(separatedBy: CharacterSet(charactersIn: "{}, ")).compactMap { Double($0) }
        guard nums.count >= 4 else { return nil }
        let (x, y, w, h) = (nums[0], nums[1], nums[2], nums[3])
        let scale = roundTo(((w / canvasSize) + (h / canvasSize)) / 2.0, places: 5)
        let cx = roundTo((x + w / 2.0) - canvasSize / 2.0, places: 3)
        let cy = roundTo((y + h / 2.0) - canvasSize / 2.0, places: 3)

        if abs(scale - 1.0) < 1e-3 && abs(cx) < 1.0 && abs(cy) < 1.0 {
            return nil
        }
        return [
            "scale": scale,
            "translation-in-points": [cx, cy]
        ]
    }

    private func colorString(from colorDict: [String: Any]?) -> String? {
        guard let c = colorDict, let comps = c["components"] as? [Double], !comps.isEmpty else { return nil }
        let rawSpace = (c["colorspace"] as? String) ?? "kCGColorSpaceSRGB"
        let space = colorSpaceMap[rawSpace] ?? "srgb"

        if space == "gray" || comps.count < 3 {
            let v = comps[0]
            let a = comps.count >= 2 ? comps[1] : 1.0
            return String(format: "gray:%.5f,%.5f", v, a)
        }
        if comps.count >= 4 {
            return String(format: "%@:%.5f,%.5f,%.5f,%.5f", space, comps[0], comps[1], comps[2], comps[3])
        }
        return String(format: "%@:%.5f,%.5f,%.5f,1.00000", space, comps[0], comps[1], comps[2])
    }

    private func parseFill(from layer: [String: Any]) -> [String: Any]? {
        if let grad = layer["gradient"] as? [String: Any], let colors = grad["colors"] as? [[String: Any]], !colors.isEmpty {
            let cstrs = colors.compactMap { colorString(from: $0) }
            if cstrs.count == 1 { return ["solid": cstrs[0]] }
            if cstrs.count == 2 { return ["linear-gradient": cstrs] }
            if cstrs.count > 2, let first = cstrs.first, let last = cstrs.last {
                return ["linear-gradient": [first, last]]
            }
        }
        if let col = layer["color"] as? [String: Any], let cstr = colorString(from: col) {
            return ["solid": cstr]
        }
        return nil
    }

    private func canvasFillToFill(cf: [String: Any]?) -> [String: Any]? {
        guard let cf = cf, let colors = cf["colors"] as? [[String: Any]], !colors.isEmpty else { return nil }
        let cstrs = colors.compactMap { colorString(from: $0) }
        guard !cstrs.isEmpty else { return nil }

        var res: [String: Any] = [:]
        if cstrs.count == 1 {
            res["automatic-gradient"] = cstrs[0]
        } else if cstrs.count == 2 {
            res["linear-gradient"] = cstrs
        } else if let first = cstrs.first, let last = cstrs.last {
            res["linear-gradient"] = [first, last]
        }

        if let start = cf["start"] as? [Double], let end = cf["end"] as? [Double], start.count >= 2, end.count >= 2 {
            res["orientation"] = [
                "start": ["x": roundTo(start[0], places: 4), "y": roundTo(start[1], places: 4)],
                "stop": ["x": roundTo(end[0], places: 4), "y": roundTo(end[1], places: 4)]
            ]
        }
        return res
    }

    private func deriveCanvasFill(
        extractedData: [String: Any],
        baseKey: String,
        otherAppearances: [(key: String, tag: String)]
    ) -> [String: Any]? {
        let baseDict = extractedData[baseKey] as? [String: Any]
        let baseCf = baseDict?["canvasFill"] as? [String: Any]
        guard var baseFill = canvasFillToFill(cf: baseCf) else { return nil }

        var diffs: [(tag: String, fill: [String: Any])] = []
        for (k, tag) in otherAppearances {
            let od = extractedData[k] as? [String: Any]
            if let ocf = od?["canvasFill"] as? [String: Any], let ofill = canvasFillToFill(cf: ocf) {
                if !areFillsEqual(ofill, baseFill) {
                    diffs.append((tag, ofill))
                }
            }
        }

        if !diffs.isEmpty {
            var specs: [[String: Any]] = [["value": baseFill]]
            for d in diffs { specs.append(["appearance": d.tag, "value": d.fill]) }
            baseFill["fill-specializations"] = specs
        }
        return baseFill
    }

    // MARK: - Validation

    private func runActoolValidation(iconPath: String) -> (isValid: Bool, message: String?) {
        let tempValDir = (NSTemporaryDirectory() as NSString).appendingPathComponent("qxcar_actool_\(UUID().uuidString)")
        defer { try? fileManager.removeItem(atPath: tempValDir) }
        try? fileManager.createDirectory(atPath: tempValDir, withIntermediateDirectories: true)

        let stem = ((iconPath as NSString).lastPathComponent as NSString).deletingPathExtension

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "actool",
            "--compile", tempValDir,
            iconPath,
            "--platform", "iphoneos",
            "--minimum-deployment-target", "26.0",
            "--app-icon", stem,
            "--output-partial-info-plist", (tempValDir as NSString).appendingPathComponent("p.plist")
        ]

        let errPipe = Pipe()
        process.standardError = errPipe
        process.standardOutput = Pipe()

        do {
            try process.run()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                return (true, nil)
            } else {
                let errStr = String(data: errData, encoding: .utf8) ?? "actool 校验失败"
                let cleanErr = errStr.components(separatedBy: .newlines).first(where: { $0.contains("error:") || $0.contains("warning:") }) ?? errStr
                return (false, cleanErr)
            }
        } catch {
            return (false, error.localizedDescription)
        }
    }

    // MARK: - Equality Helpers

    private func areFillsEqual(_ a: [String: Any]?, _ b: [String: Any]?) -> Bool {
        guard let a = a, let b = b else { return a == nil && b == nil }
        return NSDictionary(dictionary: a).isEqual(to: b)
    }

    private func areAnyEqual(_ a: Any, _ b: Any) -> Bool {
        if let da = a as? [String: Any], let db = b as? [String: Any] {
            return NSDictionary(dictionary: da).isEqual(to: db)
        }
        if let sa = a as? String, let sb = b as? String { return sa == sb }
        if let ba = a as? Bool, let bb = b as? Bool { return ba == bb }
        if let na = a as? Double, let nb = b as? Double { return abs(na - nb) < 1e-4 }
        return false
    }

    private func roundTo(_ value: Double, places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (value * divisor).rounded() / divisor
    }
}
