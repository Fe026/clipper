import SwiftUI

private let panelCoordinateSpace = "clipperPanelRoot"

struct ContentView<Manager: ClipboardManaging & ObservableObject>: View {
    @ObservedObject var clipboardManager: Manager
    @State private var searchText = ""
    @State private var hoveredItemId: UUID? = nil

    // キーボード選択用のインデックス
    @State private var keyboardSelectedIndex: Int? = nil
    @State private var isUsingKeyboard = false
    @State private var keyboardLockTask: Task<Void, Never>? = nil

    // 検索バーのフォーカスとウィンドウ高さ計算用状態
    @FocusState private var isSearchFocused: Bool
    @State private var contentHeight: CGFloat = 0
    @State private var searchBarHeight: CGFloat = 0
    @Environment(\.appearsActive) private var appearsActive

    // パネルを閉じるためのコールバック
    var onClose: (() -> Void)? = nil
    var onSizeChanged: ((CGSize) -> Void)? = nil

    // 検索語によるフィルタリング後のアイテム一覧（最大50件に制限、かつピン留め優先）
    private var filteredItems: [ClipboardItem] {
        let items: [ClipboardItem]
        if searchText.isEmpty {
            items = clipboardManager.items
        } else {
            items = clipboardManager.items.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }

        // ピン留めされたものを常に最上位にソートする
        let pinned = items.filter { $0.isPinned }
        let unpinned = items.filter { !$0.isPinned }
        let sorted = pinned + unpinned

        return Array(sorted.prefix(AppConstants.Clipboard.maxFilteredItems))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .id("top")

                    if filteredItems.isEmpty {
                        emptyStateView
                    } else {
                        VStack(spacing: LayoutMetrics.listSpacing) {
                            listViewContent
                        }
                        .padding(.horizontal, LayoutMetrics.windowHorizontal)
                        .padding(.top, LayoutMetrics.listTopPadding)
                        .padding(.bottom, LayoutMetrics.scrollBottomPadding)
                    }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { newHeight in
                    guard abs(contentHeight - newHeight) > 0.5 else { return }
                    contentHeight = newHeight
                    notifySizeChange()
                }
            }
            .scrollIndicators(.never)
            .scrollBounceBehavior(.basedOnSize)
            .scrollContentBackground(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .safeAreaBar(edge: .top, spacing: 0) {
                searchBarView
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { newHeight in
                        guard abs(searchBarHeight - newHeight) > 0.5 else { return }
                        searchBarHeight = newHeight
                        notifySizeChange()
                    }
            }
            .onReceive(NotificationCenter.default.publisher(for: .clipperPanelDidShow)) { _ in
                proxy.scrollTo("top", anchor: .top)
                keyboardSelectedIndex = nil
                isSearchFocused = true
            }
            .onChange(of: keyboardSelectedIndex) { oldValue, newValue in
                guard let index = newValue else { return }
                if let old = oldValue {
                    if index > old {
                        // 下方向への移動：選択項目の「2つ先」が表示領域に入るように最小限スクロール
                        let target = min(index + 2, filteredItems.count - 1)
                        proxy.scrollTo(target, anchor: nil)
                    } else if index < old {
                        // 上方向への移動：先頭付近なら最上部("top")へ、それ以外は「2つ手前」が表示領域に入るように最小限スクロール
                        if index <= 2 {
                            proxy.scrollTo("top", anchor: nil)
                        } else {
                            let target = max(index - 2, 0)
                            proxy.scrollTo(target, anchor: nil)
                        }
                    }
                } else {
                    if index <= 2 {
                        proxy.scrollTo("top", anchor: nil)
                    } else {
                        proxy.scrollTo(index, anchor: nil)
                    }
                }
            }
        }
        .opacity(appearsActive ? 1.0 : 0.85)
        .frame(width: LayoutMetrics.windowWidth)
        .frame(maxHeight: LayoutMetrics.maxWindowHeight, alignment: .top)
        .coordinateSpace(name: panelCoordinateSpace)
        .containerShape(.rect(cornerRadius: LayoutMetrics.panelCornerRadius, style: .continuous))
    }

    private func notifySizeChange() {
        guard searchBarHeight > 0, contentHeight > 0 else { return }
        let totalHeight = searchBarHeight + contentHeight
        let clampedHeight = min(max(totalHeight, LayoutMetrics.minWindowHeight), LayoutMetrics.maxWindowHeight)
        onSizeChanged?(CGSize(width: LayoutMetrics.windowWidth, height: clampedHeight))
    }
}

// MARK: - Subviews
extension ContentView {

