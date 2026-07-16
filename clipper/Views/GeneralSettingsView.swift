import SwiftUI

struct GeneralSettingsView<Manager: ClipboardManaging & ObservableObject>: View {
    @ObservedObject var clipboardManager: Manager
    @StateObject private var loginItemService = LoginItemService.shared
    @State private var selectedMaxItems: Int
    @State private var isShowingClearAlert = false
    
    init(clipboardManager: Manager) {
        self.clipboardManager = clipboardManager
        _selectedMaxItems = State(initialValue: clipboardManager.maxItems)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle("ログイン時に起動", isOn: $loginItemService.isEnabled)
                .font(.system(size: 12))
                .padding(.vertical, 2)
            
            Divider()
                .padding(.vertical, 4)
            
            Text("履歴の最大保存件数を指定します。上限を超えた古い履歴から自動的に削除されます。")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Picker("履歴の保存件数:", selection: $selectedMaxItems) {
                Text("50 件").tag(50)
                Text("100 件").tag(100)
                Text("500 件").tag(500)
                Text("1000 件").tag(1000)
                Text("2000 件").tag(2000)
            }
            .pickerStyle(.menu)
            .onChange(of: selectedMaxItems, initial: false) { (oldValue: Int, newValue: Int) in
                clipboardManager.updateMaxItems(newValue)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("履歴の管理:")
                    .font(.system(size: 12, weight: .bold))
                Button(action: {
                    isShowingClearAlert = true
                }) {
                    Label("すべての履歴を削除", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.15))
            }
        }
        .alert("履歴のクリア", isPresented: $isShowingClearAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                clipboardManager.clearHistory()
            }
        } message: {
            Text("すべてのコピー履歴が永久に削除されます。この操作は取り消せません。")
        }
    }
}
