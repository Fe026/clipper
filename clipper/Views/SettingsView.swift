import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "general"
    case hotkey = "hotkey"
    case updates = "updates"
    case about = "about"

    static let primaryTabs: [SettingsTab] = [.general, .hotkey, .updates]

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
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    init(clipboardManager: Manager) {
        self.clipboardManager = clipboardManager
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(activeTab: $activeTab)
                .navigationSplitViewColumnWidth(
                    min: LayoutMetrics.settingsSidebarMinWidth,
                    ideal: LayoutMetrics.settingsSidebarIdealWidth,
                    max: LayoutMetrics.settingsSidebarMaxWidth
                )
                .toolbar(removing: .sidebarToggle)
        } detail: {
            detailContent
                .navigationTitle(activeTab.displayName)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(
            minWidth: LayoutMetrics.settingsWindowWidth,
            idealWidth: LayoutMetrics.settingsWindowWidth,
            minHeight: LayoutMetrics.settingsWindowHeight,
            idealHeight: LayoutMetrics.settingsWindowHeight
        )
    }

    @ViewBuilder
    private var detailContent: some View {
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
}
