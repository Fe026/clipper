import Foundation

@MainActor
protocol HotkeyManaging: AnyObject {
    var onDoubleTap: (() -> Void)? { get set }
    func setupKeyboardMonitor()
}
