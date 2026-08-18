import Foundation

/// 多语言字符串键定义
public enum L10nKey: String, CaseIterable, Sendable {
    // 菜单相关
    case menuLanguage
    case menuFollowSystem
    case menuCheckForUpdates

    // 投放区相关
    case dropZonePrompt
    case dropZoneSubPrompt
    case chooseFilePrompt
    case tipRemoveAndReselect
    case tipClearMessage

    // 输出目录配置相关
    case btnChange
    case tipOpenInFinder
    case selectOutputFolderPrompt

    // 状态与动作按钮相关
    case statusReady
    case statusExporting
    case statusExportCompleted
    case statusNoAssetsFound
    case btnShowInFinder
    case btnOpenIcon
    case btnExportAssets

    // 错误与提示信息
    case errAppBundleNoCar
    case errInvalidCarPath
    case msgInitialPrompt
    case msgCarNotFound
    case msgInitializingExport
    case msgExportSuccess
    case msgExportFailedPrefix
    case msgPleaseDropFirst
    case msgSelectExportMode
    case msgIdentifiedFormat
}

/// 集中式多语言文本提供器
public enum L10n {
    /// 完整的多语言字典映射表
    private static let translations: [AppLanguage: [L10nKey: String]] = [
        // 1. 简体中文
        .zhHans: [
            .menuLanguage: "语言",
            .menuFollowSystem: "跟随系统",
            .menuCheckForUpdates: "检查更新…",
            .dropZonePrompt: "拖入 Assets.car 或 .app 文件夹",
            .dropZoneSubPrompt: "或点击选取文件",
            .chooseFilePrompt: "选取",
            .tipRemoveAndReselect: "移除并重新选择",
            .tipClearMessage: "清除提示",
            .btnChange: "更改...",
            .tipOpenInFinder: "在访达中打开此目录",
            .selectOutputFolderPrompt: "选择输出目录",
            .statusReady: "就绪",
            .statusExporting: "正在导出...",
            .statusExportCompleted: "导出完成",
            .statusNoAssetsFound: "未找到资源",
            .btnShowInFinder: "在访达中显示",
            .btnOpenIcon: "打开 .icon",
            .btnExportAssets: "导出资源",
            .errAppBundleNoCar: "该应用包内未找到 Assets.car 资源文件",
            .errInvalidCarPath: "该路径不是有效的 Assets.car 或未包含资源",
            .msgInitialPrompt: "请拖入 Assets.car 文件或 .app 应用程序包",
            .msgCarNotFound: "未找到 Assets.car 资源文件",
            .msgInitializingExport: "正在初始化导出任务...",
            .msgExportSuccess: "✨ 导出全部完成!",
            .msgExportFailedPrefix: "导出失败: %@",
            .msgPleaseDropFirst: "请先拖入包含有效 Assets.car 的文件或 .app",
            .msgSelectExportMode: "请至少勾选一种导出模式",
            .msgIdentifiedFormat: "已识别: %1$@ (%2$@)"
        ],

        // 2. 英语 (English)
        .en: [
            .menuLanguage: "Language",
            .menuFollowSystem: "System Default",
            .menuCheckForUpdates: "Check for Updates…",
            .dropZonePrompt: "Drop Assets.car or .app bundle here",
            .dropZoneSubPrompt: "or click to select file",
            .chooseFilePrompt: "Choose",
            .tipRemoveAndReselect: "Remove and reselect",
            .tipClearMessage: "Clear message",
            .btnChange: "Change...",
            .tipOpenInFinder: "Open this directory in Finder",
            .selectOutputFolderPrompt: "Select Output Directory",
            .statusReady: "Ready",
            .statusExporting: "Exporting...",
            .statusExportCompleted: "Export completed",
            .statusNoAssetsFound: "No assets found",
            .btnShowInFinder: "Show in Finder",
            .btnOpenIcon: "Open .icon",
            .btnExportAssets: "Export Assets",
            .errAppBundleNoCar: "Assets.car not found in this application bundle",
            .errInvalidCarPath: "This path is not a valid Assets.car or contains no assets",
            .msgInitialPrompt: "Please drop an Assets.car file or .app bundle",
            .msgCarNotFound: "Assets.car asset file not found",
            .msgInitializingExport: "Initializing export task...",
            .msgExportSuccess: "✨ Export completed successfully!",
            .msgExportFailedPrefix: "Export failed: %@",
            .msgPleaseDropFirst: "Please drop a valid Assets.car or .app first",
            .msgSelectExportMode: "Please select at least one export mode",
            .msgIdentifiedFormat: "Identified: %1$@ (%2$@)"
        ],

        // 3. 日语 (日本語)
        .ja: [
            .menuLanguage: "言語",
            .menuFollowSystem: "システム設定に従う",
            .menuCheckForUpdates: "アップデートを確認…",
            .dropZonePrompt: "Assets.car または .app をここにドラッグ",
            .dropZoneSubPrompt: "またはクリックしてファイルを選択",
            .chooseFilePrompt: "選択",
            .tipRemoveAndReselect: "削除して再選択",
            .tipClearMessage: "メッセージを消去",
            .btnChange: "変更...",
            .tipOpenInFinder: "Finder でこのフォルダを開く",
            .selectOutputFolderPrompt: "出力先フォルダを選択",
            .statusReady: "準備完了",
            .statusExporting: "エクスポート中...",
            .statusExportCompleted: "エクスポート完了",
            .statusNoAssetsFound: "リソースが見つかりません",
            .btnShowInFinder: "Finder で表示",
            .btnOpenIcon: ".icon を開く",
            .btnExportAssets: "リソースをエクスポート",
            .errAppBundleNoCar: "このアプリバンドル内に Assets.car が見つかりませんでした",
            .errInvalidCarPath: "有効な Assets.car ではないか、リソースが含まれていません",
            .msgInitialPrompt: "Assets.car ファイルまたは .app パッケージをドラッグしてください",
            .msgCarNotFound: "Assets.car リソースファイルが見つかりません",
            .msgInitializingExport: "エクスポートタスクを初期化中...",
            .msgExportSuccess: "✨ エクスポートがすべて完了しました！",
            .msgExportFailedPrefix: "エクスポート失敗: %@",
            .msgPleaseDropFirst: "有効な Assets.car または .app を先にドラッグしてください",
            .msgSelectExportMode: "少なくとも1つのエクスポートモードを選択してください",
            .msgIdentifiedFormat: "識別完了: %1$@ (%2$@)"
        ],

        // 4. 韩语 (한국어)
        .ko: [
            .menuLanguage: "언어",
            .menuFollowSystem: "시스템 설정 따름",
            .menuCheckForUpdates: "업데이트 확인…",
            .dropZonePrompt: "Assets.car 또는 .app 번들을 드래그하세요",
            .dropZoneSubPrompt: "또는 클릭하여 파일 선택",
            .chooseFilePrompt: "선택",
            .tipRemoveAndReselect: "제거하고 다시 선택",
            .tipClearMessage: "메시지 지우기",
            .btnChange: "변경...",
            .tipOpenInFinder: "Finder에서 이 폴더 열기",
            .selectOutputFolderPrompt: "출력 폴더 선택",
            .statusReady: "준비됨",
            .statusExporting: "내보내는 중...",
            .statusExportCompleted: "내보내기 완료",
            .statusNoAssetsFound: "리소스를 찾을 수 없음",
            .btnShowInFinder: "Finder에서 보기",
            .btnOpenIcon: ".icon 열기",
            .btnExportAssets: "리소스 내보내기",
            .errAppBundleNoCar: "해당 앱 번들 내에서 Assets.car를 찾을 수 없습니다",
            .errInvalidCarPath: "유효한 Assets.car가 아니거나 리소스가 포함되어 있지 않습니다",
            .msgInitialPrompt: "Assets.car 파일 또는 .app 애플리케이션 번들을 드래그하세요",
            .msgCarNotFound: "Assets.car 리소스 파일을 찾을 수 없습니다",
            .msgInitializingExport: "내보내기 작업을 초기화하는 중...",
            .msgExportSuccess: "✨ 내보내기가 모두 완료되었습니다!",
            .msgExportFailedPrefix: "내보내기 실패: %@",
            .msgPleaseDropFirst: "유효한 Assets.car 또는 .app을 먼저 드래그하세요",
            .msgSelectExportMode: "최소 하나의 내보내기 모드를 선택하세요",
            .msgIdentifiedFormat: "식별됨: %1$@ (%2$@)"
        ],

        // 5. 越南语 (Tiếng Việt)
        .vi: [
            .menuLanguage: "Ngôn ngữ",
            .menuFollowSystem: "Theo hệ thống",
            .menuCheckForUpdates: "Kiểm tra bản cập nhật…",
            .dropZonePrompt: "Kéo thả Assets.car hoặc gói .app vào đây",
            .dropZoneSubPrompt: "hoặc nhấn để chọn tệp",
            .chooseFilePrompt: "Chọn",
            .tipRemoveAndReselect: "Xóa và chọn lại",
            .tipClearMessage: "Xóa thông báo",
            .btnChange: "Thay đổi...",
            .tipOpenInFinder: "Mở thư mục này trong Finder",
            .selectOutputFolderPrompt: "Chọn thư mục đầu ra",
            .statusReady: "Sẵn sàng",
            .statusExporting: "Đang xuất...",
            .statusExportCompleted: "Xuất hoàn tất",
            .statusNoAssetsFound: "Không tìm thấy tài nguyên",
            .btnShowInFinder: "Hiển thị trong Finder",
            .btnOpenIcon: "Mở .icon",
            .btnExportAssets: "Xuất tài nguyên",
            .errAppBundleNoCar: "Không tìm thấy tệp tài nguyên Assets.car trong gói ứng dụng này",
            .errInvalidCarPath: "Đường dẫn không phải là Assets.car hợp lệ hoặc không chứa tài nguyên",
            .msgInitialPrompt: "Vui lòng kéo thả tệp Assets.car hoặc gói ứng dụng .app",
            .msgCarNotFound: "Không tìm thấy tệp tài nguyên Assets.car",
            .msgInitializingExport: "Đang khởi tạo tác vụ xuất...",
            .msgExportSuccess: "✨ Xuất hoàn tất thành công!",
            .msgExportFailedPrefix: "Xuất thất bại: %@",
            .msgPleaseDropFirst: "Vui lòng kéo thả Assets.car hoặc .app hợp lệ trước",
            .msgSelectExportMode: "Vui lòng chọn ít nhất một chế độ xuất",
            .msgIdentifiedFormat: "Đã nhận diện: %1$@ (%2$@)"
        ],

        // 6. 俄语 (Русский)
        .ru: [
            .menuLanguage: "Язык",
            .menuFollowSystem: "Как в системе",
            .menuCheckForUpdates: "Проверить обновления…",
            .dropZonePrompt: "Перетащите сюда Assets.car или пакет .app",
            .dropZoneSubPrompt: "или нажмите для выбора файла",
            .chooseFilePrompt: "Выбрать",
            .tipRemoveAndReselect: "Удалить и выбрать заново",
            .tipClearMessage: "Скрыть сообщение",
            .btnChange: "Изменить...",
            .tipOpenInFinder: "Открыть эту папку в Finder",
            .selectOutputFolderPrompt: "Выберите папку для экспорта",
            .statusReady: "Готово",
            .statusExporting: "Экспорт...",
            .statusExportCompleted: "Экспорт завершен",
            .statusNoAssetsFound: "Ресурсы не найдены",
            .btnShowInFinder: "Показать в Finder",
            .btnOpenIcon: "Открыть .icon",
            .btnExportAssets: "Экспортировать ресурсы",
            .errAppBundleNoCar: "Файл Assets.car не найден в этом пакете приложения",
            .errInvalidCarPath: "Недопустимый путь к Assets.car или нет ресурсов",
            .msgInitialPrompt: "Перетащите файл Assets.car или пакет приложения .app",
            .msgCarNotFound: "Файл ресурсов Assets.car не найден",
            .msgInitializingExport: "Инициализация задачи экспорта...",
            .msgExportSuccess: "✨ Экспорт успешно завершен!",
            .msgExportFailedPrefix: "Ошибка экспорта: %@",
            .msgPleaseDropFirst: "Сначала перетащите действительный Assets.car или .app",
            .msgSelectExportMode: "Выберите хотя бы один режим экспорта",
            .msgIdentifiedFormat: "Определено: %1$@ (%2$@)"
        ],

        // 7. 法语 (Français)
        .fr: [
            .menuLanguage: "Langue",
            .menuFollowSystem: "Par défaut du système",
            .menuCheckForUpdates: "Rechercher les mises à jour…",
            .dropZonePrompt: "Déposez Assets.car ou un paquet .app ici",
            .dropZoneSubPrompt: "ou cliquez pour choisir un fichier",
            .chooseFilePrompt: "Choisir",
            .tipRemoveAndReselect: "Supprimer et resélectionner",
            .tipClearMessage: "Effacer le message",
            .btnChange: "Modifier...",
            .tipOpenInFinder: "Ouvrir ce dossier dans le Finder",
            .selectOutputFolderPrompt: "Sélectionner le dossier de sortie",
            .statusReady: "Prêt",
            .statusExporting: "Exportation en cours...",
            .statusExportCompleted: "Exportation terminée",
            .statusNoAssetsFound: "Aucune ressource trouvée",
            .btnShowInFinder: "Afficher dans le Finder",
            .btnOpenIcon: "Ouvrir .icon",
            .btnExportAssets: "Exporter les ressources",
            .errAppBundleNoCar: "Fichier Assets.car introuvable dans ce paquet d'application",
            .errInvalidCarPath: "Chemin Assets.car non valide ou ne contenant aucune ressource",
            .msgInitialPrompt: "Veuillez déposer un fichier Assets.car ou un paquet d'application .app",
            .msgCarNotFound: "Fichier de ressources Assets.car introuvable",
            .msgInitializingExport: "Initialisation de la tâche d'exportation...",
            .msgExportSuccess: "✨ Exportation terminée avec succès !",
            .msgExportFailedPrefix: "Échec de l'exportation : %@",
            .msgPleaseDropFirst: "Veuillez d'abord déposer un fichier Assets.car ou .app valide",
            .msgSelectExportMode: "Veuillez sélectionner au moins un mode d'exportation",
            .msgIdentifiedFormat: "Identifié : %1$@ (%2$@)"
        ],

        // 8. 德语 (Deutsch)
        .de: [
            .menuLanguage: "Sprache",
            .menuFollowSystem: "Systemstandard",
            .menuCheckForUpdates: "Nach Updates suchen…",
            .dropZonePrompt: "Assets.car oder .app-Paket hierher ziehen",
            .dropZoneSubPrompt: "oder klicken, um eine Datei auszuwählen",
            .chooseFilePrompt: "Auswählen",
            .tipRemoveAndReselect: "Entfernen und neu auswählen",
            .tipClearMessage: "Hinweis ausblenden",
            .btnChange: "Ändern...",
            .tipOpenInFinder: "Diesen Ordner im Finder öffnen",
            .selectOutputFolderPrompt: "Ausgabeverzeichnis auswählen",
            .statusReady: "Bereit",
            .statusExporting: "Wird exportiert...",
            .statusExportCompleted: "Export abgeschlossen",
            .statusNoAssetsFound: "Keine Ressourcen gefunden",
            .btnShowInFinder: "Im Finder anzeigen",
            .btnOpenIcon: ".icon öffnen",
            .btnExportAssets: "Ressourcen exportieren",
            .errAppBundleNoCar: "Keine Assets.car-Ressourcendatei in diesem Anwendungspaket gefunden",
            .errInvalidCarPath: "Ungültiger Assets.car-Pfad oder enthält keine Ressourcen",
            .msgInitialPrompt: "Bitte eine Assets.car-Datei oder ein .app-Anwendungspaket hineinziehen",
            .msgCarNotFound: "Assets.car-Ressourcendatei nicht gefunden",
            .msgInitializingExport: "Exportaufgabe wird initialisiert...",
            .msgExportSuccess: "✨ Export erfolgreich abgeschlossen!",
            .msgExportFailedPrefix: "Export fehlgeschlagen: %@",
            .msgPleaseDropFirst: "Bitte ziehen Sie zuerst eine gültige Assets.car oder .app hinein",
            .msgSelectExportMode: "Bitte wählen Sie mindestens einen Exportmodus",
            .msgIdentifiedFormat: "Erkannt: %1$@ (%2$@)"
        ],

        // 9. 西班牙语 (Español)
        .es: [
            .menuLanguage: "Idioma",
            .menuFollowSystem: "Predeterminado del sistema",
            .menuCheckForUpdates: "Buscar actualizaciones…",
            .dropZonePrompt: "Arrastra Assets.car o paquete .app aquí",
            .dropZoneSubPrompt: "o haz clic para seleccionar un archivo",
            .chooseFilePrompt: "Seleccionar",
            .tipRemoveAndReselect: "Eliminar y volver a seleccionar",
            .tipClearMessage: "Borrar mensaje",
            .btnChange: "Cambiar...",
            .tipOpenInFinder: "Abrir este directorio en Finder",
            .selectOutputFolderPrompt: "Seleccionar directorio de salida",
            .statusReady: "Listo",
            .statusExporting: "Exportando...",
            .statusExportCompleted: "Exportación completada",
            .statusNoAssetsFound: "No se encontraron recursos",
            .btnShowInFinder: "Mostrar en Finder",
            .btnOpenIcon: "Abrir .icon",
            .btnExportAssets: "Exportar recursos",
            .errAppBundleNoCar: "No se encontró el archivo Assets.car en este paquete de aplicación",
            .errInvalidCarPath: "Ruta de Assets.car no válida o no contiene recursos",
            .msgInitialPrompt: "Arrastra un archivo Assets.car o paquete de aplicación .app",
            .msgCarNotFound: "No se encontró el archivo de recursos Assets.car",
            .msgInitializingExport: "Inicializando tarea de exportación...",
            .msgExportSuccess: "✨ ¡Exportación completada con éxito!",
            .msgExportFailedPrefix: "Error al exportar: %@",
            .msgPleaseDropFirst: "Arrastra primero un Assets.car o .app válido",
            .msgSelectExportMode: "Selecciona al menos un modo de exportación",
            .msgIdentifiedFormat: "Identificado: %1$@ (%2$@)"
        ]
    ]

