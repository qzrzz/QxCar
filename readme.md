# QxCar

**QxCar** 是一款基于 Swift 与 SwiftUI 构建的 macOS 资产导出与 Liquid Glass（液态玻璃）`.icon` 逆向工程工具。

---

## ✨ 核心特性

- 🔮 **macOS 27 液态玻璃设计**：采用现代 Liquid Glass 窗口质感、半透明折射材质与微光交互卡片。
- 📦 **智能路径识别**：直接拖入 `Assets.car` 或 `.app` 应用程序包，自动递归定位内部资产并解析图标堆栈（如 `AppIcon`、`AppIconUpdated`）。
- 🎨 **全量资产导出**：一键将 `Assets.car` 中的全部 PNG（1x/2x/3x）、SVG 矢量图、PDF 文档与颜色表导出至 `./outputDir/assets/`。
- 🪄 **Liquid Glass .icon 逆向重构**：
  - 参考 `decant` 逆向模型，通过底层 CoreUI / CoreSVG 框架深度解析编译后的 `IconImageStack`；
  - 完整还原多外观特化（Light / Dark / Tinted Specializations）、混合模式（Blend Mode）、图层位置与缩放变换（Scale & Translation）、高光位置（Specular Location）、折射强度与深度（Refractivity）、画布渐变填充（Canvas Fill）；
  - 组装生成 Icon Composer 可直接打开编辑的 `.icon` 格式文件夹与 `icon.json`；
  - 支持 `actool` 实时自动化校验。
- 🚀 **工程化脚本驱动**：参考 `QLaunchpad`，使用 `bun` 驱动 `dev`、`build`、`release` 与 `clean` 流程。

---

## 🛠️ 构建与开发

使用 `bun` 作为包管理与脚本运行工具：

```bash
# 启动开发调试模式 (自动构建并启动 App)
bun run dev

# 生产级构建 (输出至 build/Release/QxCar.app)
bun run build

# 发布构建 (递增版本并生成 Zip 归档)
bun run release

# 运行单元测试
bun test
```

---

## 💻 目录结构

```
QxCar/
├── Package.swift                    # Swift PM 工程配置
├── package.json                     # Bun 依赖与脚本配置
├── scripts/                         # 自动化构建与发布脚本 (TypeScript)
│   ├── build-app.ts                 # App 打包与代码签名
│   ├── dev.ts                       # 开发模式启动器
│   ├── release.ts                   # 生产与发布打包器
│   ├── version.ts                   # 版本与构建编号管理
│   └── clean.ts                     # 缓存清理
├── Sources/
│   ├── QxCarCoreBridge/             # CoreUI & CoreSVG 私有框架动态桥接层
│   ├── QxCarCore/                   # 核心服务 (发现、素材导出、.icon 逆向引擎)
│   └── QxCar/                       # SwiftUI 主界面与 Liquid Glass 视图组件
└── Tests/
    └── QxCarCoreTests/              # 核心单元测试
```

---

## 📄 License
MIT License.
