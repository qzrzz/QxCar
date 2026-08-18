import type { II18nConfig } from "qpage";

/**
 * QxCar 官网国际化多语言配置文件
 *
 * 遵循 qpage 配置规范，以简体中文（zh-Hans）为默认语言，
 * 并提供英文(en)、日文(ja)、韩文(ko)、越南文(vi)、葡萄牙文(pt)、西班牙文(es)、德文(de)、法文(fr)、俄文(ru) 9 种目标语言支持。
 * 保持清晰、专业、带有亲和力的表达风格，确保产品名称与术语的一致性。
 */
const i18n: II18nConfig = {
  defaultLang: "zh-Hans",
  langs: {
    // 默认语言（简体中文）
    "zh-Hans": {
      name: "简体中文",
    },

    // 英语 (English)
    en: {
      name: "English",
      page: {
        tagline: "Extract image assets and .icon source files from macOS app Assets.car",
        taglineShort: "Extract assets and icon source files from macOS apps",
        metaDesc: "Must-have for UI designers — extract image assets and .icon source files from macOS app Assets.car files.",
      },
      sections: [
        {
          id: "why",
          title: "Why You Need This",
          description:
            "macOS system icons are packed with exquisite design details. For UI designers, exploring and referencing these official icons is one of the most direct ways to master macOS icon design. QxCar extracts system icons from applications and restores them into .icon source files complete with layer structures and effect parameters. You can open, inspect, and edit them directly in Apple's official Icon Composer to see exactly how each layer and effect is crafted.",
          cards: [
            {
              imageDesc:
                "Assets.car is a binary asset catalog compiled and optimized by Apple developer tools from Assets.xcassets, allowing the system to efficiently load images, colors, and app icons at runtime.",
            },
          ],
        },
        {
          id: "what",
          title: "Extract Image Assets & .icon Source Files",
          description: "Simply drag and drop an application into QxCar to extract all image assets and generate .icon source files.",
        },
      ],
      ui: {
        download: "Download",
        viewOnGithub: "GitHub",
        selectPlatform: "Choose platform",
        thisDevice: "This device",
        langSwitchAria: "Select language",
        otherProducts: "Other Products",
        moreProducts: "More Products",
        productLinks: "Products",
        contact: "Contact",
        officialWebsite: "Website",
        docs: "Documentation",
        changelog: "Changelog",
      },
    },

    // 日语 (Japanese)
    ja: {
      name: "日本語",
      page: {
        tagline: "macOS アプリの Assets.car から画像アセットと .icon ソースファイルを抽出",
        taglineShort: "macOS アプリのアセットとアイコンソースファイルを抽出",
        metaDesc: "UI デザイナー必携。macOS アプリの Assets.car から画像アセットと .icon ソースファイルを抽出。",
      },
      sections: [
        {
          id: "why",
          title: "なぜこれが必要なのか",
          description:
            "macOS のシステムアイコンには、洗練されたデザインディテールが数多く詰め込まれています。UI デザイナーにとって、これらの公式アイコンを研究・参照することは、macOS アイコンデザインを学ぶ最も直接的な方法のひとつです。QxCar はアプリからシステムアイコンを抽出し、完全なレイヤー構造とエフェクトパラメータを含む .icon ソースファイルとして復元します。Apple 公式の Icon Composer で直接開いて確認・編集でき、各レイヤーや効果がどのように構成されているかを深く理解できます。",
          cards: [
            {
              imageDesc:
                "Assets.car は、Apple の開発ツールが Assets.xcassets などのリソースをコンパイル・最適化したバイナリパッケージです。システムが実行時に画像、カラー、アプリアイコンなどを高速にロードするために使用されます。",
            },
          ],
        },
        {
          id: "what",
          title: "画像アセットと .icon ソースファイルの抽出",
          description: "アプリを QxCar にドラッグ＆ドロップするだけで、すべての画像アセットを抽出し、.icon ソースファイルを生成します。",
        },
      ],
      ui: {
        download: "ダウンロード",
        viewOnGithub: "GitHub",
        selectPlatform: "プラットフォームを選択",
        thisDevice: "現在のデバイス",
        langSwitchAria: "言語を選択",
        otherProducts: "その他の製品",
        moreProducts: "その他の製品",
        productLinks: "製品",
        contact: "お問い合わせ",
        officialWebsite: "公式サイト",
        docs: "ドキュメント",
        changelog: "更新履歴",
      },
    },

    // 韩语 (Korean)
    ko: {
      name: "한국어",
      page: {
        tagline: "macOS 앱 Assets.car에서 이미지 에셋 및 .icon 소스 파일 추출",
        taglineShort: "macOS 앱의 리소스 및 아이콘 소스 파일 추출",
        metaDesc: "UI 디자이너 필수 툴 — macOS 앱의 Assets.car에서 이미지 에셋 및 .icon 소스 파일 추출.",
      },
      sections: [
        {
          id: "why",
          title: "왜 필요한가요?",
          description:
            "macOS 시스템 아이콘에는 정교하고 세밀한 디자인 디테일이 가득합니다. UI 디자이너에게 공식 아이콘을 살펴보고 연구하는 것은 macOS 아이콘 디자인을 배우는 가장 확실한 방법입니다. QxCar는 앱에서 시스템 아이콘을 추출하여 완벽한 레이어 구조와 효과 매개변수를 담은 .icon 소스 파일로 복원합니다. Apple 공식 Icon Composer로 바로 열어 확인하고 편집하며, 각 레이어와 효과가 어떻게 구성되었는지 깊이 있게 파악할 수 있습니다.",
          cards: [
            {
              imageDesc:
                "Assets.car는 Apple 개발 툴이 Assets.xcassets 등의 리소스를 컴파일하고 최적화하여 생성한 바이너리 패키지로, 시스템이 런타임에 이미지, 색상, 앱 아이콘 등을 효율적으로 불러오는 데 사용됩니다.",
            },
          ],
        },
        {
          id: "what",
          title: "이미지 에셋 및 .icon 소스 파일 추출",
          description: "앱을 QxCar로 드래그 앤 드롭하기만 하면 모든 이미지 에셋을 추출하고 .icon 소스 파일을 생성합니다.",
        },
      ],
      ui: {
        download: "다운로드",
        viewOnGithub: "GitHub",
        selectPlatform: "플랫폼 선택",
        thisDevice: "현재 기기",
        langSwitchAria: "언어 선택",
        otherProducts: "기타 제품",
        moreProducts: "더 많은 제품",
        productLinks: "제품",
        contact: "문의하기",
        officialWebsite: "공식 웹사이트",
        docs: "문서",
        changelog: "변경 내역",
      },
    },

    // 越南语 (Vietnamese)
    vi: {
      name: "Tiếng Việt",
      page: {
        tagline: "Trích xuất tài nguyên hình ảnh và tệp nguồn .icon từ Assets.car của ứng dụng macOS",
        taglineShort: "Trích xuất tài nguyên và tệp nguồn biểu tượng ứng dụng macOS",
        metaDesc: "Công cụ không thể thiếu cho UI Designer — trích xuất tài nguyên hình ảnh và tệp nguồn .icon từ Assets.car trên macOS.",
      },
      sections: [
        {
          id: "why",
          title: "Tại sao bạn cần công cụ này",
          description:
            "Biểu tượng hệ thống macOS chứa đựng rất nhiều chi tiết thiết kế tinh tế. Đối với các nhà thiết kế UI, việc nghiên cứu và tham khảo các biểu tượng chính thức này là một trong những cách trực tiếp nhất để làm chủ phong cách thiết kế biểu tượng macOS. QxCar trích xuất biểu tượng từ ứng dụng và khôi phục chúng thành các tệp nguồn .icon với cấu trúc layer và thông số hiệu ứng hoàn chỉnh. Bạn có thể mở, kiểm tra và chỉnh sửa trực tiếp bằng Icon Composer chính thức của Apple để hiểu rõ cách từng layer và hiệu ứng được xây dựng.",
          cards: [
            {
              imageDesc:
                "Assets.car là gói tài nguyên nhị phân được các công cụ phát triển của Apple biên dịch và tối ưu hóa từ Assets.xcassets, giúp hệ thống tải hình ảnh, màu sắc và biểu tượng ứng dụng một cách hiệu quả khi chạy.",
            },
          ],
        },
        {
          id: "what",
          title: "Trích xuất tài nguyên hình ảnh & tệp nguồn .icon",
          description: "Chỉ cần kéo và thả ứng dụng vào QxCar để trích xuất tất cả tài nguyên hình ảnh và tạo các tệp nguồn .icon.",
        },
      ],
      ui: {
        download: "Tải về",
        viewOnGithub: "GitHub",
        selectPlatform: "Chọn nền tảng",
        thisDevice: "Thiết bị này",
        langSwitchAria: "Chọn ngôn ngữ",
        otherProducts: "Sản phẩm khác",
        moreProducts: "Xem thêm sản phẩm",
        productLinks: "Sản phẩm",
        contact: "Liên hệ",
        officialWebsite: "Trang web chính thức",
        docs: "Tài liệu",
        changelog: "Nhật ký cập nhật",
      },
    },

    // 葡萄牙语 (Portuguese)
    pt: {
      name: "Português",
      page: {
        tagline: "Extraia recursos de imagem e arquivos fonte .icon do Assets.car de apps macOS",
        taglineShort: "Extraia recursos e arquivos fonte de ícones de apps macOS",
        metaDesc: "Essencial para designers de UI — extraia recursos de imagem e arquivos fonte .icon do Assets.car no macOS.",
      },
      sections: [
        {
          id: "why",
          title: "Por que você precisa disso",
          description:
            "Os ícones de sistema do macOS contêm detalhes de design requintados. Para designers de UI, estudar e referenciar esses ícones oficiais é uma das maneiras mais diretas de dominar o design de ícones do macOS. O QxCar extrai ícones de sistema de aplicativos e os restaura em arquivos fonte .icon completos, preservando a estrutura de camadas e parâmetros de efeitos. Você pode abrir, inspecionar e editar diretamente no Icon Composer oficial da Apple para entender a fundo a composição de cada camada e efeito.",
          cards: [
            {
              imageDesc:
                "Assets.car é um pacote binário compilado e otimizado pelas ferramentas de desenvolvimento da Apple a partir de Assets.xcassets, permitindo que o sistema carregue imagens, cores e ícones de apps de forma eficiente em tempo de execução.",
            },
          ],
        },
        {
          id: "what",
          title: "Extraia recursos de imagem e arquivos fonte .icon",
          description: "Basta arrastar e soltar o aplicativo no QxCar para extrair todos os recursos de imagem e gerar arquivos fonte .icon.",
        },
      ],
      ui: {
        download: "Baixar",
        viewOnGithub: "GitHub",
        selectPlatform: "Escolha a plataforma",
        thisDevice: "Este dispositivo",
        langSwitchAria: "Selecionar idioma",
        otherProducts: "Outros produtos",
        moreProducts: "Mais produtos",
        productLinks: "Produtos",
        contact: "Contato",
        officialWebsite: "Site oficial",
        docs: "Documentação",
        changelog: "Histórico de versões",
      },
    },

    // 西班牙语 (Spanish)
    es: {
      name: "Español",
      page: {
        tagline: "Extrae recursos de imagen y archivos fuente .icon de Assets.car de apps de macOS",
        taglineShort: "Extrae recursos y archivos fuente de iconos de aplicaciones macOS",
        metaDesc: "Imprescindible para diseñadores de UI: extrae recursos de imagen y archivos fuente .icon de Assets.car en macOS.",
      },
      sections: [
        {
          id: "why",
          title: "¿Por qué lo necesitas?",
          description:
            "Los iconos del sistema macOS albergan detalles de diseño sumamente refinados. Para los diseñadores de UI, estudiar y consultar estos iconos oficiales es una de las formas más directas de aprender el diseño de iconos de macOS. QxCar extrae los iconos de las aplicaciones y los restaura como archivos fuente .icon con su estructura completa de capas y parámetros de efectos. Puedes abrirlos, inspeccionarlos y editarlos directamente en el Icon Composer oficial de Apple para comprender en detalle cómo está compuesto cada elemento.",
          cards: [
            {
              imageDesc:
                "Assets.car es un paquete binário de recursos compilado y optimizado por las herramientas de desarrollo de Apple a partir de Assets.xcassets, que permite al sistema cargar de manera eficiente imágenes, colores e iconos durante la ejecución.",
            },
          ],
        },
        {
          id: "what",
          title: "Extraer recursos de imagen y archivos fuente .icon",
          description: "Arrastra y suelta la aplicación en QxCar para extraer todos los recursos de imagen y generar archivos fuente .icon.",
        },
      ],
      ui: {
        download: "Descargar",
        viewOnGithub: "GitHub",
        selectPlatform: "Elegir plataforma",
        thisDevice: "Este dispositivo",
        langSwitchAria: "Seleccionar idioma",
        otherProducts: "Otros productos",
        moreProducts: "Más productos",
        productLinks: "Productos",
        contact: "Contacto",
        officialWebsite: "Sitio web",
        docs: "Documentación",
        changelog: "Registro de cambios",
      },
    },

    // 德语 (German)
    de: {
      name: "Deutsch",
      page: {
        tagline: "Bildressourcen und .icon-Quelldateien aus macOS Assets.car extrahieren",
        taglineShort: "Ressourcen und Icon-Quelldateien aus macOS-Apps extrahieren",
        metaDesc: "Unverzichtbar für UI-Designer: Extrahieren Sie Bildressourcen und .icon-Quelldateien aus macOS Assets.car.",
      },
      sections: [
        {
          id: "why",
          title: "Warum Sie es brauchen",
          description:
            "macOS-Systemsymbole enthalten viele raffinierte Designdetails. Für UI-Designer ist das Studium dieser offiziellen Icons einer der direktesten Wege, das macOS-Icon-Design zu verstehen. QxCar extrahiert Systemsymbole aus Apps und stellt sie als .icon-Quelldateien mit vollständigen Ebenenstrukturen und Effektparametern wieder her. Sie können diese direkt im offiziellen Apple Icon Composer öffnen, prüfen und bearbeiten, um den Aufbau jeder Ebene und jedes Effekts im Detail nachzuvollziehen.",
          cards: [
            {
              imageDesc:
                "Assets.car ist ein von Apple-Entwicklertools aus Assets.xcassets kompiliertes und optimiertes Binärpaket, mit dem das System Bilder, Farben und App-Symbole zur Laufzeit hocheffizient lädt.",
            },
          ],
        },
        {
          id: "what",
          title: "Bildressourcen und .icon-Quelldateien extrahieren",
          description: "Ziehen Sie eine App einfach per Drag & Drop in QxCar, um alle Bildressourcen zu extrahieren und .icon-Quelldateien zu generieren.",
        },
      ],
      ui: {
        download: "Herunterladen",
        viewOnGithub: "GitHub",
        selectPlatform: "Plattform wählen",
        thisDevice: "Dieses Gerät",
        langSwitchAria: "Sprache wählen",
        otherProducts: "Andere Produkte",
        moreProducts: "Mehr Produkte",
        productLinks: "Produkte",
        contact: "Kontakt",
        officialWebsite: "Offizielle Website",
        docs: "Dokumentation",
        changelog: "Änderungsprotokoll",
      },
    },

    // 法语 (French)
    fr: {
      name: "Français",
      page: {
        tagline: "Extrayez les ressources d'images et les fichiers sources .icon depuis Assets.car sur macOS",
        taglineShort: "Extrayez les ressources et fichiers sources d'icônes d'applications macOS",
        metaDesc: "Indispensable pour les designers UI : extrayez les ressources d'images et les fichiers sources .icon d'Assets.car sur macOS.",
      },
      sections: [
        {
          id: "why",
          title: "Pourquoi en avez-vous besoin ?",
          description:
            "Les icônes système de macOS regorgent de détails de conception subtils. Pour les designers UI, analyser et s'inspirer de ces icônes officielles constitue le moyen le plus direct de maîtriser le design d'icônes macOS. QxCar extrait les icônes système des applications et les restitue sous forme de fichiers sources .icon dotés d'une structure de calques et de paramètres d'effets complets. Vous pouvez les ouvrir, les examiner et les modifier directement dans l'Icon Composer officiel d'Apple pour comprendre comment chaque calque et effet est composé.",
          cards: [
            {
              imageDesc:
                "Assets.car est une archive binaire compilée et optimisée par les outils de développement Apple à partir d'Assets.xcassets, permettant au système de charger efficacement images, couleurs et icônes à l'exécution.",
            },
          ],
        },
        {
          id: "what",
          title: "Extraire les ressources d'images et les fichiers sources .icon",
          description: "Glissez-déposez simplement une application dans QxCar pour extraire l'ensemble des ressources d'images et générer des fichiers sources .icon.",
        },
      ],
      ui: {
        download: "Télécharger",
        viewOnGithub: "GitHub",
        selectPlatform: "Choisir la plateforme",
        thisDevice: "Cet appareil",
        langSwitchAria: "Choisir la langue",
        otherProducts: "Autres produits",
        moreProducts: "Plus de produits",
        productLinks: "Produits",
        contact: "Contact",
        officialWebsite: "Site officiel",
        docs: "Documentation",
        changelog: "Journal des modifications",
      },
    },

    // 俄语 (Russian)
    ru: {
      name: "Русский",
      page: {
        tagline: "Извлечение графических ресурсов и исходных файлов .icon из Assets.car приложений macOS",
        taglineShort: "Извлечение ресурсов и исходных файлов иконок приложений macOS",
        metaDesc: "Незаменимый инструмент для UI-дизайнеров: извлечение графических ресурсов и исходных файлов .icon из Assets.car на macOS.",
      },
      sections: [
        {
          id: "why",
          title: "Зачем это нужно",
          description:
            "Системные иконки macOS содержат множество изящных деталей дизайна. Для UI-дизайнеров изучение и анализ официальных иконок — один из самых прямых способов освоить дизайн иконок в стиле macOS. QxCar извлекает системные иконки из приложений и восстанавливает их в исходные файлы .icon с полной структурой слоев и параметрами эффектов. Вы можете открывать, просматривать и редактировать их прямо в официальном Apple Icon Composer, чтобы детально понять устройство каждого слоя и эффекта.",
          cards: [
            {
              imageDesc:
                "Assets.car — это скомпилированный и оптимизированный инструментами разработки Apple бинарный пакет ресурсов из Assets.xcassets, используемый системой для быстрой загрузки изображений, цветов и иконок во время работы.",
            },
          ],
        },
        {
          id: "what",
          title: "Извлечение графических ресурсов и исходных файлов .icon",
          description: "Просто перетащите приложение в QxCar, чтобы извлечь все графические ресурсы и создать исходные файлы .icon.",
        },
      ],
      ui: {
        download: "Скачать",
        viewOnGithub: "GitHub",
        selectPlatform: "Выбрать платформу",
        thisDevice: "Это устройство",
        langSwitchAria: "Выбрать язык",
        otherProducts: "Другие продукты",
        moreProducts: "Все продукты",
        productLinks: "Продукты",
        contact: "Контакты",
        officialWebsite: "Официальный сайт",
        docs: "Документация",
        changelog: "История изменений",
      },
    },
  },
};

export default i18n;
