import XCTest
import Foundation
@testable import QxCarCore

final class QxCarCoreTests: XCTestCase {
    var sampleCarPath: String?

    override func setUp() {
        super.setUp()
        // 查找 decant/Assets.car 或系统 App 中的 Assets.car 作为测试样例
        let currentDir = FileManager.default.currentDirectoryPath
        let decantCar = (currentDir as NSString).appendingPathComponent("decant/Assets.car")
        let calcCar = "/System/Applications/Calculator.app/Contents/Resources/Assets.car"
        let previewCar = "/System/Applications/Preview.app/Contents/Resources/Assets.car"

        if FileManager.default.fileExists(atPath: decantCar) {
            sampleCarPath = decantCar
        } else if FileManager.default.fileExists(atPath: calcCar) {
            sampleCarPath = calcCar
        } else if FileManager.default.fileExists(atPath: previewCar) {
            sampleCarPath = previewCar
        }
    }

    func testCarDiscoveryService定位与元数据解析() throws {
        guard let carPath = sampleCarPath else {
            throw XCTSkip("未找到可供测试的 Assets.car 样例")
        }

        let service = CarDiscoveryService.shared
        let info = service.discover(from: carPath)

        XCTAssertNotNil(info, "应当成功解析 Assets.car 目标信息")
        XCTAssertEqual(info?.carPath, carPath)
        XCTAssertFalse(info?.displayName.isEmpty ?? true, "应当提取出有效的显示名称")
        print("✓ 测试定位到: \(info?.displayName ?? "") | 大小: \(info?.fileSizeString ?? "") | 图标栈: \(info?.iconStacks.joined(separator: ", ") ?? "")")
    }

    func testCarAssetExtractor素材全量导出() throws {
        guard let carPath = sampleCarPath else {
            throw XCTSkip("未找到可供测试的 Assets.car 样例")
        }

        let tempOutDir = (NSTemporaryDirectory() as NSString).appendingPathComponent("qxcar_test_assets_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(atPath: tempOutDir) }

        let extractor = CarAssetExtractor()
        let count = try extractor.extractAllAssets(carPath: carPath, outputDirectory: tempOutDir)

        XCTAssertGreaterThan(count, 0, "导出的资源总数应大于 0")
        let files = (try? FileManager.default.contentsOfDirectory(atPath: tempOutDir)) ?? []
        XCTAssertFalse(files.isEmpty, "导出目录中应包含生成的文件")
        print("✓ 测试素材导出完成，共产生 \(files.count) 个文件")
    }

    func testIconReverseEngineer逆向生成IconComposer包() throws {
        // 使用含 IconImageStack 的系统应用进行测试
        let calcCar = "/System/Applications/Calculator.app/Contents/Resources/Assets.car"
        let appStoreCar = "/System/Applications/App Store.app/Contents/Resources/Assets.car"
        let testCar = FileManager.default.fileExists(atPath: calcCar) ? calcCar : (FileManager.default.fileExists(atPath: appStoreCar) ? appStoreCar : sampleCarPath)

        guard let car = testCar, FileManager.default.fileExists(atPath: car) else {
            throw XCTSkip("未找到包含 IconImageStack 的 Assets.car")
        }

        let service = CarDiscoveryService.shared
        guard let info = service.discover(from: car), let primaryStack = info.primaryIconStack else {
            throw XCTSkip("未检测到图标堆栈")
        }

        let tempIconPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("TestApp.icon")
        defer { try? FileManager.default.removeItem(atPath: tempIconPath) }

        let reverser = IconReverseEngineer()
        let result = try reverser.reverseIcon(
            carPath: car,
            stackName: primaryStack,
            outputIconPath: tempIconPath,
            validateWithActool: false
        )

        XCTAssertEqual(result.iconPath, tempIconPath)
        XCTAssertGreaterThan(result.groupCount, 0, "逆向生成的图标组数应大于 0")
        XCTAssertGreaterThan(result.layerCount, 0, "逆向生成的图层数应大于 0")

        let iconJsonPath = (tempIconPath as NSString).appendingPathComponent("icon.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: iconJsonPath), "必须生成 icon.json")

        let assetsDir = (tempIconPath as NSString).appendingPathComponent("Assets")
        XCTAssertTrue(FileManager.default.fileExists(atPath: assetsDir), "必须生成 Assets/ 素材目录")

        let jsonData = try Data(contentsOf: URL(fileURLWithPath: iconJsonPath))
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertNotNil(json?["groups"], "icon.json 中应包含 groups 数组")
        XCTAssertNotNil(json?["fill"], "icon.json 中应包含 fill 背景配置")
        print("✓ 测试 .icon 逆向成功: \(result.groupCount) 组, \(result.layerCount) 层")
    }
}
