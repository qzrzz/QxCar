import SwiftUI
import AppKit

/// macOS 27 纯玻璃材质背景视图（无任何实心背景色）
public struct LiquidGlassView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .underWindowBackground,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

/// 纯玻璃材质卡片 Modifier（无任何背景颜色填充，完全依赖系统液态玻璃折射与光效）
public struct LiquidGlassCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var isHighlighted: Bool

    public init(cornerRadius: CGFloat = 16, isHighlighted: Bool = false) {
        self.cornerRadius = cornerRadius
        self.isHighlighted = isHighlighted
    }

    public func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(
                    isHighlighted ? .regular.tint(Color.accentColor.opacity(0.15)) : .regular,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            isHighlighted ? Color.accentColor.opacity(0.5) : Color.white.opacity(0.15),
                            lineWidth: isHighlighted ? 1.2 : 0.6
                        )
                )
                .focusEffectDisabled()
        } else {
            content
                .background(
                    LiquidGlassView(material: .popover, blendingMode: .withinWindow)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            isHighlighted ? Color.accentColor.opacity(0.5) : Color.white.opacity(0.15),
                            lineWidth: isHighlighted ? 1.2 : 0.6
                        )
                )
                .focusEffectDisabled()
        }
    }
}

/// 纯玻璃材质按钮样式（无背景色，仅使用 Liquid Glass 原生折射材质）
public struct LiquidGlassButtonStyle: ButtonStyle {
    public var isPrimary: Bool
    public var cornerRadius: CGFloat
    public var size: Size

    public enum Size {
        case regular
        case large

        var fontSize: CGFloat {
            switch self {
            case .regular: return 12
            case .large: return 14
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .regular: return 14
            case .large: return 22
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .regular: return 6
            case .large: return 9
            }
        }
    }

    public init(isPrimary: Bool = false, cornerRadius: CGFloat = 10, size: Size = .regular) {
        self.isPrimary = isPrimary
        self.cornerRadius = cornerRadius
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        if #available(macOS 26.0, *) {
            configuration.label
                .font(.system(size: size.fontSize, weight: isPrimary ? .semibold : .regular))
                .foregroundColor(isPrimary ? .white : .primary)
                .padding(.horizontal, size.horizontalPadding)
                .padding(.vertical, size.verticalPadding)
                .glassEffect(
                    isPrimary
                        ? .regular.tint(Color.accentColor).interactive()
                        : .regular.interactive(),
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            isPrimary ? Color.white.opacity(0.2) : Color.white.opacity(0.1),
                            lineWidth: 0.6
                        )
                )
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
                .focusEffectDisabled()
                .focusable(false)
        } else {
            configuration.label
                .font(.system(size: size.fontSize, weight: isPrimary ? .semibold : .regular))
                .foregroundColor(isPrimary ? .white : .primary)
                .padding(.horizontal, size.horizontalPadding)
                .padding(.vertical, size.verticalPadding)
                .background(
                    LiquidGlassView(
                        material: isPrimary ? .selection : .headerView,
                        blendingMode: .withinWindow
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            Color.white.opacity(isPrimary ? 0.2 : 0.1),
                            lineWidth: 0.6
                        )
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
                .focusEffectDisabled()
                .focusable(false)
        }
    }
}

public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 16, isHighlighted: Bool = false) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, isHighlighted: isHighlighted))
    }
}
