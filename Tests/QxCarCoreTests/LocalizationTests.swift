import XCTest
import Foundation
@testable import QxCarCore

final class LocalizationTests: XCTestCase {

    func test所有支持的具体语言数量与定义() {
        let concreteLangs = AppLanguage.allConcreteCases
        XCTAssertEqual(concreteLangs.count, 9, "应支持中文、英文、日文、韩文、越南文、俄文、法文、德文、西班牙语 9 种具体语言")
        
        let expectedIdentifiers: Set<String> = [
            "zh-Hans", "en", "ja", "ko", "vi", "ru", "fr", "de", "es"
        ]
        let actualIdentifiers = Set(concreteLangs.map { $0.rawValue })
        XCTAssertEqual(actualIdentifiers, expectedIdentifiers, "语言标识符集合应当与预期一致")
    }

    func test所有具体语言的词条完整性无缺失() {
        for lang in AppLanguage.allConcreteCases {
            let missing = L10n.missingKeys(for: lang)
            XCTAssertTrue(
                missing.isEmpty,
                "语言 \(lang.rawValue) (\(lang.nativeDisplayName)) 缺失了以下词条: \(missing.map { $0.rawValue }.joined(separator: ", "))"
            )
            
            // 确保获取的字符串不为空
            for key in L10nKey.allCases {
                let str = L10n.string(key, language: lang)
                XCTAssertFalse(str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "词条 \(key.rawValue) 在 \(lang.rawValue) 中不应为空")
            }
        }
    }

    func test系统语言推导匹配逻辑() {
        // 中文推导
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["zh-Hans-CN", "en-US"]), .zhHans)
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["zh-Hant-TW", "en-US"]), .zhHans)
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["zh-HK"]), .zhHans)

        // 英语推导
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["en-US", "zh-Hans"]), .en)
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["en-GB"]), .en)

        // 日语推导
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["ja-JP", "en-US"]), .ja)

        // 韩语推导
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["ko-KR"]), .ko)

        // 越南语推导
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["vi-VN"]), .vi)

        // 俄语推导
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["ru-RU"]), .ru)

        // 法语推导
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["fr-FR", "en"]), .fr)

        // 德语推导
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["de-DE"]), .de)

        // 西班牙语推导
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["es-ES"]), .es)

        // 未支持语言默认回退至英文
        XCTAssertEqual(AppLanguage.resolveFromPreferredLanguages(["pt-BR", "it-IT"]), .en)
    }

    func test参数化文本格式化() {
        for lang in AppLanguage.allConcreteCases {
            let formatted = L10n.format(.msgIdentifiedFormat, language: lang, "TestApp", "3.2 MB")
            XCTAssertTrue(formatted.contains("TestApp"), "格式化字符串应当包含传入的应用名称 (语言: \(lang.rawValue))")
            XCTAssertTrue(formatted.contains("3.2 MB"), "格式化字符串应当包含传入的文件大小 (语言: \(lang.rawValue))")
        }
    }

    @MainActor
    func testLanguageManager单例切换与持久化() {
        let manager = LanguageManager.shared

        // 切换为日文
        manager.setLanguage(.ja)
        XCTAssertEqual(manager.selectedLanguage, .ja)
        XCTAssertEqual(manager.currentLanguage, .ja)
        XCTAssertEqual(manager.string(.btnExportAssets), "リソースをエクスポート")

        // 切换为英文
        manager.setLanguage(.en)
        XCTAssertEqual(manager.selectedLanguage, .en)
        XCTAssertEqual(manager.currentLanguage, .en)
        XCTAssertEqual(manager.string(.btnExportAssets), "Export Assets")

        // 切换为跟随系统
        manager.setLanguage(.system)
        XCTAssertEqual(manager.selectedLanguage, .system)
        XCTAssertEqual(manager.currentLanguage, AppLanguage.resolveSystemLanguage())

        // 检查菜单标题
        let followSystemTitle = L10n.menuItemTitle(for: .system, currentUiLang: .zhHans)
        XCTAssertEqual(followSystemTitle, "跟随系统")

        let jaTitle = L10n.menuItemTitle(for: .ja, currentUiLang: .zhHans)
        XCTAssertEqual(jaTitle, "日本語")
    }
}
