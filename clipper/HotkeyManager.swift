import AppKit

class HotkeyManager {
    private var globalEventMonitor: GlobalEventMonitor?
    private var lastCommandKeyPressTime: Date?
    
    var onDoubleTap: (() -> Void)?
    
    func setupKeyboardMonitor() {
        // モディファイアキーの変更イベントを監視
        globalEventMonitor = GlobalEventMonitor(mask: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            
            // Commandキー単体が押された場合を想定
            // flagsChangedはキーを離したときもトリガーされるため、フラグが空でない（Commandが押された）時に判定する
            if flags == .command {
                let now = Date()
                if let lastTime = self.lastCommandKeyPressTime {
                    let diff = now.timeIntervalSince(lastTime)
                    if diff < 0.3 {
                        // 0.3秒以内の連続押下でダブルタップ判定しトグル
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
        globalEventMonitor?.start()
    }
}
