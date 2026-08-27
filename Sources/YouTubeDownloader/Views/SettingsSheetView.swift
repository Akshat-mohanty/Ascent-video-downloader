import SwiftUI
import AppKit

public struct SettingsSheetView: View {
    @Binding public var downloadDirectory: URL
    @Environment(\.dismiss) private var dismiss

    public init(downloadDirectory: Binding<URL>) {
        self._downloadDirectory = downloadDirectory
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                Text("Preferences")
                    .font(.system(size: 16, weight: .bold))
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
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))

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
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }

            Spacer()
        }
        .padding(22)
        .frame(width: 440, height: 180)
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
