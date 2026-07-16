import Foundation
import AppKit
import OSLog

@MainActor
protocol PasteServing: AnyObject {
    func paste(item: ClipboardItem)
    var isAccessibilityTrusted: Bool { get }
}

@MainActor
class PasteService: PasteServing {
    static let shared = PasteService()
    
    private let vKeyCode: CGKeyCode = 0x09 // 'v' key code
    private let pasteSimulationDelay: TimeInterval = 0.1
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "clipper", category: "PasteService")
    
    var isAccessibilityTrusted: Bool {
        let options = ["AXTrustedCheckOptionPrompt": false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func paste(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let pbItem = NSPasteboardItem()
        if let rtfData = item.rtfData {
            pbItem.setData(rtfData, forType: .rtf)
        }
        if let htmlData = item.htmlData {
            pbItem.setData(htmlData, forType: .html)
        }
        pbItem.setString(item.text, forType: .string)
        
        pasteboard.writeObjects([pbItem])
        
        // アクセシビリティ権限のチェック
        if !isAccessibilityTrusted {
            logger.warning("Accessibility permission not granted. Requesting permission prompt...")
            // プロンプトを表示してユーザーに許可を促す
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
        
        Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(pasteSimulationDelay * 1_000_000_000))
                self.simulatePaste()
            } catch {
                logger.error("Failed to sleep before simulating paste: \(error.localizedDescription)")
            }
        }
    }
    
    private func simulatePaste() {
        guard let src = CGEventSource(stateID: .hidSystemState) else {
            logger.error("Failed to create CGEventSource for simulating paste")
            return
        }
        guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true) else {
            logger.error("Failed to create keyDown CGEvent for simulating paste")
            return
        }
        keyDown.flags = CGEventFlags.maskCommand
        guard let keyUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false) else {
            logger.error("Failed to create keyUp CGEvent for simulating paste")
            return
        }
        keyUp.flags = CGEventFlags.maskCommand
        
        keyDown.post(tap: CGEventTapLocation.cghidEventTap)
        keyUp.post(tap: CGEventTapLocation.cghidEventTap)
    }
}
