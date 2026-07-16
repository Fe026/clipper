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

struct SettingsView<Manager: ClipboardManaging & ObservableObject>: View {
    @ObservedObject var clipboardManager: Manager
    
    @State private var activeTab: SettingsTab = .general
    @State private var hoveredTab: SettingsTab? = nil
    
    init(clipboardManager: Manager) {
        self.clipboardManager = clipboardManager
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 1. サイドバー (左ペイン)
            SidebarView(activeTab: $activeTab, hoveredTab: $hoveredTab)
                .applyGlassEffect(in: .rect(cornerRadius: 12), displayMode: .thick)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ColorTheme.settingsSidebarBg)
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
                            HotkeySettingsView()
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
