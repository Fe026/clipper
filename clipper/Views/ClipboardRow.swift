import SwiftUI

struct ClipboardRow: View {
    let item: ClipboardItem
    let isHovered: Bool
    let action: () -> Void
    
    private static let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    var timeString: String {
        return Self.formatter.localizedString(for: item.timestamp, relativeTo: Date())
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
                Text(displaySingleLineText)
                    .font(.system(size: LayoutMetrics.rowTextFontSize, weight: .medium, design: .rounded))
                    .foregroundColor(ColorTheme.rowText)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if isHovered {
                    HStack(spacing: LayoutMetrics.badgeSpacing) {
                        if let sourceApp = item.sourceApp {
                            Text(sourceApp)
                                .font(.system(size: LayoutMetrics.badgeFontSize, weight: .semibold, design: .rounded))
                                .foregroundColor(ColorTheme.badgeSourceApp)
                        }
                        
                        Text(timeString)
                            .font(.system(size: LayoutMetrics.badgeFontSize, design: .rounded))
                            .foregroundColor(ColorTheme.badgeTime)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, LayoutMetrics.itemInternalHorizontal)
            .padding(.vertical, LayoutMetrics.itemVertical)
            .contentShape(Rectangle()) // テキスト以外の透明な余白領域も含め、行全体を当たり判定にする
            .background(
                RoundedRectangle(cornerRadius: LayoutMetrics.rowCornerRadius) // 角丸を少し小さくしてコンパクト化に合わせる
                    .fill(isHovered ? ColorTheme.rowHoverBg : Color.clear)
            )
            .padding(.horizontal, LayoutMetrics.itemExternalHorizontal)
        }
        .buttonStyle(.plain)
    }
}
