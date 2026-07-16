import Foundation
import AppKit
import Combine
import OSLog

@MainActor
class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int
    private var monitorTask: Task<Void, Never>?
    private var isMonitoring = true
    
    @Published var maxItems: Int
    private let vKeyCode: CGKeyCode = 0x09 // 'v' key code
    private let pasteSimulationDelay: TimeInterval = 0.1
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "clipper", category: "ClipboardManager")
    
    init() {
        let savedMax = UserDefaults.standard.integer(forKey: UserDefaultsKeys.maxItems)
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
            
            logger.debug("Copied Text: \(text.prefix(30), privacy: .public)...")
            logger.debug("RTF Data size: \(rtfData?.count ?? 0) bytes")
            logger.debug("HTML Data size: \(htmlData?.count ?? 0) bytes")
            
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
        DispatchQueue.main.asyncAfter(deadline: .now() + pasteSimulationDelay) {
            self.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        guard let src = CGEventSource(stateID: .hidSystemState) else {
            logger.error("Failed to create CGEventSource for simulating paste")
            return
        }
        guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true) else {
            logger.error("Failed to create keyDown CGEvent for simulating paste")
            return
        }
        keyDown.flags = CGEventFlags.maskCommand
        guard let keyUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false) else {
            logger.error("Failed to create keyUp CGEvent for simulating paste")
            return
        }
        keyUp.flags = CGEventFlags.maskCommand
        
        keyDown.post(tap: CGEventTapLocation.cghidEventTap)
        keyUp.post(tap: CGEventTapLocation.cghidEventTap)
    }
    
    // 永続化関連
    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.clipboardHistory)
        } catch {
            logger.error("Failed to save clipboard items: \(error.localizedDescription)")
        }
    }
    
    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.clipboardHistory) else { return }
        do {
            self.items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            logger.error("Failed to load clipboard items: \(error.localizedDescription). Clearing corrupted history.")
            clearHistory()
        }
    }
    
    func clearHistory() {
        self.items.removeAll()
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.clipboardHistory)
    }
    
    func updateMaxItems(_ count: Int) {
        self.maxItems = count
        UserDefaults.standard.set(count, forKey: UserDefaultsKeys.maxItems)
        
        // 上限数を超えたら削除
        if self.items.count > count {
            self.items = Array(self.items.prefix(count))
            self.saveItems()
        }
    }
}
