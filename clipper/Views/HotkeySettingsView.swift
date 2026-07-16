import SwiftUI

struct HotkeySettingsView: View {
    @AppStorage(UserDefaultsKeys.hotkeyType) private var hotkeyType: String = HotkeyTypeOption.doubleTap.rawValue
    @AppStorage(UserDefaultsKeys.modifierKey) private var modifierKey: String = ModifierKeyOption.command.rawValue
    @AppStorage(UserDefaultsKeys.shortcutDisplayString) private var displayString: String = "⌘⇧V"
    @AppStorage(UserDefaultsKeys.shortcutModifiers) private var shortcutModifiersRaw: Int = 0
    @AppStorage(UserDefaultsKeys.shortcutKeyCode) private var shortcutKeyCodeRaw: Int = 0
    
    @State private var isRecording: Bool = false
    
    private var modifierFlagsBinding: Binding<NSEvent.ModifierFlags> {
        Binding(
            get: {
                if shortcutModifiersRaw == 0 {
                    return [.command, .shift]
                } else {
                    return NSEvent.ModifierFlags(rawValue: UInt(shortcutModifiersRaw))
                }
            },
            set: { shortcutModifiersRaw = Int($0.rawValue) }
        )
    }
    
    private var keyCodeBinding: Binding<UInt16> {
        Binding(
            get: {
                if shortcutModifiersRaw == 0 && shortcutKeyCodeRaw == 0 {
                    return 9
                } else {
                    return UInt16(shortcutKeyCodeRaw)
                }
            },
            set: { shortcutKeyCodeRaw = Int($0) }
        )
    }
    
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
                        modifierFlags: modifierFlagsBinding,
                        keyCode: keyCodeBinding,
                        displayString: $displayString,
                        isRecording: $isRecording
                    )
                    .frame(width: 160, height: 26)
                }
            }
        }
        .onChange(of: isRecording, initial: false) { (oldValue: Bool, newValue: Bool) in
            NotificationCenter.default.post(
                name: .clipperIsRecordingShortcutDidChange,
                object: nil,
                userInfo: ["isRecording": newValue]
            )
        }
    }
}
