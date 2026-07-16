import Foundation
import AppKit
import OSLog
import Combine

@MainActor
class ClipboardManager: ObservableObject, ClipboardManaging {
    @Published var items: [ClipboardItem] = []
    
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int
    private var monitorTask: Task<Void, Never>?
    private var isMonitoring = true
    
    @Published var maxItems: Int
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
                    try await Task.sleep(nanoseconds: UInt64(AppConstants.Clipboard.pollingInterval * 1_000_000_000))
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
            
            let newItem = ClipboardItem(text: text, type: .text, rtfData: rtfData, htmlData: htmlData, sourceApp: sourceAppName)
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
        defer {
            isMonitoring = true
        }
        
        // タイムスタンプを現在の時刻に更新し、リストの先頭に移動する
        let updatedItem = ClipboardItem(
            id: item.id,
            text: item.text,
            type: item.type,
            timestamp: Date(),
            rtfData: item.rtfData,
            htmlData: item.htmlData,
            sourceApp: item.sourceApp
        )
        
        // クリップボード書き込みとペーストの実行は PasteService に委譲する
        PasteService.shared.paste(item: updatedItem)
        
        // changeCountを更新して、自分の書き込みを検知対象外にする
        self.changeCount = pasteboard.changeCount
        
        self.items.removeAll { $0.id == item.id || $0.text == item.text }
        self.items.insert(updatedItem, at: 0)
        self.saveItems()
    }
    
    // 永続化関連
    private var historyFileURL: URL? {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let clipperURL = appSupportURL.appendingPathComponent("clipper", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: clipperURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.error("Failed to create Application Support/clipper directory: \(error.localizedDescription)")
            return nil
        }
        
        return clipperURL.appendingPathComponent("history.json")
    }
    
    private var saveTask: Task<Void, Never>?
    
    private func saveItems() {
        saveTask?.cancel()
        
        saveTask = Task(priority: .background) {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                guard !Task.isCancelled else { return }
                
                let itemsToSave = await MainActor.run { self.items }
                let data = try JSONEncoder().encode(itemsToSave)
                
                guard let fileURL = self.historyFileURL else { return }
                try data.write(to: fileURL, options: [.atomic])
                self.logger.info("Successfully saved \(itemsToSave.count) items to JSON file.")
            } catch is CancellationError {
                // Ignore cancellation
            } catch {
                self.logger.error("Failed to save clipboard items: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadItems() {
        if let fileURL = historyFileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                self.items = try JSONDecoder().decode([ClipboardItem].self, from: data)
                logger.info("Loaded \(self.items.count) items from JSON file.")
                return
            } catch {
                logger.error("Failed to load clipboard items from JSON file: \(error.localizedDescription)")
            }
        }
        
        if let oldData = UserDefaults.standard.data(forKey: UserDefaultsKeys.clipboardHistory) {
            do {
                self.items = try JSONDecoder().decode([ClipboardItem].self, from: oldData)
                logger.info("Successfully migrated \(self.items.count) items from UserDefaults.")
                
                saveItems()
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.clipboardHistory)
                return
            } catch {
                logger.error("Failed to migrate items from UserDefaults: \(error.localizedDescription)")
            }
        }
    }
    
    func clearHistory() {
        self.items.removeAll()
        saveTask?.cancel()
        
        if let fileURL = historyFileURL {
            do {
                let data = try JSONEncoder().encode([ClipboardItem]())
                try data.write(to: fileURL, options: [.atomic])
                logger.info("Successfully cleared history and saved empty state.")
            } catch {
                logger.error("Failed to clear history file: \(error.localizedDescription)")
            }
        }
        
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
