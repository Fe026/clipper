import Foundation

@MainActor
protocol PanelManaging: AnyObject {
    var panel: FloatingPanel? { get }
    func setupPanel<Manager: ClipboardManaging & ObservableObject>(clipboardManager: Manager)
    func togglePanel()
    func showPanel()
    func closePanel()
}
