import Foundation
import Combine

/// 应用全局语言管理中心（单例 & 响应式状态）
@MainActor
public final class LanguageManager: ObservableObject {
    /// 全局共享单例
    public static let shared = LanguageManager()

    /// 存储于 UserDefaults 的偏好设置键名
    public static let userDefaultsKey = "app_language"

    /// 用户在菜单中选定的语言（默认为 .system 跟随系统）
    @Published public var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: Self.userDefaultsKey)
            updateCurrentLanguage()
        }
    }

    /// 实际生效的当前语言（如果用户选了 .system，则动态解析为匹配的 concrete 语言）
    @Published public private(set) var currentLanguage: AppLanguage

    private var cancellables = Set<AnyCancellable>()

    private init() {
        let initialSelected: AppLanguage
        if let savedRaw = UserDefaults.standard.string(forKey: Self.userDefaultsKey),
           let savedLang = AppLanguage(rawValue: savedRaw) {
            initialSelected = savedLang
        } else {
            initialSelected = .system
        }

        self.selectedLanguage = initialSelected
        self.currentLanguage = (initialSelected == .system) ? AppLanguage.resolveSystemLanguage() : initialSelected

        // 监听系统语言与区域变化通知，当用户处于「跟随系统」时即时热刷新
        NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleSystemLocaleChange()
                }
            }
            .store(in: &cancellables)
    }

    /**
     * 手动切换应用语言
     * @param language 用户选定的目标语言
     */
    public func setLanguage(_ language: AppLanguage) {
        self.selectedLanguage = language
    }

    /**
     * 获取当前生效语言下的文本
     * @param key 词条键名
     * @return 本地化字符串
     */
    public func string(_ key: L10nKey) -> String {
        L10n.string(key, language: currentLanguage)
    }

    /**
     * 格式化当前生效语言下的动态文本
     * @param key 词条键名
     * @param arguments 填充参数
     * @return 格式化后的本地化字符串
     */
    public func format(_ key: L10nKey, _ arguments: CVarArg...) -> String {
        let pattern = L10n.string(key, language: currentLanguage)
        return String(format: pattern, locale: currentLanguage.locale, arguments: arguments)
    }

    /// 内部更新当前实际生效语言并触发 UI 刷新
    private func updateCurrentLanguage() {
        if selectedLanguage == .system {
            self.currentLanguage = AppLanguage.resolveSystemLanguage()
        } else {
            self.currentLanguage = selectedLanguage
        }
    }

    /// 处理系统区域/语言变更事件
    private func handleSystemLocaleChange() {
        guard selectedLanguage == .system else { return }
        let newResolved = AppLanguage.resolveSystemLanguage()
        if newResolved != currentLanguage {
            self.currentLanguage = newResolved
        }
    }
}
