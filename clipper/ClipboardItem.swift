import Foundation

enum ClipboardType: String, Codable {
    case text
    case image
    case file
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let type: ClipboardType
    let timestamp: Date
    let rawData: Data? // RTF データ
    let htmlData: Data? // HTML データ (Webブラウザ等のコピー用)
    
    // コピー元のアプリケーション情報（オプショナル）
    let sourceApp: String?
    
    init(id: UUID = UUID(), text: String, type: ClipboardType = .text, timestamp: Date = Date(), rawData: Data? = nil, htmlData: Data? = nil, sourceApp: String? = nil) {
        self.id = id
        self.text = text
        self.type = type
        self.timestamp = timestamp
        self.rawData = rawData
        self.htmlData = htmlData
        self.sourceApp = sourceApp
    }
}
