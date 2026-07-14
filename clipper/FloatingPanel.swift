import Cocoa
import SwiftUI

class FloatingPanel: NSPanel {
    init(contentView: AnyView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 100),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // ウィンドウ枠を非表示にし、背景を透明にする
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        
        // ウィンドウ全体の透過設定
        self.isOpaque = false
        
        // NSHostingView を使用 (サイズ変更はSwiftUI側からコールバックで制御)
        let hostingView = NSHostingView(rootView: contentView)
        self.contentView = hostingView
    }
    
    // キー入力を受け取れるようにする
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    // ユーザーがウィンドウ外をクリックしたり、他のアプリにフォーカスが移った際に自動で閉じる
    override func resignKey() {
        super.resignKey()
        self.orderOut(nil)
    }
    
    // Escapeキーが押されたときにウィンドウを閉じる
    override func cancelOperation(_ sender: Any?) {
        self.orderOut(nil)
    }
}
