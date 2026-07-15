import SwiftUI

// UI レイアウト定数 (パディングとマージンの一元管理)
struct LayoutMetrics {
    // ウィンドウ全体・配置
    static let windowWidth: CGFloat = 280         // ウィンドウ幅
    static let maxWindowHeight: CGFloat = 480     // ウィンドウ最大高さ
    static let windowHorizontal: CGFloat = 8      // ウィンドウ左右の基本マージン (検索バー、ScrollViewの左右配置)
    static let mainVStackSpacing: CGFloat = 12    // メインVStackのスペース
    
    // 検索バー
    static let searchBarTop: CGFloat = 8          // 検索バーの上方向余白
    static let searchBarAreaHeight: CGFloat = 44  // 検索バー＋上マージンの合計高さ (ScrollView上部の潜り込み余白)
    static let searchBarHorizontalPadding: CGFloat = 12 // 検索バー内の左右余白
    static let searchBarVerticalPadding: CGFloat = 8   // 検索バー内の上下余白
    static let searchBarCornerRadius: CGFloat = 8      // 検索バーの角丸半径
    static let searchBarFontSize: CGFloat = 13         // 検索テキストのフォントサイズ
    static let searchBarBottomPadding: CGFloat = 8     // 検索エリア下部パディング
    
    // リスト
    static let rowHeight: CGFloat = 30            // 各行アイテムの基本高さ
    static let listSpacing: CGFloat = 2           // リストアイテム間のスペース
    static let scrollInsetTopOffset: CGFloat = 4  // スクロール上部追加インセット
    static let scrollBottomPadding: CGFloat = 4   // スクロール下部追加パディング
    
    // リストアイテム（行全体）の配置
    static let itemExternalHorizontal: CGFloat = 0 // 行アイテムの左右外側パディング (検索バーの端とハイライト端を揃えるため0)
    static let rowSpacing: CGFloat = 8            // 行内テキストとホバーバッジの間のスペース
    static let rowCornerRadius: CGFloat = 6       // 行の角丸半径
    
    // リストアイテム内部のフォントとパディング
    static let itemInternalHorizontal: CGFloat = 8 // テキストの横余白
    static let itemVertical: CGFloat = 4           // 表示密度を上げるための行の縦余白
    static let rowTextFontSize: CGFloat = 12       // コピーテキストのフォントサイズ
    static let badgeSpacing: CGFloat = 6           // バッジ間のスペース
    static let badgeFontSize: CGFloat = 9          // アプリ名・時間表示のフォントサイズ
    
    // 仕切り線（Divider）のパディング
    static let dividerHorizontal: CGFloat = 0      // テキスト開始位置と揃える余白
    
    // 空表示 (Empty View)
    static let emptyViewSpacing: CGFloat = 8       // 空表示要素のスペース
    static let emptyIconSize: CGFloat = 24         // 空表示のアイコンサイズ
    static let emptyFontSize: CGFloat = 12         // 空表示のテキストフォントサイズ
    static let emptyTopOffset: CGFloat = 20        // 空表示の上部オフセット
    static let emptyBottomPadding: CGFloat = 20    // 空表示の下部パディング
    
    // フッターの配置 (将来用)
    static let footerHorizontal: CGFloat = 8       // フッターの左右余白 (検索バー/リストと揃えるため8)
    static let footerBottom: CGFloat = 8           // フッターの下マージン
}

// SwiftUIの色定数 (色・グラデーションの一元管理)
struct ColorTheme {
    // 基本テキスト・アイコン
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color.primary.opacity(0.4)
    
    // 空表示 (Empty View)
    static let emptyIcon = Color.secondary.opacity(0.3)
    static let emptyText = Color.secondary
    
    // 区切り線
    static let divider = Color.primary.opacity(0.06)
    
    // 検索バー
    static let searchBarText = Color.primary
    static let searchBarIcon = Color.secondary
    static let searchBarClearButton = Color.secondary
    
    // リストアイテム
    static let rowText = Color.primary
    static let rowHoverBg = Color.primary.opacity(0.08)
    static let badgeSourceApp = Color.blue.opacity(0.8)
    static let badgeTime = Color.secondary
}

extension View {
    @ViewBuilder
    func applyGlassEffect(in shape: some Shape) -> some View {
        #if compiler(>=6.3)
        self.glassEffect(in: shape)
        #else
        self.background(.ultraThinMaterial, in: shape)
        #endif
    }
}

