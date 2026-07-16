import XCTest
@testable import clipper

class UpdateManagerTests: XCTestCase {
    var updateManager: UpdateManager!
    
    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        updateManager = UpdateManager()
    }
    
    override func tearDownWithError() throws {
        updateManager = nil
        try super.tearDownWithError()
    }
    
    @MainActor
    func testIsNewerVersion() {
        // メジャーバージョンが高い場合
        XCTAssertTrue(updateManager.isNewerVersion(latest: "2.0.0", current: "1.0.0"))
        // マイナーバージョンが高い場合
        XCTAssertTrue(updateManager.isNewerVersion(latest: "1.1.0", current: "1.0.0"))
        // パッチバージョンが高い場合
        XCTAssertTrue(updateManager.isNewerVersion(latest: "1.0.1", current: "1.0.0"))
        // 同一バージョンの場合
        XCTAssertFalse(updateManager.isNewerVersion(latest: "1.0.0", current: "1.0.0"))
        // 過去バージョンの場合
        XCTAssertFalse(updateManager.isNewerVersion(latest: "0.9.0", current: "1.0.0"))
        
        // 桁数が異なる場合
        XCTAssertTrue(updateManager.isNewerVersion(latest: "1.0.0.1", current: "1.0.0"))
        XCTAssertFalse(updateManager.isNewerVersion(latest: "1.0", current: "1.0.0"))
    }
}
