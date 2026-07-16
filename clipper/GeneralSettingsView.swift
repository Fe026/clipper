import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @State private var selectedMaxItems: Int
    
    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
        _selectedMaxItems = State(initialValue: clipboardManager.maxItems)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                    clipboardManager.clearHistory()
                }) {
                    Label("すべての履歴を削除", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.15))
            }
        }
    }
}
