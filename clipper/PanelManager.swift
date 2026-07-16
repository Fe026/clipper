import AppKit
import SwiftUI

@MainActor
class PanelManager {
    var panel: FloatingPanel?
    
    func setupPanel(clipboardManager: ClipboardManager) {
        let contentView = ContentView(clipboardManager: clipboardManager) { [weak self] in
            self?.closePanel()
        } onSizeChanged: { [weak self] newSize in
            self?.updatePanelSize(newSize)
        }
        panel = FloatingPanel(contentView: AnyView(contentView))
    }
    
    private var previousActiveApp: NSRunningApplication?
    
    private func updatePanelSize(_ size: CGSize) {
        guard let panel = panel else { return }
        
        var frame = panel.frame
        let oldHeight = frame.size.height
        let newHeight = size.height
        
        if abs(oldHeight - newHeight) > 0.5 {
            let diff = newHeight - oldHeight
            // macOSは左下が原点のため、ウィンドウの上端が変わらないようにY座標を調整
            frame.origin.y -= diff
            frame.size.height = newHeight
            frame.size.width = size.width
            
            panel.setFrame(frame, display: true, animate: false)
        }
    }
    
    func togglePanel() {
        guard let panel = panel else { return }
        if panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }
    
    func showPanel() {
        guard let panel = panel else { return }
        
        // Clipperを表示する直前にアクティブだったアプリを記憶
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.bundleIdentifier != Bundle.main.bundleIdentifier {
            self.previousActiveApp = frontmost
        }
        
        let mouseLocation = NSEvent.mouseLocation
        let panelSize = panel.frame.size
        
        // デフォルトでカーソルの「すぐ右下」に表示されるように設定 (オフセットなし)
        var originX = mouseLocation.x
        var originY = mouseLocation.y - panelSize.height
        
        // パネルが画面外にはみ出さないように現在のスクリーン基準で位置調整
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main {
            let screenFrame = screen.visibleFrame
            
            // Y方向調整
            if originY < screenFrame.minY {
                // 下端はみ出し（下につく場合）：画面の下に合わせる
                originY = screenFrame.minY
            } else if originY + panelSize.height > screenFrame.maxY {
                // 上端はみ出し
                originY = screenFrame.maxY - panelSize.height
            }
            
            // X方向調整：通常はマウスの右側、右端はみ出しなら左側、それでも左端はみ出しなら左端に合わせる
            if originX + panelSize.width > screenFrame.maxX {
                originX = mouseLocation.x - panelSize.width
            }
            if originX < screenFrame.minX {
                originX = screenFrame.minX
            }
        }
        
        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
        
        // アプリケーションをアクティブにしてウィンドウを最前面にし、キーフォーカスを当てる
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        
        NotificationCenter.default.post(name: NSNotification.Name("ClipperPanelDidShow"), object: nil)
    }
    
    func closePanel() {
        panel?.orderOut(nil)
        
        // 記憶していた元のアプリをアクティブにする
        if let previousApp = previousActiveApp {
            previousApp.activate(options: [])
            previousActiveApp = nil
        }
    }
}
