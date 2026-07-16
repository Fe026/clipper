import Foundation

/// UserDefaults で使用されるキーの一覧
enum UserDefaultsKeys {
    /// 履歴の最大保存件数 (Int)
    static let maxItems = "max_items"
    
    /// クリップボードの保存履歴データ (Data)
    static let clipboardHistory = "clipboard_history"
    
    /// ホットキーのタイプ (String, "double_tap" または "shortcut")
    static let hotkeyType = "hotkey_type"
    
    /// ダブルタップ起動で使用する修飾キー (String, "Command" など)
    static let modifierKey = "modifier_key"
    
    /// ショートカットキーで設定された修飾キーのフラグ値 (Int)
    static let shortcutModifiers = "shortcut_modifiers"
    
    /// ショートカットキーで設定されたキーコード値 (Int)
    static let shortcutKeyCode = "shortcut_keycode"
    
    /// ショートカットキーの表示用文字列 (String, "⌥Space" など)
    static let shortcutDisplayString = "shortcut_display_string"
}
