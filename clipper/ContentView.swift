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
    
    // 検索語によるフィルタリング後のアイテム一覧（最大50件に制限）
    private var filteredItems: [ClipboardItem] {
        let items: [ClipboardItem]
        if searchText.isEmpty {
            items = clipboardManager.items
        } else {
            items = clipboardManager.items.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
        return Array(items.prefix(50))
    }
    
    // 検索バーの下層にリストを潜り込ませるための、スクロールビュー上部余白の計算
    private var listScrollInsetTop: CGFloat {
        LayoutMetrics.searchBarAreaHeight - LayoutMetrics.searchBarTop
    }
    
    // 画面の最大表示可能範囲に収めたリストの高さ（ScrollView表示時の上限）
    private var listVisibleHeight: CGFloat {
        LayoutMetrics.maxWindowHeight - LayoutMetrics.searchBarTop
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 検索バーと履歴リストをZStackで重ねる (検索バーの下にリストが潜り込めるようにするため)
            ZStack(alignment: .top) {
                // 1. 履歴リスト / 空白表示 (下層に配置)
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    clipboardListView
                }
                
                // 2. 検索バー (上層に配置)
                searchBarView
            }
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
        .applyGlassEffect(in: .rect(cornerRadius: 14.0), displayMode: .thick)
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
        Group {
            if filteredItems.count <= 10 {
                // 10件以下の場合は、ScrollView を排除してスクロールやスクロールバーを物理的に排除する
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: listScrollInsetTop + LayoutMetrics.scrollInsetTopOffset)
                    
                    VStack(spacing: LayoutMetrics.listSpacing) {
                        listViewContent
                    }
                }
                .padding(.bottom, LayoutMetrics.scrollBottomPadding)
            } else {
                // 10件を超える場合は、最大高さ制限付きの ScrollView で描画する
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Color.clear
                                .frame(height: 0)
                                .id("top")
                            
                            Spacer()
                                .frame(height: listScrollInsetTop + LayoutMetrics.scrollInsetTopOffset)
                            
                            VStack(spacing: LayoutMetrics.listSpacing) {
                                listViewContent
                            }
                        }
                        .padding(.bottom, LayoutMetrics.scrollBottomPadding)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ClipperPanelDidShow"))) { _ in
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
                .frame(height: listVisibleHeight)
            }
        }
        .padding(.horizontal, LayoutMetrics.windowHorizontal)
        .padding(.top, LayoutMetrics.searchBarTop) // スクロールビュー自体を検索バーの上端（上マージン）まで下げて配置
    }
    
    @ViewBuilder
    private var listViewContent: some View {
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
        .applyGlassEffect(in: .rect(cornerRadius: LayoutMetrics.searchBarCornerRadius), displayMode: .thin)
        .padding(.horizontal, LayoutMetrics.windowHorizontal)
        .padding(.top, LayoutMetrics.searchBarTop)
    }
}

