import XCTest
@testable import clipper

class ClipboardManagerTests: XCTestCase {
    var clipboardManager: ClipboardManager!
    
    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        clipboardManager = ClipboardManager()
    }
    
    override func tearDownWithError() throws {
        clipboardManager = nil
        try super.tearDownWithError()
    }
    
    @MainActor
    func testUpdateMaxItems() {
        let originalMax = clipboardManager.maxItems
        
        clipboardManager.updateMaxItems(10)
        XCTAssertEqual(clipboardManager.maxItems, 10)
        
        // 戻す
        clipboardManager.updateMaxItems(originalMax)
        XCTAssertEqual(clipboardManager.maxItems, originalMax)
    }
    
    @MainActor
    func testClearHistory() {
        clipboardManager.clearHistory()
        XCTAssertTrue(clipboardManager.items.isEmpty)
    }
}
