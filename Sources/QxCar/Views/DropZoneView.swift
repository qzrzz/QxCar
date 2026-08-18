import SwiftUI
import UniformTypeIdentifiers
import QxCarCore

/// 遵循 Apple HIG 与 macOS 27 Liquid Glass 的拖放投放与目标文件卡片
/// 最小高度 96pt，在窗口内吃掉剩余垂直空间；各状态共用同一高度，避免切换抖动
public struct DropZoneView: View {
    @ObservedObject var viewModel: QxCarViewModel

    public static let minHeight: CGFloat = 96

    public init(viewModel: QxCarViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if let info = viewModel.targetInfo {
                // 1. 已成功识别到 Assets.car 的有效文件卡片
                HStack(spacing: 14) {
                    // 真实 App 图标或 Assets.car 文件图标
                    Image(nsImage: NSWorkspace.shared.icon(forFile: info.sourcePath))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(info.displayName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            Button {
                                viewModel.reset()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .focusEffectDisabled()
                            .focusable(false)
                            .help("移除并重新选择")
                        }

                        HStack(spacing: 6) {
                            Text(info.fileSizeString)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            if !info.iconStacks.isEmpty {
                                Text("•")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary.opacity(0.5))

                                if info.iconStacks.count > 1 {
                                    Picker("", selection: $viewModel.selectedIconStack) {
                                        ForEach(info.iconStacks, id: \.self) { stack in
                                            Text(stack).tag(stack)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    .controlSize(.mini)
                                    .focusEffectDisabled()
                                    .focusable(false)
                                } else if let stack = info.iconStacks.first {
                                    Text(stack)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .liquidGlassCard(cornerRadius: 16, isHighlighted: false)
            } else if let notFound = viewModel.notFoundInfo {
                // 2. 拖入 App / 文件夹但未找到 Assets.car 的提示卡片
                HStack(spacing: 14) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: notFound.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .opacity(0.85)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(notFound.displayName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            Button {
                                viewModel.reset()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .focusEffectDisabled()
                            .focusable(false)
                            .help("清除提示")
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)

                            Text(notFound.reason)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .liquidGlassCard(cornerRadius: 16, isHighlighted: true)
            } else {
                // 3. 空白拖放区（点击选取或拖入）
                Button {
                    selectLocalFile()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: viewModel.isDragOver ? "arrow.down.circle.fill" : "arrow.down.doc")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(viewModel.isDragOver ? .accentColor : .secondary)

                        VStack(spacing: 3) {
                            Text("拖入 Assets.car 或 .app 文件夹")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)

                            Text("或点击选取文件")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .modifier(EmptyDropZoneBackgroundModifier(isDragOver: viewModel.isDragOver))
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                .focusable(false)
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: $viewModel.isDragOver) { providers in
                    handleDrop(providers: providers)
                }
            }
        }
        .frame(minHeight: DropZoneView.minHeight, maxHeight: .infinity)
        .focusEffectDisabled()
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                DispatchQueue.main.async {
                    self.viewModel.handleDroppedPaths([url.path])
                }
            }
        }
        return true
    }

    private func selectLocalFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "car") ?? .data,
            UTType.applicationBundle,
            UTType.folder
        ]
        panel.prompt = "选取"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.handleDroppedPaths([url.path])
        }
    }
}

/// 适配 macOS 27 的空白投放区纯玻璃折射效果（无背景色填充）
private struct EmptyDropZoneBackgroundModifier: ViewModifier {
    var isDragOver: Bool

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(
                    isDragOver ? .regular.tint(Color.accentColor.opacity(0.15)).interactive() : .clear.interactive(),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            isDragOver ? Color.accentColor : Color.white.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1.0, dash: [5, 4])
                        )
                )
        } else {
            content
                .background(
                    LiquidGlassView(
                        material: isDragOver ? .selection : .popover,
                        blendingMode: .withinWindow
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            isDragOver ? Color.accentColor : Color.white.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1.0, dash: [5, 4])
                        )
                )
        }
    }
}
