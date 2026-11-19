import SwiftUI
import UniformTypeIdentifiers
import AppKit

fileprivate struct IgnoredApp: Identifiable {
    var id: String { bundleID }
    let bundleID: String
}

struct GeneralSettingsView<Manager: ClipboardManaging & ObservableObject>: View {
    @ObservedObject var clipboardManager: Manager
    @StateObject private var loginItemService = LoginItemService.shared
    @State private var selectedMaxItems: Int
    @State private var isShowingClearAlert = false

    // 除外アプリ管理用の状態
    @State private var ignoredAppBundleIDs: [String] = []

    private var ignoredApps: [IgnoredApp] {
        ignoredAppBundleIDs.map { IgnoredApp(bundleID: $0) }
    }

    init(clipboardManager: Manager) {
        self.clipboardManager = clipboardManager
        _selectedMaxItems = State(initialValue: clipboardManager.maxItems)
    }

    var body: some View {
        Form {
            Section("一般") {
                Toggle("ログイン時に起動", isOn: $loginItemService.isEnabled)
            }

            Section {
                Picker("履歴の保存件数", selection: $selectedMaxItems) {
                    Text("50 件").tag(50)
                    Text("100 件").tag(100)
                    Text("500 件").tag(500)
                    Text("1000 件").tag(1000)
                    Text("2000 件").tag(2000)
                }
                .onChange(of: selectedMaxItems, initial: false) { (_, newValue: Int) in
                    clipboardManager.updateMaxItems(newValue)
                }
            } header: {
                Text("クリップボード履歴")
            } footer: {
                Text("上限を超えた古い履歴から自動的に削除されます。")
            }

            Section {
                if ignoredApps.isEmpty {
                    Text("除外するアプリケーションはありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(ignoredApps) { app in
                        HStack(spacing: 10) {
                            getAppIcon(from: app.bundleID)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .clipShape(.rect(cornerRadius: 5, style: .continuous))

                            Text(getAppName(from: app.bundleID))
                                .lineLimit(1)

                            Spacer()

                            Button(role: .destructive) {
                                removeIgnoredApp(app.bundleID)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("除外リストから削除")
                        }
                    }
                }

                Button(action: selectAppFromFinder) {
                    Label("アプリケーションを追加...", systemImage: "plus")
                }
            } header: {
                Text("監視から除外するアプリケーション")
            } footer: {
                Text("指定したアプリでコピーされた内容は履歴に記録されません。（パスワードマネージャー等は除外が推奨されます）")
            }

            Section("履歴の管理") {
                Button(role: .destructive) {
                    isShowingClearAlert = true
                } label: {
                    Label("すべての履歴を削除", systemImage: "trash")
                }
            }
        }
        .formStyle(.grouped)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .alert("履歴のクリア", isPresented: $isShowingClearAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                clipboardManager.clearHistory()
            }
        } message: {
            Text("すべてのコピー履歴が永久に削除されます。この操作は取り消せません。")
        }
        .onAppear {
            loadIgnoredApps()
        }
    }

    // 除外リストのロード
    private func loadIgnoredApps() {
        self.ignoredAppBundleIDs = UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.ignoredAppBundleIDs) ?? []
    }

    // ファインダーからアプリケーションを選択
    private func selectAppFromFinder() {
        let openPanel = NSOpenPanel()
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.applicationBundle, .application]
        openPanel.prompt = "選択"
        openPanel.title = "除外するアプリケーションの選択"

        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                if let bundleID = getBundleIdentifier(from: url) {
                    if !ignoredAppBundleIDs.contains(bundleID) {
                        ignoredAppBundleIDs.append(bundleID)
                        UserDefaults.standard.set(ignoredAppBundleIDs, forKey: UserDefaultsKeys.ignoredAppBundleIDs)
                    }
                }
            }
        }
    }

    // アプリの URL から Bundle ID を取得
    private func getBundleIdentifier(from appURL: URL) -> String? {
        if let bundle = Bundle(url: appURL), let bundleID = bundle.bundleIdentifier {
            return bundleID
        }
        let infoPlistURL = appURL.appendingPathComponent("Contents/Info.plist")
        if let infoDict = NSDictionary(contentsOf: infoPlistURL) as? [String: Any],
           let bundleID = infoDict["CFBundleIdentifier"] as? String {
            return bundleID
        }
        return nil
    }

    // 除外リストから削除
    private func removeIgnoredApp(_ bundleID: String) {
        ignoredAppBundleIDs.removeAll { $0 == bundleID }
        UserDefaults.standard.set(ignoredAppBundleIDs, forKey: UserDefaultsKeys.ignoredAppBundleIDs)
    }

    // デフォルト除外アプリの表示名マッピング（ClipboardManager のデフォルト除外リストと対応）
    private var presetAppNames: [String: String] {
        [
            "com.apple.passwords": "パスワード",
            "com.apple.keychainaccess": "キーチェーンアクセス"
        ]
    }

    // Bundle ID からアプリの表示名を取得
    private func getAppName(from bundleID: String) -> String {
        if let presetName = presetAppNames[bundleID] {
            return presetName.hasSuffix(".app") ? presetName : "\(presetName).app"
        }

        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return url.lastPathComponent
        }

        return bundleID.hasSuffix(".app") ? bundleID : "\(bundleID).app"
    }

    // Bundle ID からアプリのアイコンを取得
    private func getAppIcon(from bundleID: String) -> Image {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let nsImage = NSWorkspace.shared.icon(forFile: url.path)
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "app")
    }
}
