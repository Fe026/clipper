import SwiftUI
import AppKit

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var modifierFlags: NSEvent.ModifierFlags
    @Binding var keyCode: UInt16
    @Binding var displayString: String
    @Binding var isRecording: Bool

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.onShortcutRecorded = { flags, code, desc in
            self.modifierFlags = flags
            self.keyCode = code
            self.displayString = desc
            self.isRecording = false
        }
        view.onFocusChanged = { focused in
            self.isRecording = focused
        }
        return view
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        nsView.displayString = displayString
        nsView.isRecording = isRecording
    }
}

class RecorderNSView: NSView {
    var onShortcutRecorded: ((NSEvent.ModifierFlags, UInt16, String) -> Void)?
    var onFocusChanged: ((Bool) -> Void)?
    
    var displayString: String = "" {
        didSet {
            needsDisplay = true
        }
    }
    
    var isRecording: Bool = false {
        didSet {
            needsDisplay = true
            if isRecording {
                window?.makeFirstResponder(self)
            }
        }
    }
    
    private var trackingArea: NSTrackingArea?
    private var isHovered = false {
        didSet {
            needsDisplay = true
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        self.trackingArea = area
    }
    
    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }
    
    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let rect = bounds.insetBy(dx: 1, dy: 1)
        let radius = rect.height / 2
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        
        if isRecording {
            NSColor.controlAccentColor.withAlphaComponent(0.14).setFill()
            NSColor.controlAccentColor.setStroke()
            path.lineWidth = 1.5
        } else if isHovered {
            NSColor.labelColor.withAlphaComponent(0.08).setFill()
            NSColor.labelColor.withAlphaComponent(0.18).setStroke()
            path.lineWidth = 1.0
        } else {
            NSColor.labelColor.withAlphaComponent(0.05).setFill()
            NSColor.separatorColor.withAlphaComponent(0.6).setStroke()
            path.lineWidth = 0.75
        }
        
        path.fill()
        path.stroke()
        
        let isEmpty = displayString.isEmpty
        let text = isRecording ? "キーを押してください..." : (isEmpty ? "未設定" : displayString)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let textColor: NSColor
        if isRecording {
            textColor = .controlAccentColor
        } else if isEmpty {
            textColor = .secondaryLabelColor
        } else {
            textColor = .labelColor
        }
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: isRecording ? .semibold : .medium),
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]
        
        let size = text.size(withAttributes: attrs)
        let textRect = NSRect(
            x: 0,
            y: (bounds.height - size.height) / 2,
            width: bounds.width,
            height: size.height
        )
        text.draw(in: textRect, withAttributes: attrs)
    }
    
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }
    
    override func becomeFirstResponder() -> Bool {
        isRecording = true
        onFocusChanged?(true)
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        isRecording = false
        onFocusChanged?(false)
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode
        
        // Escapeキー(53)でキャンセル
        if keyCode == 53 {
            window?.makeFirstResponder(nil)
            return
        }
        
        var desc = ""
        if flags.contains(.control) { desc += "⌃" }
        if flags.contains(.option) { desc += "⌥" }
        if flags.contains(.shift) { desc += "⇧" }
        if flags.contains(.command) { desc += "⌘" }
        
        desc += ShortcutKeyOption.keyString(from: keyCode)
        
        onShortcutRecorded?(flags, keyCode, desc)
        window?.makeFirstResponder(nil)
    }
}
