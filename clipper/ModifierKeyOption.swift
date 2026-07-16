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
    
    var keyCode: UInt16 {
        switch self {
        case .a: return 0x00
        case .s: return 0x01
        case .d: return 0x02
        case .f: return 0x03
        case .h: return 0x04
        case .g: return 0x05
        case .z: return 0x06
        case .x: return 0x07
        case .c: return 0x08
        case .v: return 0x09
        case .b: return 0x0B
        case .q: return 0x0C
        case .w: return 0x0D
        case .e: return 0x0E
        case .r: return 0x0F
        case .y: return 0x10
        case .t: return 0x11
        case .o: return 0x1F
        case .u: return 0x20
        case .i: return 0x22
        case .p: return 0x23
        case .l: return 0x25
        case .j: return 0x26
        case .k: return 0x28
        case .n: return 0x2D
        case .m: return 0x2E
        case .space: return 0x31
        }
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
        switch keyCode {
        case 0: return 0x41 // A
        case 1: return 0x53 // S
        case 2: return 0x44 // D
        case 3: return 0x46 // F
        case 4: return 0x48 // H
        case 5: return 0x47 // G
        case 6: return 0x5A // Z
        case 7: return 0x58 // X
        case 8: return 0x43 // C
        case 9: return 0x56 // V
        case 11: return 0x42 // B
        case 12: return 0x51 // Q
        case 13: return 0x57 // W
        case 14: return 0x45 // E
        case 15: return 0x52 // R
        case 16: return 0x59 // Y
        case 17: return 0x54 // T
        case 18: return 0x31 // 1
        case 19: return 0x32 // 2
        case 20: return 0x33 // 3
        case 21: return 0x34 // 4
        case 22: return 0x36 // 6
        case 23: return 0x35 // 5
        case 24: return 0x3D // =
        case 25: return 0x39 // 9
        case 26: return 0x37 // 7
        case 27: return 0x2D // -
        case 28: return 0x38 // 8
        case 29: return 0x30 // 0
        case 31: return 0x4F // O
        case 32: return 0x55 // U
        case 34: return 0x49 // I
        case 35: return 0x50 // P
        case 37: return 0x4C // L
        case 38: return 0x4A // J
        case 40: return 0x4B // K
        case 45: return 0x4E // N
        case 46: return 0x4D // M
        default: return nil
        }
    }
}
