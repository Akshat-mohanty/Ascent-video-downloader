import SwiftUI
import AppKit

public struct DownloadProgressView: View {
    public let task: DownloadTask
    public let onCancel: () -> Void
    public let onReset: () -> Void

    @State private var shimmerOffset: CGFloat = -200

    public init(
        task: DownloadTask,
        onCancel: @escaping () -> Void,
        onReset: @escaping () -> Void
    ) {
        self.task = task
        self.onCancel = onCancel
        self.onReset = onReset
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Top Row: Thumbnail/Icon + Title + Percentage
            HStack(alignment: .top, spacing: 14) {
                // Thumbnail or Video Glyph
                ZStack {
                    if let thumb = task.metadata?.thumbnail {
                        AsyncImage(url: thumb) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(16/9, contentMode: .fill)
                            } else {
                                Color.primary.opacity(0.06)
                            }
                        }
                    } else {
                        Color.primary.opacity(0.06)
                    }
                }
                .frame(width: 88, height: 52)
                .cornerRadius(8)
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // Title & Channel
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.displayTitle)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text(task.quality.shortTitle)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(4)

                        Text(task.displayChannel)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Percentage / Status Indicator
                VStack(alignment: .trailing, spacing: 2) {
                    if task.status == .completed {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Complete")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.green)
                        }
                    } else if task.status == .failed {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Failed")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.red)
                        }
                    } else if task.status == .merging {
                        Text("FFmpeg Mux")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.purple)
                    } else {
                        Text("\(Int(task.progress * 100))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
            }

            // Linear Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background Track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 8)

                        // Active Fill
                        if task.status == .completed {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green)
                                .frame(width: geometry.size.width, height: 8)
                        } else if task.status == .failed {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: geometry.size.width, height: 8)
                        } else {
                            let progressWidth = max(8, geometry.size.width * CGFloat(task.progress))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .shadow(color: Color.white.opacity(0.35), radius: 3, x: 0, y: 0)
                                .frame(width: progressWidth, height: 8)
                                .animation(.linear(duration: 0.25), value: task.progress)
                        }
                    }
                }
                .frame(height: 8)

                // Subtitle Row: Status text + ETA
                HStack {
                    Text(statusDescription)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    if task.status.isActive && !task.eta.isEmpty && task.eta != "--" {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("ETA \(task.eta)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }

            // Stats Metrics Row
            if task.status.isActive {
                HStack(spacing: 16) {
                    MetricChip(
                        icon: "bolt.fill",
                        label: "Speed",
                        value: task.downloadSpeed.isEmpty ? "--" : task.downloadSpeed
                    )

                    MetricChip(
                        icon: "internaldrive.fill",
                        label: "Downloaded",
                        value: task.totalSize.isEmpty ? "--" : (task.downloadedSize.isEmpty ? task.totalSize : "\(task.downloadedSize) / \(task.totalSize)")
                    )

                    MetricChip(
                        icon: "film.fill",
                        label: "Resolution",
                        value: task.quality.shortTitle
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.03))
                )
            }

            // Error banner if failed
            if let error = task.errorMessage, task.status == .failed {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            Divider()
                .opacity(0.5)

            // Action Buttons Row
            HStack(spacing: 12) {
                if task.status.isActive {
                    Button(action: onCancel) {
                        HStack(spacing: 5) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                            Text("Cancel Download")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                } else if task.status == .completed {
                    if let fileURL = task.destinationFileURL, FileManager.default.fileExists(atPath: fileURL.path) {
                        Button(action: {
                            NSWorkspace.shared.open(fileURL)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                Text("Play Video")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(red: 0.18, green: 0.18, blue: 0.20))
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "folder")
                                Text("Show in Finder")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button(action: onReset) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Download Another")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Failed or cancelled
                    Button(action: onReset) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Try Again")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
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

    private var statusDescription: String {
        switch task.status {
        case .idle:
            return "Ready"
        case .fetchingInfo:
            return "Fetching video details..."
        case .downloading:
            return task.progress >= 0.99 ? "Finalizing streams..." : "Downloading video + audio streams..."
        case .merging:
            return "Merging video & audio losslessly with FFmpeg..."
        case .completed:
            return "Download & merge complete!"
        case .failed:
            return "Download interrupted"
        case .cancelled:
            return "Download cancelled"
        }
    }
}

struct MetricChip: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Text("\(label):")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}
