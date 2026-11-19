import SwiftUI

/// テキストからカラーコード（HEX / RGB / RGBA）をパースするユーティリティ
enum ColorParser {
    private static let rgbRegex: NSRegularExpression? = {
        // "rgb(255, 0, 0)" / "rgba(255, 0, 0, 0.5)" の厳密な形式のみ受け付ける
        try? NSRegularExpression(pattern: #"^rgba?\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*(?:,\s*([0-9.]+)\s*)?\)$"#)
    }()

    /// テキストがカラーコード文字列であれば対応する Color を返す
    static func parse(from text: String) -> Color? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.hasPrefix("#") || trimmed.hasPrefix("rgb") else { return nil }

        if let hexColor = parseHex(trimmed) { return hexColor }
        if let rgbColor = parseRGB(trimmed) { return rgbColor }

        return nil
    }

    // MARK: - Private

    /// HEX (#fff / #ffffff / #ffffffff) のパース。不正な文字が含まれる場合は nil。
    private static func parseHex(_ text: String) -> Color? {
        guard text.hasPrefix("#") else { return nil }
        var hex = String(text.dropFirst())

        // 3桁・4桁の短縮形を6桁・8桁に展開
        if hex.count == 3 || hex.count == 4 {
            hex = hex.map { String(repeating: $0, count: 2) }.joined()
        }
        guard hex.count == 6 || hex.count == 8 else { return nil }
        // 16進数以外の文字を拒否（Scanner の戻り値無視による "#zzzzzz" → black 誤爆を防ぐ）
        guard hex.allSatisfy(\.isHexDigit) else { return nil }

        var rgbValue: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgbValue) else { return nil }

        if hex.count == 6 {
            let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            let b = Double(rgbValue & 0x0000FF) / 255.0
            return Color(red: r, green: g, blue: b)
        } else {
            let r = Double((rgbValue & 0xFF000000) >> 24) / 255.0
            let g = Double((rgbValue & 0x00FF0000) >> 16) / 255.0
            let b = Double((rgbValue & 0x0000FF00) >> 8) / 255.0
            let a = Double(rgbValue & 0x000000FF) / 255.0
            return Color(red: r, green: g, blue: b, opacity: a)
        }
    }

    /// RGB / RGBA のパース。範囲外の値はクランプし、形式不正は nil。
    private static func parseRGB(_ text: String) -> Color? {
        guard text.hasPrefix("rgb"), let regex = rgbRegex else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges >= 4
        else { return nil }

        func component(at index: Int, maximum: Double) -> Double? {
            let nsRange = match.range(at: index)
            guard nsRange.location != NSNotFound,
                  let range = Range(nsRange, in: text),
                  let value = Double(text[range])
            else { return nil }
            return min(max(value, 0), maximum) / maximum
        }

        guard let r = component(at: 1, maximum: 255),
              let g = component(at: 2, maximum: 255),
              let b = component(at: 3, maximum: 255)
        else { return nil }

        // アルファは "0.5" 形式または "50%" 形式ではなく 0...1 の数値のみ受け付ける
        var alpha = 1.0
        let alphaRange = match.range(at: 4)
        if alphaRange.location != NSNotFound,
           let range = Range(alphaRange, in: text),
           let value = Double(text[range]) {
            alpha = min(max(value, 0), 1)
        }
        return Color(red: r, green: g, blue: b, opacity: alpha)
    }
}
