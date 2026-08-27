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
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                        Text(downloadDirectory.lastPathComponent)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)

                        Button(action: selectFolder) {
                            Text("Change...")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.85))
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                Button(action: onStartDownload) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 15))
                        Text(selectedQuality == .maxQuality ? "Download Highest Quality" : "Download (\(selectedQuality.shortTitle))")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.18, green: 0.18, blue: 0.20))
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private func isOptionAvailable(_ option: QualityOption) -> Bool {
        switch option {
        case .maxQuality, .audioMp3, .thumbnail:
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
                    Text(option.typeLabel)
                        .font(.system(size: 9))
                        .opacity(isSelected ? 0.75 : 0.8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.white : Color(nsColor: .controlColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? Color.black : (isAvailable ? .primary : .secondary))
            .shadow(color: isSelected ? Color.black.opacity(0.12) : Color.clear, radius: 4, x: 0, y: 2)
            .opacity(isAvailable ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
    }
}
