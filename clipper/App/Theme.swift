import AppKit
import SwiftUI

// UI レイアウト定数 (パディングとマージンの一元管理)
enum LayoutMetrics {
    // ウィンドウ全体・配置
    static let windowWidth: CGFloat = 300         // ウィンドウ幅
    static let minWindowHeight: CGFloat = 120     // ウィンドウ最小高さ
    static let maxWindowHeight: CGFloat = 480     // ウィンドウ最大高さ
    static let panelCornerRadius: CGFloat = 20    // パネルの連続角丸半径 (macOS 27)
    static let windowHorizontal: CGFloat = 10     // ウィンドウ左右の基本マージン (検索バー、ScrollViewの左右配置)

    // 設定ウィンドウ
    static let settingsWindowWidth: CGFloat = 600      // 設定ウィンドウのデフォルト・最小幅
    static let settingsWindowHeight: CGFloat = 420     // 設定ウィンドウのデフォルト・最小高さ
    static let settingsSidebarMinWidth: CGFloat = 168  // サイドバー最小幅
    static let settingsSidebarIdealWidth: CGFloat = 184 // サイドバー標準幅
    static let settingsSidebarMaxWidth: CGFloat = 210  // サイドバー最大幅

    // 検索バー
    static let searchBarTop: CGFloat = 10               // 検索バーの上方向余白
    static let searchBarBottomPadding: CGFloat = 8      // 検索エリア下部パディング
    static let searchBarHorizontalPadding: CGFloat = 12 // 検索バー内の左右余白
    static let searchBarVerticalPadding: CGFloat = 7    // 検索バー内の上下余白
    static let searchBarFontSize: CGFloat = 13          // 検索テキストのフォントサイズ
    static let searchBarOverlapMaxBlurRadius: CGFloat = 18 // 検索バー裏へ回り込んだ行の最大ぼかし半径
    static let searchBarOverlapMinOpacity: Double = 0.35   // 検索バー裏へ回り込んだ行の最小不透明度

    // リスト
    static let listSpacing: CGFloat = 2           // リストアイテム間のスペース
    static let listTopPadding: CGFloat = 2        // スクロール上部追加パディング
    static let scrollBottomPadding: CGFloat = 10  // スクロール下部追加パディング

    // リストアイテム（行全体）の配置
    static let rowSpacing: CGFloat = 8            // 行内テキストとホバーバッジの間のスペース
    static let rowCornerRadius: CGFloat = 10      // 行の同心角丸最小半径 (20 - 10 = 10)

    // リストアイテム内部のフォントとパディング
    static let itemInternalHorizontal: CGFloat = 10 // テキストの横余白
    static let itemVertical: CGFloat = 6            // 行の縦余白
    static let rowTextFontSize: CGFloat = 13        // コピーテキストのフォントサイズ
    static let badgeSpacing: CGFloat = 6            // バッジ間のスペース
    static let badgeFontSize: CGFloat = 10          // アプリ名・時間表示のフォントサイズ
    static let badgeIconSize: CGFloat = 14          // アプリアイコンのサイズ
    static let pinIconSize: CGFloat = 10            // ピン留めアイコンのサイズ
    static let colorChipSize: CGFloat = 12          // カラーコードプレビューチップのサイズ
    static let colorChipCornerRadius: CGFloat = 4   // カラーチップの角丸半径
    static let contextMenuFontSize: CGFloat = 11    // コンテキストメニューのフォントサイズ

    // 空表示 (Empty View)
    static let emptyViewSpacing: CGFloat = 8      // 空表示要素のスペース
    static let emptyIconSize: CGFloat = 26        // 空表示のアイコンサイズ
    static let emptyFontSize: CGFloat = 13        // 空表示のテキストフォントサイズ
    static let emptyVerticalPadding: CGFloat = 32 // 空表示の上下パディング
}

// SwiftUIの色定数 (色・適応カラーの一元管理)
enum ColorTheme {
    // 基本テキスト・アイコン
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary

    // 空表示 (Empty View)
    static let emptyIcon = Color.secondary.opacity(0.4)
    static let emptyText = Color.secondary

    // 検索バー (カプセル型埋め込みフィールド)
    static let searchBarText = Color.primary
    static let searchBarIcon = Color.secondary
    static let searchBarClearButton = Color.secondary
    static let searchBarFill = adaptiveColor(
        light: NSColor.black.withAlphaComponent(0.05),
        dark: NSColor.white.withAlphaComponent(0.10)
    )
    static let searchBarBorder = adaptiveColor(
        light: NSColor.black.withAlphaComponent(0.08),
        dark: NSColor.white.withAlphaComponent(0.12)
    )
    static let searchBarFocusedBorder = Color.accentColor.opacity(0.55)

    // リストアイテム
    static let rowText = Color.primary
    static let rowHoverBg = adaptiveColor(
        light: NSColor.black.withAlphaComponent(0.07),
        dark: NSColor.white.withAlphaComponent(0.11)
    )
    static let rowHoverBorder = adaptiveColor(
        light: NSColor.black.withAlphaComponent(0.05),
        dark: NSColor.white.withAlphaComponent(0.08)
    )
    static let badgeSourceApp = Color.secondary
    static let badgeTime = Color.secondary

    private static func adaptiveColor(light: NSColor, dark: NSColor) -> Color {
        Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}
