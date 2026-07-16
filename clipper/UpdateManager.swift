import Foundation
import AppKit
import Combine

enum UpdateState: Equatable {
    case idle
    case checking
    case noUpdate(latestVersion: String)
    case updateAvailable(latestVersion: String, releaseUrl: URL)
    case error(String)
}

@MainActor
class UpdateManager: ObservableObject {
    @Published var state: UpdateState = .idle
    
    var currentVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private let repoUrl = "https://api.github.com/repos/Fe026/clipper/releases/latest"
    
    func checkForUpdates() {
        state = .checking
        
        guard let url = URL(string: repoUrl) else {
            state = .error("無効なリポジトリURLです。")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        // User-Agent は GitHub API のリクエストに必須です
        request.setValue("clipper-app", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.state = .error("通信エラー: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self.state = .error("データを受信できませんでした。")
                    return
                }
                
                do {
                    let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                    self.processRelease(release)
                } catch {
                    self.state = .error("レスポンスの解析に失敗しました。")
                }
            }
        }.resume()
    }
    
    private func processRelease(_ release: GitHubRelease) {
        let rawTagName = release.tagName
        // 最新バージョンのタグ名から 'v' または 'V' を取り除く
        var cleanTagName = rawTagName
        if cleanTagName.lowercased().hasPrefix("v") {
            cleanTagName.removeFirst()
        }
        
        // 現在のバージョンから 'v' または 'V' を取り除く
        var cleanCurrentVersion = currentVersion
        if cleanCurrentVersion.lowercased().hasPrefix("v") {
            cleanCurrentVersion.removeFirst()
        }
        
        // バージョン比較: numeric オプションを使用し、タグの方が新しければアップデートありと判定
        if cleanTagName.compare(cleanCurrentVersion, options: .numeric) == .orderedDescending {
            if let url = URL(string: release.htmlUrl) {
                self.state = .updateAvailable(latestVersion: rawTagName, releaseUrl: url)
            } else {
                self.state = .error("無効なリリースURLです。")
            }
        } else {
            self.state = .noUpdate(latestVersion: rawTagName)
        }
    }
    
    func openReleaseUrl(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}

struct GitHubRelease: Codable {
    let tagName: String
    let htmlUrl: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
    }
}
