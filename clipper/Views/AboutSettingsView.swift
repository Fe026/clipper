import AppKit
import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section {
                VStack(spacing: 10) {
                    appIconView
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)

                    Text("Clipper")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(AppVersionProvider.currentVersionFormatted)
                        .font(.caption.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section {
                LabeledContent("バージョン") {
                    Text(AppVersionProvider.currentVersion)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                if let url = AppConstants.URLs.gitHubRepo {
                    LabeledContent("リポジトリ") {
                        Link("Fe026/clipper", destination: url)
                    }
                }

                LabeledContent("ライセンス") {
                    Text("MIT License")
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Copyright © 2026 Fe. All rights reserved.")
            }
        }
        .formStyle(.grouped)
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    @ViewBuilder
    private var appIconView: some View {
        if let nsImage = NSImage(named: "AppIcon") {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.blue, Color(red: 0.2, green: 0.5, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 72, height: 72)

                Image(systemName: "book.pages")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }
}
