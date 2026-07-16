import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "general"
    case hotkey = "hotkey"
    case updates = "updates"
    case about = "about"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .general: return "一般"
        case .hotkey: return "起動設定"
        case .updates: return "更新"
        case .about: return "このアプリについて"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "slider.horizontal.3"
        case .hotkey: return "keyboard"
        case .updates: return "arrow.clockwise.circle"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    
    @State private var modifierFlags: NSEvent.ModifierFlags = .command
    @State private var keyCode: UInt16 = 9
    
    @State private var activeTab: SettingsTab = .general
    @State private var hoveredTab: SettingsTab? = nil
    
    @Environment(\.colorScheme) var colorScheme
    
    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
        
        let savedModifiersRaw = UserDefaults.standard.integer(forKey: UserDefaultsKeys.shortcutModifiers)
        let savedModifiers = NSEvent.ModifierFlags(rawValue: UInt(savedModifiersRaw))
        let savedKeyCode = UInt16(UserDefaults.standard.integer(forKey: UserDefaultsKeys.shortcutKeyCode))
        
        let modifier = savedModifiersRaw == 0 ? .command : savedModifiers
        let code = savedModifiersRaw == 0 && savedKeyCode == 0 ? UInt16(9) : savedKeyCode
        
        _modifierFlags = State(initialValue: modifier)
        _keyCode = State(initialValue: code)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 1. サイドバー (左ペイン)
            SidebarView(activeTab: $activeTab, hoveredTab: $hoveredTab, colorScheme: colorScheme)
                .applyGlassEffect(in: .rect(cornerRadius: 12), displayMode: .thick)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.15) : Color.black.opacity(0.03))
                )
                .padding([.top, .bottom, .leading], 8)
            
            // 2. 詳細コンテンツ (右ペイン)
            VStack(alignment: .leading, spacing: 0) {
                // 上部ヘッダー（ドラッグ可能領域、タイトルを表示）
                HStack {
                    Text(activeTab.displayName)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Spacer()
                }
                .padding(.top, 14)
                .padding(.bottom, 12)
                .padding(.horizontal, 16)
                .frame(height: 48)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        switch activeTab {
                        case .general:
                            GeneralSettingsView(clipboardManager: clipboardManager)
                        case .hotkey:
                            HotkeySettingsView(modifierFlags: $modifierFlags, keyCode: $keyCode)
                        case .updates:
                            UpdateSettingsView()
                        case .about:
                            AboutSettingsView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 500, idealWidth: 500, maxWidth: .infinity, minHeight: 340, idealHeight: 340, maxHeight: .infinity)
        .applyGlassEffect(in: .rect(cornerRadius: 0), displayMode: .thin)
        .ignoresSafeArea(.container, edges: .top)
    }
}
