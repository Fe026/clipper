import AppKit

class HotkeyManager {
    private var globalEventMonitor: GlobalEventMonitor?
    private var lastCommandKeyPressTime: Date?
    
    var onDoubleTap: (() -> Void)?
    
    func setupKeyboardMonitor() {
        // モディファイアキーの変更イベントとキー押下イベントの両方を監視
        globalEventMonitor = GlobalEventMonitor(mask: [.flagsChanged, .keyDown]) { [weak self] event in
            guard let self = self else { return }
            
            // ショートカットキー設定入力中（記録中）は、ホットキー入力を完全に無視する
            if UserDefaults.standard.bool(forKey: UserDefaultsKeys.isRecordingShortcut) {
                return
            }
            
            let hotkeyTypeRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.hotkeyType) ?? HotkeyTypeOption.doubleTap.rawValue
            let hotkeyType = HotkeyTypeOption(rawValue: hotkeyTypeRaw) ?? .doubleTap
            
            if hotkeyType == .doubleTap {
                let rawModifier = UserDefaults.standard.string(forKey: UserDefaultsKeys.modifierKey) ?? ModifierKeyOption.command.rawValue
                let selectedModifier = ModifierKeyOption(rawValue: rawModifier) ?? .command
                
                if event.type == .flagsChanged {
                    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    if flags == selectedModifier.flags {
                        let now = Date()
                        if let lastTime = self.lastCommandKeyPressTime {
                            let diff = now.timeIntervalSince(lastTime)
                            if diff < 0.3 {
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
                    
                    // 保存された modifiers & keycode を読み出す
                    let savedModifiersRaw = UserDefaults.standard.integer(forKey: UserDefaultsKeys.shortcutModifiers)
                    let savedModifiers = NSEvent.ModifierFlags(rawValue: UInt(savedModifiersRaw))
                    let savedKeyCode = UInt16(UserDefaults.standard.integer(forKey: UserDefaultsKeys.shortcutKeyCode))
                    
                    // デフォルト値 (未設定時は Command + V)
                    let targetModifiers = savedModifiersRaw == 0 ? .command : savedModifiers
                    let targetKeyCode = savedModifiersRaw == 0 && savedKeyCode == 0 ? UInt16(9) : savedKeyCode
                    
                    if flags == targetModifiers && event.keyCode == targetKeyCode {
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
