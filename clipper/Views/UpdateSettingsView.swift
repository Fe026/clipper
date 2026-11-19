import SwiftUI

struct UpdateSettingsView: View {
    @StateObject private var updateManager = UpdateManager()

    private var currentVersionFormatted: String {
        AppVersionProvider.currentVersionFormatted
    }

    private func formatVersion(_ version: String) -> String {
        version.lowercased().hasPrefix("v") ? version : "v\(version)"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("現在のバージョン") {
                    Text(currentVersionFormatted)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                LabeledContent("ステータス") {
                    statusMessageView
                }
            } header: {
                Text("バージョン情報")
            } footer: {
                Text("GitHub リポジトリ (Fe026/clipper) の Releases から最新バージョンを確認します。")
            }

            Section {
                HStack(spacing: 10) {
                    Button {
                        updateManager.checkForUpdates()
                    } label: {
                        Label("アップデートを確認", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.glass)
                    .disabled(updateManager.state == .checking)

                    if case .updateAvailable(_, let url) = updateManager.state {
                        Button {
                            updateManager.openReleaseUrl(url)
                        } label: {
                            Label("ダウンロード", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.glassProminent)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .onAppear {
            // 設定画面が開かれたときに自動でアップデートを確認する
            updateManager.checkForUpdates()
        }
    }

    @ViewBuilder
    private var statusMessageView: some View {
        switch updateManager.state {
        case .idle:
            Text("未確認")
                .font(.callout)
                .foregroundStyle(.secondary)

        case .checking:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("確認中...")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

        case .noUpdate(let latestVersion):
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.green)
                Text("最新バージョンです (\(formatVersion(latestVersion)))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

        case .updateAvailable(let latestVersion, _):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
                Text("新しいバージョン (\(formatVersion(latestVersion))) が利用可能です")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.primary)
            }

        case .error(let message):
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.red)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