    private var emptyStateView: some View {
        VStack(spacing: LayoutMetrics.emptyViewSpacing) {
            Image(systemName: searchText.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                .font(.system(size: LayoutMetrics.emptyIconSize))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(ColorTheme.emptyIcon)
            Text(searchText.isEmpty ? "履歴がありません" : "見つかりませんでした")
                .font(.system(size: LayoutMetrics.emptyFontSize, weight: .medium))
                .foregroundStyle(ColorTheme.emptyText)
        }
        .padding(.vertical, LayoutMetrics.emptyVerticalPadding)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var listViewContent: some View {
        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
            ClipboardRow(
                item: item,
                isHovered: hoveredItemId == item.id,
                isSelected: keyboardSelectedIndex == index,
                action: {
                    clipboardManager.selectAndPaste(item)
                    onClose?()
                },
                onPinToggle: {
                    clipboardManager.togglePin(item)
                },
                onDelete: {
                    clipboardManager.deleteItem(item)
                    // 削除後にインデックスがズレるのを防ぐため、選択をリセットまたは調整
                    if keyboardSelectedIndex == index {
                        keyboardSelectedIndex = nil
                    } else if let current = keyboardSelectedIndex, current > index {
                        keyboardSelectedIndex = current - 1
                    }
                },
                onPasteAsPlainText: {
                    pasteAsPlainText(item)
                }
            )
            .id(index) // ScrollViewReader でスクロールターゲットにするためのID
            .onHover { isHovered in
                guard !isUsingKeyboard else { return }
                withAnimation(.easeOut(duration: 0.1)) {
                    hoveredItemId = isHovered ? item.id : nil
                    if isHovered {
                        keyboardSelectedIndex = index
                    }
                }
            }
            .topEdgeProgressiveBlur(threshold: searchBarHeight, coordinateSpace: panelCoordinateSpace)

            // ピン留めセクションと通常履歴の境界にのみ控えめな区切り線を配置
            if item.isPinned && index < filteredItems.count - 1 && !filteredItems[index + 1].isPinned {
                Divider()
                    .opacity(0.5)
                    .padding(.horizontal, LayoutMetrics.itemInternalHorizontal)
                    .padding(.vertical, 3)
                    .topEdgeProgressiveBlur(threshold: searchBarHeight, coordinateSpace: panelCoordinateSpace)
            }
        }
    }

    private var searchBarView: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ColorTheme.searchBarIcon)

            TextField("検索", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .foregroundStyle(ColorTheme.searchBarText)
                .font(.system(size: LayoutMetrics.searchBarFontSize, weight: .regular))
                .onChange(of: searchText) { oldValue, newValue in
                    keyboardSelectedIndex = nil
                }
                .onKeyPress(.downArrow) {
                    moveSelection(down: true)
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    moveSelection(down: false)
                    return .handled
                }
                .onKeyPress(.return) {
                    pasteSelected()
                    return .handled
                }

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(ColorTheme.searchBarClearButton)
                }
                .buttonStyle(.plain)
                .help("検索をクリア")
            }
        }
        .padding(.horizontal, LayoutMetrics.searchBarHorizontalPadding)
        .padding(.vertical, LayoutMetrics.searchBarVerticalPadding)
        .background {
            Capsule()
                .fill(.thinMaterial)
                .overlay {
                    Capsule()
                        .fill(ColorTheme.searchBarFill)
                }
        }
        .overlay {
            Capsule()
                .strokeBorder(
                    isSearchFocused ? ColorTheme.searchBarFocusedBorder : ColorTheme.searchBarBorder,
                    lineWidth: isSearchFocused ? 1.0 : 0.5
                )
        }
        .padding(.horizontal, LayoutMetrics.windowHorizontal)
        .padding(.top, LayoutMetrics.searchBarTop)
        .padding(.bottom, LayoutMetrics.searchBarBottomPadding)
    }

    // キーボードによる選択位置の移動
    private func moveSelection(down: Bool) {
        isUsingKeyboard = true
        keyboardLockTask?.cancel()
        keyboardLockTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300msロック
            guard !Task.isCancelled else { return }
            isUsingKeyboard = false
        }

        let count = filteredItems.count
        guard count > 0 else { return }

        if let current = keyboardSelectedIndex {
            if down {
                keyboardSelectedIndex = min(current + 1, count - 1)
            } else {
                keyboardSelectedIndex = max(current - 1, 0)
            }
        } else {
            keyboardSelectedIndex = down ? 0 : count - 1
        }
    }

    // 現在キーボードで選択しているアイテムをペースト
    private func pasteSelected() {
        guard let index = keyboardSelectedIndex, index < filteredItems.count else { return }
        let item = filteredItems[index]
        clipboardManager.selectAndPaste(item)
        onClose?()
    }

    // プレーンテキストとしてペースト
    private func pasteAsPlainText(_ item: ClipboardItem) {
        clipboardManager.selectAndPaste(item.asPlainText())
        onClose?()
    }
}

private extension View {
    func topEdgeProgressiveBlur(threshold: CGFloat, coordinateSpace: String) -> some View {
        let maxBlurRadius = LayoutMetrics.searchBarOverlapMaxBlurRadius
        let minOpacity = LayoutMetrics.searchBarOverlapMinOpacity
        return self.visualEffect { content, proxy in
            let eased: Double
            if threshold > 0 {
                let minY = proxy.frame(in: .named(coordinateSpace)).minY
                let overlap = max(0, threshold - minY)
                let blurRange = max(threshold * 0.75, 34)
                let t = min(overlap / blurRange, 1)
                eased = Double(t * t * (3 - 2 * t))
            } else {
                eased = 0
            }
            return content
                .blur(radius: CGFloat(eased) * maxBlurRadius)
                .opacity(1 - eased * (1 - minOpacity))
        }
    }
}