    /**
     * 获取指定语言下的本地化文本
     * @param key 字符串词条键
     * @param language 目标语言（如为 .system 则根据系统推导）
     * @return 对应的本地化文本
     */
    public static func string(_ key: L10nKey, language: AppLanguage) -> String {
        let concreteLang = language == .system ? AppLanguage.resolveSystemLanguage() : language
        if let text = translations[concreteLang]?[key] {
            return text
        }
        // 如果当前语言缺失该词条，回退到英文或简体中文
        if let fallbackEn = translations[.en]?[key] {
            return fallbackEn
        }
        if let fallbackZh = translations[.zhHans]?[key] {
            return fallbackZh
        }
        return key.rawValue
    }

    /**
     * 格式化包含参数的本地化文本
     * @param key 字符串词条键
     * @param language 目标语言
     * @param arguments 填充参数
     * @return 格式化后的本地化文本
     */
    public static func format(_ key: L10nKey, language: AppLanguage, _ arguments: CVarArg...) -> String {
        let pattern = string(key, language: language)
        return String(format: pattern, locale: language.locale, arguments: arguments)
    }

    /**
     * 获取指定语言在 UI 菜单中的完整显示标题（如包含本地翻译与原生自称）
     * @param targetLang 目标语言项
     * @param currentUiLang 当前界面生效的语言
     * @return 菜单项标题文本
     */
    public static func menuItemTitle(for targetLang: AppLanguage, currentUiLang: AppLanguage) -> String {
        if targetLang == .system {
            return string(.menuFollowSystem, language: currentUiLang)
        }
        return targetLang.nativeDisplayName
    }

    /**
     * 校验字典完整性：检查指定语言是否包含所有键
     * @param language 要检查的语言
     * @return 缺失的键列表
     */
    public static func missingKeys(for language: AppLanguage) -> [L10nKey] {
        guard let langDict = translations[language] else {
            return L10nKey.allCases
        }
        return L10nKey.allCases.filter { langDict[$0] == nil }
    }
}
