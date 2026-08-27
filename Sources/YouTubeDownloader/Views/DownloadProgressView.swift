import SwiftUI
import AppKit

public struct DownloadProgressView: View {
    public let task: DownloadTask
    public let onCancel: () -> Void
    public let onReset: () -> Void

    @State private var isPulsing = false
    @State private var rotationAngle: Double = 0

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
        VStack(spacing: 24) {
            // Header: Title & Status
            VStack(spacing: 6) {
                Text(task.displayTitle)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    if task.status == .merging {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.purple)
                            .rotationEffect(.degrees(rotationAngle))
                            .onAppear {
                                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                                    rotationAngle = 360
                                }
                            }
                    } else if task.status == .downloading {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.blue)
                    } else if task.status == .completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if task.status == .failed {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }

                    Text(task.status.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // Central Animated Progress Ring
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                    .frame(width: 140, height: 140)

                // Foreground Progress Arc
                if task.status == .downloading || task.status == .merging {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(max(task.progress, 0.02)))
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [Color.blue, Color.cyan, Color.purple, Color.blue]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 140, height: 140)
                        .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 0)
                        .animation(.linear(duration: 0.2), value: task.progress)
                } else if task.status == .completed {
                    Circle()
                        .stroke(Color.green, lineWidth: 12)
                        .frame(width: 140, height: 140)
                        .shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 0)
                } else if task.status == .failed {
                    Circle()
                        .stroke(Color.red, lineWidth: 12)
                        .frame(width: 140, height: 140)
                }

                // Center Icon / Percentage
                VStack(spacing: 2) {
                    if task.status == .completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.green)
                            .scaleEffect(isPulsing ? 1.05 : 0.95)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                    isPulsing = true
                                }
                            }
                    } else if task.status == .failed {
                        Image(systemName: "xmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.red)
                    } else if task.status == .merging {
                        Image(systemName: "film.stack.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.purple)
                        Text("FFmpeg Mux")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.purple)
                    } else {
                        Text("\(Int(task.progress * 100))%")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.primary)

                        if !task.eta.isEmpty && task.eta != "--" {
                            Text("ETA \(task.eta)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Metrics Bar
            if task.status == .downloading || task.status == .merging {
                HStack(spacing: 20) {
                    MetricBadge(title: "Speed", value: task.downloadSpeed.isEmpty ? "--" : task.downloadSpeed, icon: "bolt.fill")
                    MetricBadge(title: "Size", value: task.totalSize.isEmpty ? "--" : (task.downloadedSize.isEmpty ? task.totalSize : "\(task.downloadedSize) / \(task.totalSize)"), icon: "cylinder.fill")
                    MetricBadge(title: "Format", value: task.quality.shortTitle, icon: task.quality.icon)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlColor).opacity(0.6))
                .cornerRadius(12)
            }

            // Error banner if failed
            if let error = task.errorMessage, task.status == .failed {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
                .padding(10)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            // Action Buttons
            HStack(spacing: 14) {
                if task.status.isActive {
                    Button(action: onCancel) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.circle.fill")
                            Text("Cancel Download")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(10)
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
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "folder")
                                Text("Show in Finder")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color(nsColor: .controlColor))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: onReset) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle")
                            Text("Download Another")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Color.cyan.opacity(0.15))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Failed or cancelled
                    Button(action: onReset) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Try Again")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Color(nsColor: .controlColor))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
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
}

struct MetricBadge: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }
}
