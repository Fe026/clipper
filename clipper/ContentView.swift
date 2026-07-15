import SwiftUI

struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}


struct ContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var hoveredItemId: UUID? = nil
    
    // パネルを閉じるためのコールバック
    var onClose: (() -> Void)? = nil
    var onSizeChanged: ((CGSize) -> Void)? = nil
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.items
        } else {
            return clipboardManager.items.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: LayoutMetrics.mainVStackSpacing) {
            
            // 検索バーと履歴リストをZStackで重ねる (検索バーの下にリストが潜り込めるようにするため)
            ZStack(alignment: .top) {
                
                // 1. 履歴リスト (下層に配置)
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    clipboardListView
                }
                
                // 2. 検索バー (上層に配置)
                searchBarView
            }
            .padding(.bottom, LayoutMetrics.searchBarBottomPadding)
        }
        .frame(width: LayoutMetrics.windowWidth)
        // 1. まずVStack単体の自然な推奨サイズを測定する (これにより要素が少ないときにウィンドウが正しく縮みます)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ViewSizeKey.self, value: geo.size)
            }
        )
        .onPreferenceChange(ViewSizeKey.self) { size in
            let cappedHeight = min(size.height, LayoutMetrics.maxWindowHeight)
            onSizeChanged?(CGSize(width: size.width, height: cappedHeight))
        }
        // 2. その後に最大高さを制限し、コンテンツを常に「上詰め(.top)」に配置する
        .frame(maxHeight: LayoutMetrics.maxWindowHeight, alignment: .top)
        .applyGlassEffect(in: .rect(cornerRadius: 14.0))
        .clipShape(.rect(cornerRadius: 14.0))
    }
}

// MARK: - Subviews
extension ContentView {
    
    private var emptyStateView: some View {
        VStack(spacing: LayoutMetrics.emptyViewSpacing) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: LayoutMetrics.emptyIconSize))
                .foregroundColor(ColorTheme.emptyIcon)
            Text(searchText.isEmpty ? "履歴がありません" : "見つかりませんでした")
                .font(.system(size: LayoutMetrics.emptyFontSize, weight: .medium, design: .rounded))
                .foregroundColor(ColorTheme.emptyText)
        }
        .padding(.top, LayoutMetrics.searchBarAreaHeight + LayoutMetrics.emptyTopOffset)
        .padding(.bottom, LayoutMetrics.emptyBottomPadding)
        .frame(maxWidth: .infinity)
    }
    
    private var clipboardListView: some View {
        let listContentHeight = CGFloat(filteredItems.count) * LayoutMetrics.rowHeight
        let calculatedHeight = min(listContentHeight, LayoutMetrics.maxWindowHeight - (LayoutMetrics.searchBarAreaHeight + LayoutMetrics.searchBarBottomPadding))
        
        // スクロールビューが上端の上マージンに進入しないように、
        // スクロールコンテンツ自身のパディングと、スクロールビュー自体の位置を既存の定数から計算
        let scrollInsetTop = LayoutMetrics.searchBarAreaHeight - LayoutMetrics.searchBarTop
        
        return ScrollView(showsIndicators: false) {
            LazyVStack(spacing: LayoutMetrics.listSpacing) {
                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                    ClipboardRow(item: item, isHovered: hoveredItemId == item.id) {
                        clipboardManager.selectAndPaste(item)
                        onClose?()
                    }
                    .onHover { isHovered in
                        withAnimation(.easeOut(duration: 0.1)) {
                            hoveredItemId = isHovered ? item.id : nil
                        }
                    }
                    
                    if index < filteredItems.count - 1 {
                        Divider()
                            .background(ColorTheme.divider)
                            .padding(.horizontal, LayoutMetrics.dividerHorizontal)
                    }
                }
            }
            .padding(.top, scrollInsetTop + LayoutMetrics.scrollInsetTopOffset)
            .padding(.bottom, LayoutMetrics.scrollBottomPadding)
        }
        .padding(.horizontal, LayoutMetrics.windowHorizontal)
        .padding(.top, LayoutMetrics.searchBarTop) // スクロールビュー自体を検索バーの上端（上マージン）まで下げて配置
        .frame(height: calculatedHeight + scrollInsetTop) // 高さ自体を引き上げて検索バーの下まで潜り込ませる
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ColorTheme.searchBarIcon)
            
            TextField("検索", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(ColorTheme.searchBarText)
                .font(.system(size: LayoutMetrics.searchBarFontSize, weight: .medium, design: .rounded))
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                       .foregroundColor(ColorTheme.searchBarClearButton)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, LayoutMetrics.searchBarHorizontalPadding)
        .padding(.vertical, LayoutMetrics.searchBarVerticalPadding)
        .applyGlassEffect(in: .rect(cornerRadius: LayoutMetrics.searchBarCornerRadius))
        .padding(.horizontal, LayoutMetrics.windowHorizontal)
        .padding(.top, LayoutMetrics.searchBarTop)
    }
}

