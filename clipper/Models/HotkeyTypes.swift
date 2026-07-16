import AppKit

enum ModifierKeyOption: String, CaseIterable, Identifiable {
    case command = "Command"
    case option = "Option"
    case control = "Control"
    case shift = "Shift"
    
    var id: String { self.rawValue }
    
    var flags: NSEvent.ModifierFlags {
        switch self {
        case .command:
            return .command
        case .option:
            return .option
        case .control:
            return .control
        case .shift:
            return .shift
        }
    }
}

enum HotkeyTypeOption: String, CaseIterable, Identifiable {
    case doubleTap = "double_tap"
    case shortcut = "shortcut"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .doubleTap: return "修飾キーのダブルタップ"
        case .shortcut: return "修飾キー + キー"
        }
    }
}

enum ShortcutKeyOption: String, CaseIterable, Identifiable {
    case space = "Space"
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case h = "H"
    case i = "I"
    case j = "J"
    case k = "K"
    case l = "L"
    case m = "M"
    case n = "N"
    case o = "O"
    case p = "P"
    case q = "Q"
    case r = "R"
    case s = "S"
    case t = "T"
    case u = "U"
    case v = "V"
    case w = "W"
    case x = "X"
    case y = "Y"
    case z = "Z"
    
    var id: String { self.rawValue }
    
    private static let keyMap: [ShortcutKeyOption: (keyCode: UInt16, char: UInt32)] = [
        .a: (0x00, 0x41),
        .s: (0x01, 0x53),
        .d: (0x02, 0x44),
        .f: (0x03, 0x46),
        .h: (0x04, 0x48),
        .g: (0x05, 0x47),
        .z: (0x06, 0x5A),
        .x: (0x07, 0x58),
        .c: (0x08, 0x43),
        .v: (0x09, 0x56),
        .b: (0x0B, 0x42),
        .q: (0x0C, 0x51),
        .w: (0x0D, 0x57),
        .e: (0x0E, 0x45),
        .r: (0x0F, 0x52),
        .y: (0x10, 0x59),
        .t: (0x11, 0x54),
        .o: (0x1F, 0x4F),
        .u: (0x20, 0x55),
        .i: (0x22, 0x49),
        .p: (0x23, 0x50),
        .l: (0x25, 0x4C),
        .j: (0x26, 0x4A),
        .k: (0x28, 0x4B),
        .n: (0x2D, 0x4E),
        .m: (0x2E, 0x4D),
        .space: (0x31, 0x20)
    ]
    
    var keyCode: UInt16 {
        return Self.keyMap[self]?.keyCode ?? 0
    }
    
    static func keyString(from keyCode: UInt16) -> String {
        switch keyCode {
        case 36: return "↩"
        case 48: return "⇥"
        case 49: return "Space"
        case 51: return "⌫"
        case 53: return "⎋"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default:
            if let charCode = eventCharacters(from: keyCode),
               let scalar = UnicodeScalar(charCode) {
                return String(Character(scalar)).uppercased()
            }
            return "Key(\(keyCode))"
        }
    }
    
    static func eventCharacters(from keyCode: UInt16) -> UInt32? {
        return keyMap.values.first(where: { $0.keyCode == keyCode })?.char
    }
}
