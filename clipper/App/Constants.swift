import Foundation

enum AppConstants {
    enum Clipboard {
        static let pollingInterval: TimeInterval = 0.5
        static let doubleTapInterval: TimeInterval = 0.3
        static let maxFilteredItems = 50
    }
    enum URLs {
        static let gitHubRepoString = "https://github.com/Fe026/clipper"
        static let gitHubReleasesAPIString = "https://api.github.com/repos/Fe026/clipper/releases/latest"
        
        static var gitHubRepo: URL? {
            URL(string: gitHubRepoString)
        }
        
        static var gitHubReleasesAPI: URL? {
            URL(string: gitHubReleasesAPIString)
        }
    }
}

extension Notification.Name {
    static let clipperPanelDidShow = Notification.Name("ClipperPanelDidShow")
    static let clipperIsRecordingShortcutDidChange = Notification.Name("ClipperIsRecordingShortcutDidChange")
}
