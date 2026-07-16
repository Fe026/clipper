import SwiftUI

struct UpdateSettingsView: View {
    @StateObject private var updateManager = UpdateManager()
    
    private var currentVersionFormatted: String {
        let version = updateManager.currentVersion
        return version.lowercased().hasPrefix("v") ? version : "v\(version)"
    }
    
    private func formatVersion(_ version: String) -> String {
        return version.lowercased().hasPrefix("v") ? version : "v\(version)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("GitHub リポジトリ (Fe026/clipper) の Releases から最新バージョンを確認し、アプリを更新します。")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text("現在のバージョン:")
                    .font(.system(size: 12, weight: .bold))
                Text(currentVersionFormatted)
                    .font(.system(size: 12))
            }
            
            Divider()
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("アップデートの確認:")
                    .font(.system(size: 12, weight: .bold))
                
                HStack(spacing: 12) {
                    Button(action: {
                        updateManager.checkForUpdates()
                    }) {
                        Label("アップデートを確認", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(updateManager.state == .checking)
                    
                    switch updateManager.state {
                    case .checking:
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("確認中...")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    default:
                        EmptyView()
                    }
                }
                
                // ステータス表示
                statusMessageView
            }
        }
        .onAppear {
            // 設定画面が開かれたときに自動でアップデートを確認する
            updateManager.checkForUpdates()
        }
    }
    
    @ViewBuilder
    private var statusMessageView: some View {
        switch updateManager.state {
        case .idle:
            Text("アップデートはまだ確認されていません。")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
        case .checking:
            EmptyView()
            
        case .noUpdate(let latestVersion):
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("最新バージョンです (最新リリース: \(formatVersion(latestVersion)))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
            
        case .updateAvailable(let latestVersion, let url):
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("新しいバージョン (\(formatVersion(latestVersion))) が利用可能です。")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    updateManager.openReleaseUrl(url)
                }) {
                    Label("アップデートをダウンロード (ブラウザが開きます)", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(.top, 4)
            
        case .error(let message):
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
            .padding(.top, 4)
        }
    }
}
