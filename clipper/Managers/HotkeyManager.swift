import AppKit

@MainActor
class HotkeyManager: HotkeyManaging {
    private var globalEventMonitor: GlobalEventMonitor?
    private var lastCommandKeyPressTime: Date?
    
    var onDoubleTap: (() -> Void)?
    
    // キャッシュされた設定値
    private var isRecordingShortcut: Bool = false
    private var hotkeyType: HotkeyTypeOption = .doubleTap
    private var modifierKey: ModifierKeyOption = .command
    private var shortcutModifiers: NSEvent.ModifierFlags = [.command, .shift]
    private var shortcutKeyCode: UInt16 = 9 // V
    
    init() {
        loadSettings()
        // UserDefaultsの変更を監視してキャッシュを更新する
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        // ショートカット記録状態の変更を監視する
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(isRecordingShortcutDidChange(_:)),
            name: .clipperIsRecordingShortcutDidChange,
            object: nil
        )
    }
    
    deinit {
        // NotificationCenter.default.removeObserver は iOS 9 / macOS 10.11 以降は自動で行われるため
        // deinit での明示的な呼び出しは必須ではありませんが、Swift 6 アクター外 deinit での監視解除エラーを防ぐためにも不要な場合は避けるか、安全に処理します。
    }
    
    @objc private func userDefaultsDidChange() {
        loadSettings()
    }
    
    @objc private func isRecordingShortcutDidChange(_ notification: Notification) {
        if let isRecording = notification.userInfo?["isRecording"] as? Bool {
            self.isRecordingShortcut = isRecording
        }
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        let hotkeyTypeRaw = defaults.string(forKey: UserDefaultsKeys.hotkeyType) ?? HotkeyTypeOption.doubleTap.rawValue
        self.hotkeyType = HotkeyTypeOption(rawValue: hotkeyTypeRaw) ?? .doubleTap
        
        let rawModifier = defaults.string(forKey: UserDefaultsKeys.modifierKey) ?? ModifierKeyOption.command.rawValue
        self.modifierKey = ModifierKeyOption(rawValue: rawModifier) ?? .command
        
        let savedModifiersRaw = defaults.integer(forKey: UserDefaultsKeys.shortcutModifiers)
        if savedModifiersRaw == 0 {
            // デフォルトは Command + Shift
            self.shortcutModifiers = [.command, .shift]
        } else {
            self.shortcutModifiers = NSEvent.ModifierFlags(rawValue: UInt(savedModifiersRaw))
        }
        
        let savedKeyCode = defaults.integer(forKey: UserDefaultsKeys.shortcutKeyCode)
        if savedModifiersRaw == 0 && savedKeyCode == 0 {
            // デフォルトは V (9)
            self.shortcutKeyCode = UInt16(9)
        } else {
            self.shortcutKeyCode = UInt16(savedKeyCode)
        }
    }
    
    func setupKeyboardMonitor() {
        // モディファイアキーの変更イベントとキー押下イベントの両方を監視
        globalEventMonitor = GlobalEventMonitor(mask: [.flagsChanged, .keyDown]) { [weak self] event in
            guard let self = self else { return }
            
            // ショートカットキー設定入力中（記録中）は、ホットキー入力を完全に無視する
            if self.isRecordingShortcut {
                return
            }
            
            if self.hotkeyType == .doubleTap {
                if event.type == .flagsChanged {
                    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    if flags == self.modifierKey.flags {
                        let now = Date()
                        if let lastTime = self.lastCommandKeyPressTime {
                            let diff = now.timeIntervalSince(lastTime)
                            if diff < AppConstants.Clipboard.doubleTapInterval {
                                DispatchQueue.main.async {
                                    self.onDoubleTap?()
                                }
                                self.lastCommandKeyPressTime = nil
                                return
                            }
                        }
                        self.lastCommandKeyPressTime = now
                    }
                }
            } else {
                if event.type == .keyDown {
                    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    
                    if flags == self.shortcutModifiers && event.keyCode == self.shortcutKeyCode {
                        DispatchQueue.main.async {
                            self.onDoubleTap?()
                        }
                    }
                }
            }
        }
        globalEventMonitor?.start()
    }
}
