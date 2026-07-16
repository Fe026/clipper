import Foundation

enum ClipboardType: String, Codable {
    case text
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let type: ClipboardType
    let timestamp: Date
    let rtfData: Data? // RTF データ
    let htmlData: Data? // HTML データ (Webブラウザ等のコピー用)
    
    // コピー元のアプリケーション情報（オプショナル）
    let sourceApp: String?
    
    init(id: UUID = UUID(), text: String, type: ClipboardType = .text, timestamp: Date = Date(), rtfData: Data? = nil, htmlData: Data? = nil, sourceApp: String? = nil) {
        self.id = id
        self.text = text
        self.type = type
        self.timestamp = timestamp
        self.rtfData = rtfData
        self.htmlData = htmlData
        self.sourceApp = sourceApp
    }
}
