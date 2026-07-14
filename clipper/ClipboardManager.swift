import Foundation
import AppKit
import Combine

@MainActor
class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int
    private var monitorTask: Task<Void, Never>?
    private var isMonitoring = true
    
    @Published var maxItems: Int
    private let maxItemsKey = "max_items"
    private let userDefaultsKey = "clipboard_history"
    private let vKeyCode: CGKeyCode = 0x09 // 'v' key code
    
    init() {
        let savedMax = UserDefaults.standard.integer(forKey: "max_items")
        self.maxItems = savedMax == 0 ? 1000 : savedMax
        self.changeCount = pasteboard.changeCount
        loadItems()
        startMonitoring()
    }
    
    func startMonitoring() {
        monitorTask?.cancel()
        
        monitorTask = Task(priority: .utility) { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                } catch {
                    break
                }
                
                guard let self = self else { break }
                
                let currentChangeCount = self.pasteboard.changeCount
                
                // メインアクター側から状態を取得して条件に合う場合のみ、メインアクター上で処理を走らせる
                let shouldCheck = await MainActor.run {
                    return currentChangeCount != self.changeCount && self.isMonitoring
                }
                
                if shouldCheck {
                    await MainActor.run {
                        self.checkPasteboard()
                    }
                }
            }
        }
    }
    
    private func checkPasteboard() {
        guard pasteboard.changeCount != changeCount else { return }
        changeCount = pasteboard.changeCount
        
        // テキスト情報を取得
        if let text = pasteboard.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // 直前のアイテムと同じなら取得しない（重複防止）
            if let firstItem = items.first, firstItem.text == text {
                return
            }
            
            // RTF形式およびHTML形式の書式情報データを取得 (リッチテキスト保存用)
            let rtfData = pasteboard.data(forType: .rtf)
            let htmlData = pasteboard.data(forType: .html)
            
            print("[Clipper Debug] Copied Text: \(text.prefix(30))...")
            print("[Clipper Debug] RTF Data size: \(rtfData?.count ?? 0) bytes")
            print("[Clipper Debug] HTML Data size: \(htmlData?.count ?? 0) bytes")
            
            // コピー元のアプリ名を取得（可能な場合）
            var sourceAppName: String? = nil
            if let activeApp = NSWorkspace.shared.frontmostApplication {
                sourceAppName = activeApp.localizedName
            }
            
            let newItem = ClipboardItem(text: text, type: .text, rawData: rtfData, htmlData: htmlData, sourceApp: sourceAppName)
            addItem(newItem)
        }
    }
    
    private func addItem(_ item: ClipboardItem) {
        // すでに同じ内容がある場合は古いものを削除して、最新として先頭に持ってくる
        self.items.removeAll { $0.text == item.text }
        self.items.insert(item, at: 0)
        
        // 上限数を超えたら削除
        if self.items.count > self.maxItems {
            self.items = Array(self.items.prefix(self.maxItems))
        }
        
        self.saveItems()
    }
    
    // クリップボードを上書きし、自動で貼り付ける
    func selectAndPaste(_ item: ClipboardItem) {
        // 一時的に監視を停止して、自分自身が上書きしたものをコピーとして検知しないようにする
        isMonitoring = false
        
        pasteboard.clearContents()
        
        // NSPasteboardItem を使用して、複数形式のデータをアトミックかつ優先度付きで書き込む（推奨API）
        let pbItem = NSPasteboardItem()
        
        if let rtfData = item.rawData {
            pbItem.setData(rtfData, forType: .rtf)
        }
        if let htmlData = item.htmlData {
            pbItem.setData(htmlData, forType: .html)
        }
        pbItem.setString(item.text, forType: .string)
        
        pasteboard.writeObjects([pbItem])
        
        // changeCountを更新して、自分の書き込みを検知対象外にする
        self.changeCount = pasteboard.changeCount
        
        // 監視を再開
        isMonitoring = true
        
        // タイムスタンプを現在の時刻に更新し、リストの先頭に移動する
        let updatedItem = ClipboardItem(
            id: item.id,
            text: item.text,
            type: item.type,
            timestamp: Date(),
            rawData: item.rawData,
            htmlData: item.htmlData,
            sourceApp: item.sourceApp
        )
        
        self.items.removeAll { $0.id == item.id || $0.text == item.text }
        self.items.insert(updatedItem, at: 0)
        self.saveItems()
        
        // システムイベントでCommand+Vを入力し貼り付けを実行
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        let src = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true) else { return }
        keyDown.flags = CGEventFlags.maskCommand
        guard let keyUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false) else { return }
        keyUp.flags = CGEventFlags.maskCommand
        
        keyDown.post(tap: CGEventTapLocation.cghidEventTap)
        keyUp.post(tap: CGEventTapLocation.cghidEventTap)
    }
    
    // 永続化関連
    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save clipboard items: \(error)")
        }
    }
    
    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            self.items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load clipboard items: \(error). Clearing corrupted history.")
            clearHistory()
        }
    }
    
    func clearHistory() {
        self.items.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    func updateMaxItems(_ count: Int) {
        DispatchQueue.main.async {
            self.maxItems = count
            UserDefaults.standard.set(count, forKey: self.maxItemsKey)
            
            // 上限数を超えたら削除
            if self.items.count > count {
                self.items = Array(self.items.prefix(count))
                self.saveItems()
            }
        }
    }
}
