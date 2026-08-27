import SwiftUI
import AppKit

public struct HistoryListView: View {
    @ObservedObject private var historyStore = HistoryStore.shared
    @State private var hoveredTaskId: UUID? = nil

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("Download History")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                if !historyStore.items.isEmpty {
                    Button(action: {
                        withAnimation {
                            historyStore.clearAll()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Clear All")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(nsColor: .controlColor))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            if historyStore.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No downloads yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("Paste a YouTube link above to start downloading in highest quality.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(historyStore.items) { task in
                            HistoryItemRow(task: task, isHovered: hoveredTaskId == task.id) {
                                withAnimation {
                                    historyStore.removeTask(id: task.id)
                                }
                            }
                            .onHover { hovering in
                                hoveredTaskId = hovering ? task.id : nil
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 280)
            }
        }
    }
}

struct HistoryItemRow: View {
    let task: DownloadTask
    let isHovered: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                if let thumb = task.metadata?.thumbnail {
                    AsyncImage(url: thumb) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 80, height: 48)
            .cornerRadius(6)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(task.displayTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text(task.quality.shortTitle)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)

                    Text(task.displayChannel)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if !task.totalSize.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(task.totalSize)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                if let fileURL = task.destinationFileURL, FileManager.default.fileExists(atPath: fileURL.path) {
                    Button(action: {
                        NSWorkspace.shared.open(fileURL)
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Play Video")

                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                    }) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Show in Finder")
                } else {
                    Text("File moved")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove from history")
            }
            .opacity(isHovered ? 1.0 : 0.7)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(isHovered ? 0.9 : 0.6))
        )
    }
}
