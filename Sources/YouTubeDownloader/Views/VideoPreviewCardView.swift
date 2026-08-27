import SwiftUI

public struct VideoPreviewCardView: View {
    public let metadata: VideoMetadata
    @Binding public var selectedQuality: QualityOption
    @Binding public var downloadDirectory: URL
    public let onStartDownload: () -> Void

    @State private var isHovering = false

    public init(
        metadata: VideoMetadata,
        selectedQuality: Binding<QualityOption>,
        downloadDirectory: Binding<URL>,
        onStartDownload: @escaping () -> Void
    ) {
        self.metadata = metadata
        self._selectedQuality = selectedQuality
        self._downloadDirectory = downloadDirectory
        self.onStartDownload = onStartDownload
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Main Metadata Row
            HStack(alignment: .top, spacing: 16) {
                // Thumbnail container
                ZStack(alignment: .bottomTrailing) {
                    if let thumb = metadata.thumbnail {
                        AsyncImage(url: thumb) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(
                                        ProgressView()
                                            .controlSize(.small)
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(16/9, contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 24))
                                            .foregroundColor(.secondary)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 220, height: 124)
                        .clipped()
                        .cornerRadius(10)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 220, height: 124)
                            .cornerRadius(10)
                    }

                    // Duration Badge
                    if metadata.duration > 0 {
                        Text(metadata.formattedDuration)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.75))
                            .cornerRadius(5)
                            .padding(6)
                    }
                }
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)

                // Info details
                VStack(alignment: .leading, spacing: 8) {
                    Text(metadata.title)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.secondary)
                        Text(metadata.channel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)

                        if !metadata.formattedViews.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(metadata.formattedViews)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Available Max Resolution Badges
                    HStack(spacing: 6) {
                        if metadata.availableHeights.contains(where: { $0 >= 2160 }) {
                            BadgeView(text: "4K UHD", color: .pink)
                        } else if metadata.availableHeights.contains(where: { $0 >= 1440 }) {
                            BadgeView(text: "2K QHD", color: .indigo)
                        } else if metadata.availableHeights.contains(where: { $0 >= 1080 }) {
                            BadgeView(text: "1080p FHD", color: .blue)
                        } else {
                            BadgeView(text: "HD", color: .teal)
                        }

                        BadgeView(text: "Video + Audio Mux", color: .purple)
                    }
                    .padding(.top, 2)
                }

                Spacer()
            }

            Divider()
                .opacity(0.6)

            // Quality Selection Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Select Download Format & Quality:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(QualityOption.allCases) { option in
                            QualityPill(
                                option: option,
                                isSelected: selectedQuality == option,
                                isAvailable: isOptionAvailable(option),
                                onSelect: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedQuality = option
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Destination Folder & Action
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Save to:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))
                        Text(downloadDirectory.lastPathComponent)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)

                        Button(action: selectFolder) {
                            Text("Change...")
                                .font(.system(size: 11))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                Button(action: onStartDownload) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16))
                        Text(selectedQuality == .maxQuality ? "Download Highest Quality" : "Download (\(selectedQuality.shortTitle))")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple, Color.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 4)
                    .scaleEffect(isHovering ? 1.02 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovering = hovering
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
    }

    private func isOptionAvailable(_ option: QualityOption) -> Bool {
        switch option {
        case .maxQuality, .audioMp3, .audioM4a:
            return true
        case .uhd4k:
            return metadata.availableHeights.contains { $0 >= 2160 }
        case .qhd1440:
            return metadata.availableHeights.contains { $0 >= 1440 }
        case .fhd1080:
            return metadata.availableHeights.contains { $0 >= 1080 }
        case .hd720:
            return metadata.availableHeights.contains { $0 >= 720 }
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select Download Folder"

        if panel.runModal() == .OK, let url = panel.url {
            downloadDirectory = url
        }
    }
}

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }
}

struct QualityPill: View {
    let option: QualityOption
    let isSelected: Bool
    let isAvailable: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.system(size: 11))

                VStack(alignment: .leading, spacing: 1) {
                    Text(option.shortTitle)
                        .font(.system(size: 12, weight: .bold))
                    Text(option.isAudioOnly ? "Audio" : "Video")
                        .font(.system(size: 9))
                        .opacity(0.8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.85) : Color(nsColor: .controlColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 1.5)
                    )
            )
            .foregroundColor(isSelected ? .white : (isAvailable ? .primary : .secondary))
            .opacity(isAvailable ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
    }
}
