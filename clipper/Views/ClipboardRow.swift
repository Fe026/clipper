import SwiftUI

struct ClipboardRow: View {
    let item: ClipboardItem
    let isHovered: Bool
    let isSelected: Bool // キーボード選択中
    let action: () -> Void
    let onPinToggle: (() -> Void)?
    let onDelete: (() -> Void)?
    let onPasteAsPlainText: (() -> Void)?

    private var isHighlighted: Bool { isHovered || isSelected }

    private var rowShape: ConcentricRectangle {
        ConcentricRectangle(
            corners: .concentric(minimum: .fixed(LayoutMetrics.rowCornerRadius)),
            isUniform: true
        )
    }

    private static let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var timeString: String {
        Self.formatter.localizedString(for: item.timestamp, relativeTo: Date())
    }

    var displaySingleLineText: String {
        // 改行をスペースに置換し、前後の不要な空白を取り除く
        item.text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutMetrics.rowSpacing) {
                // カラーコード判定時のカラーチップ表示
                if let parsedColor = ColorParser.parse(from: item.text) {
                    colorChipView(color: parsedColor)
                }

                Text(displaySingleLineText)
                    .font(.system(size: LayoutMetrics.rowTextFontSize, weight: .regular))
                    .foregroundStyle(ColorTheme.rowText)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // ピン留めマーク（ホバー中・キーボード選択中でなく、ピン留めされている場合のみ表示）
                if !isHighlighted && item.isPinned {
                    pinIndicator
                }

                if isHovered {
                    hoverBadgesView
                }
            }
            .padding(.horizontal, LayoutMetrics.itemInternalHorizontal)
            .padding(.vertical, LayoutMetrics.itemVertical)
            .contentShape(rowShape) // テキスト以外の透明な余白領域も含め、行全体を当たり判定にする
            .background {
                if isHighlighted {
                    rowShape
                        .fill(ColorTheme.rowHoverBg)
                        .overlay {
                            rowShape
                                .stroke(ColorTheme.rowHoverBorder, lineWidth: 1)
                                .clipShape(rowShape)
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu { contextMenuContent }
    }

    // MARK: - サブビュー

    private func colorChipView(color: Color) -> some View {
        RoundedRectangle(cornerRadius: LayoutMetrics.colorChipCornerRadius, style: .continuous)
            .fill(color)
            .frame(width: LayoutMetrics.colorChipSize, height: LayoutMetrics.colorChipSize)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutMetrics.colorChipCornerRadius, style: .continuous)
                    .strokeBorder(.primary.opacity(0.2), lineWidth: 0.5)
            )
    }

    private var pinIndicator: some View {
        Image(systemName: "pin.fill")
            .font(.system(size: LayoutMetrics.pinIconSize))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.orange)
            .padding(.trailing, 1)
    }

    private var hoverBadgesView: some View {
        HStack(spacing: LayoutMetrics.badgeSpacing) {
            if let sourceApp = item.sourceApp {
                HStack(spacing: 4) {
                    if let icon = AppInfoResolver.icon(for: item.sourceAppBundleID) {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: LayoutMetrics.badgeIconSize, height: LayoutMetrics.badgeIconSize)
                            .clipShape(.rect(cornerRadius: 3.5, style: .continuous))
                    }
                    Text(sourceApp)
                        .font(.system(size: LayoutMetrics.badgeFontSize, weight: .medium))
                        .foregroundStyle(ColorTheme.badgeSourceApp)
                        .lineLimit(1)
                }
            }

            Text(timeString)
                .font(.system(size: LayoutMetrics.badgeFontSize, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(ColorTheme.badgeTime)

            // ピン留めトグルボタン（内側の Button がタップを消費するため、行全体のペースト動作には波及しない）
            Button(action: { onPinToggle?() }) {
                Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                    .font(.system(size: LayoutMetrics.pinIconSize))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(item.isPinned ? AnyShapeStyle(.secondary) : AnyShapeStyle(.orange))
            }
            .buttonStyle(.plain)
            .help(item.isPinned ? "ピン留め解除" : "ピン留めする")
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Section {
            Text(item.text)
                .lineLimit(5)
                .font(.system(size: LayoutMetrics.contextMenuFontSize, design: .monospaced))
        } header: {
            Text("プレビュー")
        }

        Divider()

        Button(action: action) {
            Label("ペースト", systemImage: "doc.on.clipboard")
        }

        Button(action: { onPasteAsPlainText?() }) {
            Label("プレーンテキストとしてペースト", systemImage: "doc.plaintext")
        }

        Divider()

        Button(action: { onPinToggle?() }) {
            if item.isPinned {
                Label("ピン留め解除", systemImage: "pin.slash")
            } else {
                Label("ピン留めする", systemImage: "pin")
            }
        }

        Button(role: .destructive, action: { onDelete?() }) {
            Label("履歴から削除", systemImage: "trash")
        }
    }
}
