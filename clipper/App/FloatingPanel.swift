import Cocoa
import SwiftUI

class FloatingPanel: NSPanel {
    var onClose: (() -> Void)?
    
    init<Content: View>(contentView: Content) {
        let initialRect = NSRect(
            x: 0,
            y: 0,
            width: LayoutMetrics.windowWidth,
            height: LayoutMetrics.minWindowHeight
        )
        super.init(
            contentRect: initialRect,
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
        
        // ウィンドウ外枠の Liquid Glass は AppKit の NSGlassEffectView で描画する
        let glassView = NSGlassEffectView(frame: initialRect)
        glassView.style = .regular
        glassView.cornerRadius = LayoutMetrics.panelCornerRadius
        glassView.autoresizingMask = [.width, .height]
        
        // NSHostingView を使用 (サイズ変更はSwiftUI側からコールバックで制御)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.sizingOptions = []
        hostingView.frame = glassView.bounds
        hostingView.autoresizingMask = [.width, .height]
        glassView.contentView = hostingView
        
        self.contentView = glassView
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
        if let onClose = onClose {
            onClose()
        } else {
            self.orderOut(nil)
        }
    }
    
    // Escapeキーが押されたときにウィンドウを閉じる
    override func cancelOperation(_ sender: Any?) {
        if let onClose = onClose {
            onClose()
        } else {
            self.orderOut(nil)
        }
    }
}
