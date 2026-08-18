import Foundation

/// 应用支持的语言类型枚举
public enum AppLanguage: String, CaseIterable, Sendable, Codable {
    /// 跟随 macOS 系统偏好设置
    case system = "system"
    /// 简体中文
    case zhHans = "zh-Hans"
    /// 英语
    case en = "en"
    /// 日语
    case ja = "ja"
    /// 韩语
    case ko = "ko"
    /// 越南语
    case vi = "vi"
    /// 俄语
    case ru = "ru"
    /// 法语
    case fr = "fr"
    /// 德语
    case de = "de"
    /// 西班牙语
    case es = "es"

    /// 所有具体的语言选项（排除 .system）
    public static var allConcreteCases: [AppLanguage] {
        allCases.filter { $0 != .system }
    }

    /// 各语言在菜单中呈现的母语原生显示名称
    public var nativeDisplayName: String {
        switch self {
        case .system:
            return "跟随系统"
        case .zhHans:
            return "简体中文"
        case .en:
            return "English"
        case .ja:
            return "日本語"
        case .ko:
            return "한국어"
        case .vi:
            return "Tiếng Việt"
        case .ru:
            return "Русский"
        case .fr:
            return "Français"
        case .de:
            return "Deutsch"
        case .es:
            return "Español"
        }
    }

    /// 对应的系统 Locale
    public var locale: Locale {
        switch self {
        case .system:
            return Locale.current
        case .zhHans:
            return Locale(identifier: "zh-Hans")
        case .en:
            return Locale(identifier: "en")
        case .ja:
            return Locale(identifier: "ja")
        case .ko:
            return Locale(identifier: "ko")
        case .vi:
            return Locale(identifier: "vi")
        case .ru:
            return Locale(identifier: "ru")
        case .fr:
            return Locale(identifier: "fr")
        case .de:
            return Locale(identifier: "de")
        case .es:
            return Locale(identifier: "es")
        }
    }

    /**
     * 根据传入的语言标识符列表推导最匹配的支持语言
     * @param preferredLanguages 语言标识符列表（如 ["zh-Hans-CN", "en-US"]）
     * @return 匹配到的支持语言，未匹配则默认返回 .en
     */
    public static func resolveFromPreferredLanguages(_ preferredLanguages: [String]) -> AppLanguage {
        for identifier in preferredLanguages {
            let lower = identifier.lowercased()
            if lower.hasPrefix("zh") {
                return .zhHans
            } else if lower.hasPrefix("ja") {
                return .ja
            } else if lower.hasPrefix("ko") {
                return .ko
            } else if lower.hasPrefix("vi") {
                return .vi
            } else if lower.hasPrefix("ru") {
                return .ru
            } else if lower.hasPrefix("fr") {
                return .fr
            } else if lower.hasPrefix("de") {
                return .de
            } else if lower.hasPrefix("es") {
                return .es
            } else if lower.hasPrefix("en") {
                return .en
            }
        }
        return .en
    }

    /**
     * 根据系统当前的偏好语言推导具体的支持语言
     * @return 解析得到的具体语言
     */
    public static func resolveSystemLanguage() -> AppLanguage {
        let preferred = Locale.preferredLanguages
        if !preferred.isEmpty {
            return resolveFromPreferredLanguages(preferred)
        }
        if let code = Locale.current.language.languageCode?.identifier {
            return resolveFromPreferredLanguages([code])
        }
        return .zhHans
    }
}
