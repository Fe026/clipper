import Foundation

@MainActor
protocol ClipboardManaging: AnyObject {
    var items: [ClipboardItem] { get }
    var maxItems: Int { get }
    
    func selectAndPaste(_ item: ClipboardItem)
    func clearHistory()
    func updateMaxItems(_ count: Int)
}
