import SwiftUI
import AppKit

public struct SettingsSheetView: View {
    @Binding public var downloadDirectory: URL
    @Environment(\.dismiss) private var dismiss

    @State private var ytDlpPath: String = BinaryResolver.shared.resolveYtDlp() ?? ""
    @State private var ffmpegPath: String = BinaryResolver.shared.resolveFfmpeg() ?? ""
    @State private var customYtDlp: String = BinaryResolver.shared.customYtDlpPath ?? ""
    @State private var customFfmpeg: String = BinaryResolver.shared.customFfmpegPath ?? ""

    public init(downloadDirectory: Binding<URL>) {
        self._downloadDirectory = downloadDirectory
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Preferences")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }

            Divider()

            // Download Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Default Download Folder")
                    .font(.system(size: 13, weight: .semibold))

                HStack {
                    Text(downloadDirectory.path)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("Change...") {
                        chooseFolder()
                    }
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }

            // Binary Dependencies
            VStack(alignment: .leading, spacing: 12) {
                Text("Engine & Merger Binaries")
                    .font(.system(size: 13, weight: .semibold))

                // yt-dlp
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: ytDlpPath.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(ytDlpPath.isEmpty ? .red : .green)
                        Text("yt-dlp Engine:")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        if ytDlpPath.isEmpty {
                            Text("Not Found")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red)
                        } else {
                            Text("Active")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }

                    Text(ytDlpPath.isEmpty ? "Install via Homebrew: brew install yt-dlp" : ytDlpPath)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)

                // ffmpeg
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: ffmpegPath.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(ffmpegPath.isEmpty ? .red : .green)
                        Text("FFmpeg Merger:")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        if ffmpegPath.isEmpty {
                            Text("Not Found")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red)
                        } else {
                            Text("Active")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }

                    Text(ffmpegPath.isEmpty ? "Install via Homebrew: brew install ffmpeg" : ffmpegPath)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 480, height: 380)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            downloadDirectory = url
            UserDefaults.standard.set(url.path, forKey: "default_download_dir")
        }
    }
}
