import AppKit

enum StatusMenuBuilder {
    @MainActor
    static func build(
        delegate: AnyObject,
        maxItems: Int,
        clearAction: Selector,
        limitAction: Selector,
        settingsAction: Selector
    ) -> NSMenu {
        let menu = NSMenu()
        
        let clearItem = NSMenuItem(title: "履歴をクリア", action: clearAction, keyEquivalent: "")
        clearItem.target = delegate
        menu.addItem(clearItem)
        
        let limitMenu = NSMenu()
        let limits = [50, 100, 500, 1000, 2000]
        for limit in limits {
            let item = NSMenuItem(title: "\(limit)件", action: limitAction, keyEquivalent: "")
            item.target = delegate
            item.representedObject = limit
            if maxItems == limit {
                item.state = .on
            }
            limitMenu.addItem(item)
        }
        let limitSubMenu = NSMenuItem(title: "保存件数制限", action: nil, keyEquivalent: "")
        limitSubMenu.submenu = limitMenu
        menu.addItem(limitSubMenu)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: "設定...", action: settingsAction, keyEquivalent: ",")
        settingsItem.target = delegate
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        return menu
    }
}
