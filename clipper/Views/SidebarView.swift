import SwiftUI

struct SidebarView: View {
    @Binding var activeTab: SettingsTab

    private var selectionBinding: Binding<SettingsTab?> {
        Binding(
            get: { activeTab },
            set: { newValue in
                if let newValue {
                    activeTab = newValue
                }
            }
        )
    }

    var body: some View {
        List(selection: selectionBinding) {
            Section {
                ForEach(SettingsTab.primaryTabs) { tab in
                    Label(tab.displayName, systemImage: tab.icon)
                        .tag(tab)
                }
            }

            Section {
                Label(SettingsTab.about.displayName, systemImage: SettingsTab.about.icon)
                    .tag(SettingsTab.about)
            }
        }
        .listStyle(.sidebar)
    }
}
