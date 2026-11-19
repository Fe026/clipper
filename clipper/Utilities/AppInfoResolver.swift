import AppKit
import SwiftUI

/// Bundle ID からアプリ名・アイコンを解決するユーティリティ。
/// `NSWorkspace` への問い合わせはメインスレッドでの呼び出しを想定し、結果をキャッシュする。
enum AppInfoResolver {
    private static let iconCache = NSCache<NSString, NSImage>()

    /// アプリの URL から Bundle ID を取得する
    static func bundleIdentifier(from appURL: URL) -> String? {
        if let bundle = Bundle(url: appURL), let bundleID = bundle.bundleIdentifier {
            return bundleID
        }
        // フォールバック: Info.plist を直接読む（Bundle 初期化に失敗した場合）
        let infoPlistURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let bundleID = plist["CFBundleIdentifier"] as? String
        else {
            return nil
        }
        return bundleID
    }

    /// Bundle ID からアプリの表示名を取得する。解決できない場合は Bundle ID をそのまま返す。
    static func displayName(for bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return url.deletingPathExtension().lastPathComponent
        }
        return bundleID
    }

    /// Bundle ID からアプリのアイコンを取得する。解決できない場合は nil。
    static func icon(for bundleID: String?) -> NSImage? {
        guard let bundleID, !bundleID.isEmpty else { return nil }
        if let cached = iconCache.object(forKey: bundleID as NSString) {
            return cached
        }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        let image = NSWorkspace.shared.icon(forFile: url.path)
        iconCache.setObject(image, forKey: bundleID as NSString)
        return image
    }

    /// SwiftUI 用のアイコン取得。解決できない場合はフォールバックのシステムイメージを返す。
    static func swiftUIImage(for bundleID: String?) -> Image {
        if let nsImage = icon(for: bundleID) {
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "app")
    }
}
