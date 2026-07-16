import Foundation

struct AppVersionProvider {
    static var currentVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static var currentVersionFormatted: String {
        let version = currentVersion
        return version.lowercased().hasPrefix("v") ? version : "v\(version)"
    }
}
