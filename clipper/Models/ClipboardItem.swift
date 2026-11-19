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
    
    // コピー元のアプリケーション情報
    let sourceApp: String?
    let sourceAppBundleID: String?
    
    // ピン留め状態
    let isPinned: Bool
    
    init(
        id: UUID = UUID(),
        text: String,
        type: ClipboardType = .text,
        timestamp: Date = Date(),
        rtfData: Data? = nil,
        htmlData: Data? = nil,
        sourceApp: String? = nil,
        sourceAppBundleID: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.text = text
        self.type = type
        self.timestamp = timestamp
        self.rtfData = rtfData
        self.htmlData = htmlData
        self.sourceApp = sourceApp
        self.sourceAppBundleID = sourceAppBundleID
        self.isPinned = isPinned
    }
    
    enum CodingKeys: String, CodingKey {
        case id, text, type, timestamp, rtfData, htmlData, sourceApp, sourceAppBundleID, isPinned
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.text = try container.decode(String.self, forKey: .text)
        self.type = try container.decode(ClipboardType.self, forKey: .type)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.rtfData = try container.decodeIfPresent(Data.self, forKey: .rtfData)
        self.htmlData = try container.decodeIfPresent(Data.self, forKey: .htmlData)
        self.sourceApp = try container.decodeIfPresent(String.self, forKey: .sourceApp)
        self.sourceAppBundleID = try container.decodeIfPresent(String.self, forKey: .sourceAppBundleID)
        self.isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
    
    // MARK: - ヘルパーメソッド

    /// 共通の複製処理（指定されたプロパティのみ上書きする）
    private func copy(
        timestamp: Date? = nil,
        rtfData: Data?? = nil,
        htmlData: Data?? = nil,
        isPinned: Bool? = nil
    ) -> ClipboardItem {
        ClipboardItem(
            id: id, text: text, type: type, timestamp: timestamp ?? self.timestamp,
            rtfData: rtfData ?? self.rtfData, htmlData: htmlData ?? self.htmlData,
            sourceApp: sourceApp, sourceAppBundleID: sourceAppBundleID,
            isPinned: isPinned ?? self.isPinned
        )
    }

    /// isPinned を反転したコピーを返す（タイムスタンプは維持）
    func togglingPin() -> ClipboardItem {
        copy(isPinned: !isPinned)
    }

    /// リッチテキスト情報を除去したプレーンテキストコピーを返す（タイムスタンプは維持し、更新は呼び出し側に委ねる）
    func asPlainText() -> ClipboardItem {
        copy(rtfData: .some(nil), htmlData: .some(nil))
    }

    /// タイムスタンプを現在時刻に更新したコピーを返す
    func withCurrentTimestamp() -> ClipboardItem {
        copy(timestamp: Date())
    }
}
