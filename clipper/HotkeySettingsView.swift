import SwiftUI

struct HotkeySettingsView: View {
    @AppStorage(UserDefaultsKeys.hotkeyType) private var hotkeyType: String = HotkeyTypeOption.doubleTap.rawValue
    @AppStorage(UserDefaultsKeys.modifierKey) private var modifierKey: String = ModifierKeyOption.command.rawValue
    @AppStorage(UserDefaultsKeys.shortcutDisplayString) private var displayString: String = "⌘V"
    @AppStorage(UserDefaultsKeys.isRecordingShortcut) private var isRecording: Bool = false
    
    @Binding var modifierFlags: NSEvent.ModifierFlags
    @Binding var keyCode: UInt16
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("履歴パネルを表示するためのキーボード操作を設定します。設定中（入力待ち）はホットキーが無効化されます。")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Picker("起動タイプ:", selection: $hotkeyType) {
                ForEach(HotkeyTypeOption.allCases) { option in
                    Text(option.displayName).tag(option.rawValue)
                }
            }
            .pickerStyle(.menu)
            
            if hotkeyType == HotkeyTypeOption.doubleTap.rawValue {
                Picker("修飾キー (ダブルタップ):", selection: $modifierKey) {
                    ForEach(ModifierKeyOption.allCases) { option in
                        Text(option.rawValue).tag(option.rawValue)
                    }
                }
                .pickerStyle(.menu)
            } else {
                HStack(spacing: 8) {
                    Text("ショートカットキー:")
                    ShortcutRecorder(
                        modifierFlags: $modifierFlags,
                        keyCode: $keyCode,
                        displayString: $displayString,
                        isRecording: $isRecording
                    )
                    .frame(width: 160, height: 26)
                    .onChange(of: modifierFlags, initial: false) { (oldValue: NSEvent.ModifierFlags, newValue: NSEvent.ModifierFlags) in
                        UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultsKeys.shortcutModifiers)
                    }
                    .onChange(of: keyCode, initial: false) { (oldValue: UInt16, newValue: UInt16) in
                        UserDefaults.standard.set(Int(newValue), forKey: UserDefaultsKeys.shortcutKeyCode)
                    }
                }
            }
        }
    }
}
