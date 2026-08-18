import SwiftUI
import QxCarCore

/// 遵循 Apple HIG 规范与 macOS 27 Liquid Glass 的极简主窗口
public struct ContentView: View {
    @StateObject private var viewModel = QxCarViewModel()

    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            // 背景：系统级液态玻璃毛玻璃背景
            LiquidGlassView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()

            // 窗口透明度与无缝标题栏注入器
            LiquidGlassWindowAccessor()
                .frame(width: 0, height: 0)

            // 绝对定位在物理顶边缘的纯文本标题（高度 28pt，垂直中心位于 14pt，与红绿灯控制按钮完全一致）
            WindowTitleView("QxCar")
                .frame(height: 28)
                .zIndex(2)

            if #available(macOS 26.0, *) {
                GlassEffectContainer {
                    mainLayout
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(1)
            } else {
                mainLayout
                    .zIndex(1)
            }
        }
        .ignoresSafeArea(.all)
        .frame(width: QxCarWindowMetrics.width, height: QxCarWindowMetrics.height)
        .focusEffectDisabled()
    }

    private var mainLayout: some View {
        VStack(spacing: 12) {
            // 1. 拖入投放区 / 已选文件信息：吃掉标题栏与底栏之间的全部剩余高度
            DropZoneView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 2. 输出文件夹配置栏 (12pt 圆角)
            outputDirectoryRow

            // 3. 底部操作与状态栏 (10pt 按钮圆角)
            bottomActionBar
        }
        .padding(.horizontal, 16)
        .padding(.top, 34)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Subviews

    /// 输出文件夹设置行（macOS 27 12pt 连续平滑圆角）
    private var outputDirectoryRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder")
                .foregroundColor(.secondary)
                .font(.system(size: 13))

            Text(abbreviatedPath(viewModel.outputDirectory))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button("更改...") {
                viewModel.selectOutputFolder()
            }
            .buttonStyle(LiquidGlassButtonStyle(isPrimary: false, cornerRadius: 8))
            .controlSize(.small)
            .focusEffectDisabled()
            .focusable(false)

            Button {
                viewModel.openOutputDirInFinder()
            } label: {
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 11))
            }
            .buttonStyle(LiquidGlassButtonStyle(isPrimary: false, cornerRadius: 8))
            .controlSize(.small)
            .focusEffectDisabled()
            .focusable(false)
            .help("在访达中打开此目录")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .liquidGlassCard(cornerRadius: 12)
        .focusEffectDisabled()
    }

    /// 底部状态与操作栏
    private var bottomActionBar: some View {
        HStack(spacing: 10) {
            // 状态提示 / 进度动画
            HStack(spacing: 6) {
                if viewModel.isExporting {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在导出...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else if viewModel.lastResult != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 13))
                    Text("导出完成")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                } else if viewModel.notFoundInfo != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 13))
                    Text("未找到资源")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                } else if viewModel.targetInfo != nil {
                    Text("就绪")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 动作按钮（macOS 27 10pt 连续平滑圆角）
            if let result = viewModel.lastResult {
                Button("在访达中显示") {
                    viewModel.openOutputDirInFinder()
                }
                .buttonStyle(LiquidGlassButtonStyle(isPrimary: false, cornerRadius: 10))
                .controlSize(.regular)
                .focusEffectDisabled()
                .focusable(false)

                if result.iconPath != nil {
                    Button("打开 .icon") {
                        viewModel.openIconInIconComposer()
                    }
                    .buttonStyle(LiquidGlassButtonStyle(isPrimary: true, cornerRadius: 10))
                    .controlSize(.regular)
                    .focusEffectDisabled()
                    .focusable(false)
                }
            } else {
                Button("导出资源") {
                    viewModel.startExport()
                }
                .buttonStyle(LiquidGlassButtonStyle(isPrimary: true, cornerRadius: 12, size: .large))
                .controlSize(.large)
                .focusEffectDisabled()
                .focusable(false)
                .disabled(viewModel.targetInfo == nil || viewModel.isExporting)
            }
        }
        .focusEffectDisabled()
    }

    private func abbreviatedPath(_ path: String) -> String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

/// 窗口无缝透明与液态玻璃属性配置器
struct LiquidGlassWindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.title = "QxCar"
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.titlebarSeparatorStyle = .none
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true
                window.backgroundColor = .clear
                window.isOpaque = false
                window.hasShadow = true
                window.contentMinSize = QxCarWindowMetrics.size
                window.contentMaxSize = QxCarWindowMetrics.size
                window.setContentSize(QxCarWindowMetrics.size)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// 绝对定位纯文本窗口标题控件
public struct WindowTitleView: View {
    public var title: String

    public init(_ title: String = "QxCar") {
        self.title = title
    }

    public var body: some View {
        HStack {
            Spacer()
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary.opacity(0.85))
                .allowsHitTesting(false)
            Spacer()
        }
        .frame(height: 28)
    }
}
