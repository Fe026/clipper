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
            let menu = buildStatusMenu()
            if let button = statusItem?.button {
                menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
            }
        } else {
            panelManager.togglePanel()
        }
    }
    
    private func buildStatusMenu() -> NSMenu {
        return StatusMenuBuilder.build(
            delegate: self,
            maxItems: clipboardManager.maxItems,
            clearAction: #selector(clearHistoryClicked),
            limitAction: #selector(limitClicked(_:)),
            settingsAction: #selector(openSettings)
        )
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
                contentRect: NSRect(x: 0, y: 0, width: LayoutMetrics.settingsWindowWidth, height: LayoutMetrics.settingsWindowHeight),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Clipper 設定"
            window.toolbarStyle = .unified
            window.titlebarSeparatorStyle = .none
            window.delegate = self
            window.contentViewController = hostingController
            window.minSize = NSSize(width: LayoutMetrics.settingsWindowWidth, height: LayoutMetrics.settingsWindowHeight)
            window.setContentSize(NSSize(width: LayoutMetrics.settingsWindowWidth, height: LayoutMetrics.settingsWindowHeight))
            window.center()
            window.isReleasedWhenClosed = false
            self.settingsWindow = window
        }
        
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindow {
            settingsWindow = nil
        }
    }
}
