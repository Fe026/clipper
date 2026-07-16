import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 8)
            
            // アプリアイコン
            Group {
                if let nsImage = NSImage(named: "AppIcon") {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                } else {
                    // フォールバック（アセットが見つからない場合）
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.blue, Color(red: 0.2, green: 0.5, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: "book.pages")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
            
            // アプリ名
            Text("Clipper")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 6) {
                // レポジトリ
                HStack(spacing: 4) {
                    Text("リポジトリ:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    if let url = AppConstants.URLs.gitHubRepo {
                        Link(destination: url) {
                            Text("Fe026/clipper")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // バージョン
                HStack(spacing: 4) {
                    Text("バージョン:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(AppVersionProvider.currentVersion)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            // コピーライト
            Text("Copyright © 2026 Fe. All rights reserved.")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}
