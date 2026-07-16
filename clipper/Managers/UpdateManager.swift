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
class UpdateManager: ObservableObject, UpdateManaging {
    @Published var state: UpdateState = .idle
    
    var currentVersion: String {
        return AppVersionProvider.currentVersion
    }
    
    func checkForUpdates() {
        state = .checking
        
        guard let url = AppConstants.URLs.gitHubReleasesAPI else {
            state = .error("無効なリポジトリURLです。")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        // User-Agent は GitHub API のリクエストに必須です
        request.setValue("clipper-app", forHTTPHeaderField: "User-Agent")
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.state = .error("無効なレスポンスを受信しました。")
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 403 {
                        self.state = .error("APIの利用制限に達しました。時間をおいて再試行してください。")
                    } else {
                        self.state = .error("サーバーエラー（ステータスコード: \(httpResponse.statusCode)）")
                    }
                    return
                }
                
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                self.processRelease(release)
            } catch {
                self.state = .error("通信エラー: \(error.localizedDescription)")
            }
        }
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
        
        // バージョン比較: セマンティックバージョニングに基づく比較
        if isNewerVersion(latest: cleanTagName, current: cleanCurrentVersion) {
            if let url = URL(string: release.htmlUrl) {
                self.state = .updateAvailable(latestVersion: rawTagName, releaseUrl: url)
            } else {
                self.state = .error("無効なリリースURLです。")
            }
        } else {
            self.state = .noUpdate(latestVersion: rawTagName)
        }
    }
    
    func isNewerVersion(latest: String, current: String) -> Bool {
        let latestComponents = latest.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        
        let count = max(latestComponents.count, currentComponents.count)
        for i in 0..<count {
            let latestVal = i < latestComponents.count ? latestComponents[i] : 0
            let currentVal = i < currentComponents.count ? currentComponents[i] : 0
            
            if latestVal > currentVal {
                return true
            } else if latestVal < currentVal {
                return false
            }
        }
        return false
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
