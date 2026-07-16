import SwiftUI

struct SidebarView: View {
    @Binding var activeTab: SettingsTab
    @Binding var hoveredTab: SettingsTab?
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 信号ボタンのためのスペース（fullSizeContentView のため）
            Spacer().frame(height: 30)
            
            ForEach(SettingsTab.allCases.filter { $0 != .about }) { tab in
                tabButton(for: tab)
            }
            
            Spacer()
            
            if let aboutTab = SettingsTab.allCases.first(where: { $0 == .about }) {
                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                tabButton(for: aboutTab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .frame(width: 160)
    }
    
    @ViewBuilder
    private func tabButton(for tab: SettingsTab) -> some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.15)) {
                activeTab = tab
            }
        }) {
            HStack(spacing: 8) {
                if tab != .about {
                    Image(systemName: tab.icon)
                        .font(.system(size: 13))
                        .foregroundColor(activeTab == tab ? .primary : (hoveredTab == tab ? .primary : .secondary))
                }
                Text(tab.displayName)
                    .font(.system(size: 12, weight: activeTab == tab ? .medium : .regular))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            Group {
                let isDark = colorScheme == .dark
                if activeTab == tab {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ColorTheme.settingsSidebarActiveBg(isDark: isDark))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ColorTheme.settingsSidebarActiveBorder(isDark: isDark), lineWidth: 0.5)
                        )
                        .shadow(color: ColorTheme.settingsSidebarActiveShadow(isDark: isDark), radius: 3, x: 0, y: 1.5)
                } else if hoveredTab == tab {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ColorTheme.settingsSidebarHoverBg(isDark: isDark))
                } else {
                    Color.clear
                }
            }
        )
        .onHover { isHovered in
            hoveredTab = isHovered ? tab : nil
        }
    }
}
