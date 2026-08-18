# QxCar 开发规范与说明 (DEV.md)

## 项目概述
QxCar 是一个面向 macOS 的现代化资源导出与 Liquid Glass（液态玻璃）`.icon` 逆向工程工具。
基于 Swift + SwiftUI 原生构建，通过 `bun` 与 npm scripts 驱动工程化编译与打包流程。

## 技术栈与工程架构
- **语言**：Swift 6.0 / Objective-C (CoreUI 私有桥接)
- **UI 框架**：SwiftUI (macOS 27 Liquid Glass 设计风格)
- **包管理与构建脚本**：`bun` (TypeScript 脚本)
- **底层技术**：Apple CoreUI / CoreSVG 动态符号解析与反向重构
- **测试框架**：`XCTest` / `swift test`

## 常用脚本命令
```bash
bun run dev          # 启动开发调试模式（构建 Debug 应用并立即运行）
bun run build        # 构建生产级应用包 build/Release/QxCar.app 并打包
bun run release      # 构建并发布压缩包
bun run clean        # 清理 build/ 与 .build/ 构建缓存
bun run test         # 运行 Swift 单元测试
```

## 核心模块说明
1. `Sources/QxCarCoreBridge`:
   - 动态载入 `/System/Library/PrivateFrameworks/CoreUI.framework` 与 `CoreSVG.framework`。
   - 提供 `CUICatalog`、图层栈解析、SVG 写入与位图导出的 Objective-C 桥接接口。
2. `Sources/QxCarCore`:
   - `CarDiscoveryService`：智能识别拖入路径，定位 `Assets.car` 并解析元数据与图标堆栈。
   - `CarAssetExtractor`：全量导出 `Assets.car` 中所有 PNG、SVG、PDF、Colors 资源至 `./outputDir/assets/`。
   - `IconReverseEngineer`：根据 `decant` 算法校准模型，逆向还原图层、外观特化、折射率、高光、玻璃质感等并生成规范的 `.icon` 文件夹与 `icon.json`。
   - `ExportManager`：全流程异步任务调度与进度事件流分发。
3. `Sources/QxCar`:
   - SwiftUI 应用界面，采用 macOS 27 液态玻璃设计（`.liquidGlassCard()`、交互高亮反馈、状态与日志控制台）。
