import SwiftUI
import AppKit

@main
struct ClipperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    let panelManager = PanelManager()
    let clipboardManager = ClipboardManager()
    var hotkeyManager = HotkeyManager()
    var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 起動時にショートカット記録状態を確実にリセット
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.isRecordingShortcut)
        
        // Dockアイコンを完全に非表示にする
        NSApp.setActivationPolicy(.accessory)
        
        // アプリアイコンに SF Symbol の "book.pages" を設定
        if let iconImage = NSImage(systemSymbolName: "book.pages", accessibilityDescription: "Clipper App Icon") {
            NSApp.applicationIconImage = iconImage
        }
        
        // メニューバーアイテムのセットアップ
        setupStatusItem()
        
        // パネルのセットアップ
        panelManager.setupPanel(clipboardManager: clipboardManager)
        
        // キーボード監視のセットアップ
        hotkeyManager.onDoubleTap = { [weak self] in
            self?.panelManager.togglePanel()
        }
        hotkeyManager.setupKeyboardMonitor()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "book.pages", accessibilityDescription: "Clipper")
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    

    @objc private func statusItemClicked() {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            let menu = NSMenu()
            
            let clearItem = NSMenuItem(title: "履歴をクリア", action: #selector(clearHistoryClicked), keyEquivalent: "")
            clearItem.target = self
            menu.addItem(clearItem)
            
            let limitMenu = NSMenu()
            let limits = [50, 100, 500, 1000, 2000]
            for limit in limits {
                let item = NSMenuItem(title: "\(limit)件", action: #selector(limitClicked(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = limit
                if clipboardManager.maxItems == limit {
                    item.state = .on
                }
                limitMenu.addItem(item)
            }
            let limitSubMenu = NSMenuItem(title: "保存件数制限", action: nil, keyEquivalent: "")
            limitSubMenu.submenu = limitMenu
            menu.addItem(limitSubMenu)
            
            menu.addItem(NSMenuItem.separator())
            
            let settingsItem = NSMenuItem(title: "設定...", action: #selector(openSettings), keyEquivalent: ",")
            settingsItem.target = self
            menu.addItem(settingsItem)
            
            menu.addItem(NSMenuItem.separator())
            
            let quitItem = NSMenuItem(title: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            menu.addItem(quitItem)
            
            if let button = statusItem?.button {
                menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
            }
        } else {
            panelManager.togglePanel()
        }
    }
    
    @objc private func clearHistoryClicked() {
        clipboardManager.clearHistory()
    }
    
    @objc private func limitClicked(_ sender: NSMenuItem) {
        if let limit = sender.representedObject as? Int {
            clipboardManager.updateMaxItems(limit)
        }
    }
    
    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(clipboardManager: clipboardManager)
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 340),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Clipper 設定"
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            window.isMovableByWindowBackground = true
            window.delegate = self
            window.contentViewController = hostingController
            window.minSize = NSSize(width: 500, height: 340)
            window.center()
            window.isReleasedWhenClosed = false
            self.settingsWindow = window
            
            self.positionWindowButtons(for: window)
        }
        
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func positionWindowButtons(for window: NSWindow) {
        guard let closeButton = window.standardWindowButton(.closeButton) else { return }
        if let titlebarContainer = closeButton.superview?.superview {
            var frame = titlebarContainer.frame
            frame.origin.x = 8
            frame.origin.y = window.frame.height - frame.height - 8
            titlebarContainer.frame = frame
        }
    }
    
    func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindow {
            positionWindowButtons(for: window)
        }
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindow {
            positionWindowButtons(for: window)
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindow {
            UserDefaults.standard.set(false, forKey: UserDefaultsKeys.isRecordingShortcut)
            settingsWindow = nil
        }
    }
}

