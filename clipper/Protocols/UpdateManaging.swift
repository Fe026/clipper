import Foundation

@MainActor
protocol UpdateManaging: AnyObject {
    var state: UpdateState { get }
    var currentVersion: String { get }
    func checkForUpdates()
    func openReleaseUrl(_ url: URL)
}
