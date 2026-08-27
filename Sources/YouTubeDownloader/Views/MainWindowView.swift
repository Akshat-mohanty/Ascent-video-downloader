import SwiftUI
import UserNotifications

public struct MainWindowView: View {
    @State private var urlInput: String = ""
    @State private var isFetchingMetadata: Bool = false
    @State private var currentMetadata: VideoMetadata? = nil
    @State private var selectedQuality: QualityOption = .maxQuality
    @State private var currentDownloadTask: DownloadTask? = nil
    @State private var downloadDirectory: URL = MainWindowView.defaultDownloadDirectory()
    @State private var selectedTab: Int = 0 // 0: Downloader, 1: History
    @State private var showSettings: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false

    @ObservedObject private var historyStore = HistoryStore.shared

    public init() {}

    public var body: some View {
        ZStack {
            // Aesthetic dynamic background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.06),
                    Color(nsColor: .windowBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top App Bar
                HStack(spacing: 14) {
                    // App Brand
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.red.opacity(0.4), radius: 6, x: 0, y: 2)

                            Image(systemName: "arrow.down")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 6) {
                                Text("AetherTube")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundColor(.primary)

                                Text("PRO")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(4)
                            }

                            Text("Max Quality Video & Audio Downloader")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Tab Segment
                    Picker("", selection: $selectedTab) {
                        Text("Download").tag(0)
                        Text("History (\(historyStore.items.count))").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)

                    // Settings Button
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(nsColor: .controlColor).opacity(0.5))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .help("Preferences")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)

                Divider()
                    .opacity(0.4)

                // Body content
                ScrollView {
                    VStack(spacing: 22) {
                        if selectedTab == 0 {
                            // URL Input Bar
                            URLInputView(
                                urlText: $urlInput,
                                isLoading: isFetchingMetadata,
                                onFetch: { fetchVideoInfo() },
                                onPasteAndFetch: { fetchVideoInfo() }
                            )

                            // Active Download Progress or Video Preview
                            if let task = currentDownloadTask {
                                DownloadProgressView(
                                    task: task,
                                    onCancel: { cancelDownload() },
                                    onReset: { resetState() }
                                )
                                .transition(.scale.combined(with: .opacity))
                            } else if let metadata = currentMetadata {
                                VideoPreviewCardView(
                                    metadata: metadata,
                                    selectedQuality: $selectedQuality,
                                    downloadDirectory: $downloadDirectory,
                                    onStartDownload: { startDownload() }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            } else {
                                // Default landing hero
                                LandingHeroView()
                                    .padding(.top, 10)
                            }
                        } else {
                            // History Tab
                            HistoryListView()
                                .padding(.top, 10)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 560)
        .sheet(isPresented: $showSettings) {
            SettingsSheetView(downloadDirectory: $downloadDirectory)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unexpected error occurred.")
        }
    }

    private static func defaultDownloadDirectory() -> URL {
        if let saved = UserDefaults.standard.string(forKey: "default_download_dir"), !saved.isEmpty {
            return URL(fileURLWithPath: saved)
        }
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        return downloads ?? URL(fileURLWithPath: NSHomeDirectory())
    }

    private func fetchVideoInfo() {
        let trimmed = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isFetchingMetadata = true
        currentMetadata = nil
        currentDownloadTask = nil

        Task {
            do {
                let metadata = try await YtDlpService.shared.fetchMetadata(for: trimmed)
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        self.currentMetadata = metadata
                        self.isFetchingMetadata = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isFetchingMetadata = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }

    private func startDownload() {
        guard let metadata = currentMetadata else { return }

        let taskID = UUID()
        let task = DownloadTask(
            id: taskID,
            url: urlInput,
            metadata: metadata,
            quality: selectedQuality,
            status: .downloading,
            progress: 0.01,
            downloadSpeed: "Connecting...",
            eta: "--",
            downloadedSize: "",
            totalSize: "",
            createdAt: Date()
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.currentDownloadTask = task
        }

        YtDlpService.shared.download(
            taskID: taskID,
            url: urlInput,
            quality: selectedQuality,
            outputDirectory: downloadDirectory,
            onProgress: { update in
                guard var current = self.currentDownloadTask, current.id == taskID else { return }
                current.progress = update.progress
                current.downloadSpeed = update.speed
                current.eta = update.eta
                current.downloadedSize = update.downloadedSize
                current.totalSize = update.totalSize
                self.currentDownloadTask = current
            },
            onStatusChange: { status in
                guard var current = self.currentDownloadTask, current.id == taskID else { return }
                current.status = status
                self.currentDownloadTask = current
            },
            completion: { result in
                guard var current = self.currentDownloadTask, current.id == taskID else { return }
                switch result {
                case .success(let fileURL):
                    current.status = .completed
                    current.progress = 1.0
                    current.destinationPath = fileURL.path
                    current.completedAt = Date()
                    self.currentDownloadTask = current
                    HistoryStore.shared.addTask(current)
                    self.sendNotification(title: "Download Complete!", body: "\(metadata.title) has finished downloading.")
                case .failure(let error):
                    current.status = .failed
                    current.errorMessage = error.localizedDescription
                    self.currentDownloadTask = current
                }
            }
        )
    }

    private func cancelDownload() {
        if let current = currentDownloadTask {
            YtDlpService.shared.cancel(taskID: current.id)
            var cancelled = current
            cancelled.status = .cancelled
            self.currentDownloadTask = cancelled
        }
    }

    private func resetState() {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.currentDownloadTask = nil
            self.currentMetadata = nil
            self.urlInput = ""
        }
    }

    private func sendNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default

                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                center.add(request)
            }
        }
    }
}

struct LandingHeroView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 30)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.25), Color.blue.opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 130, height: 130)

                Image(systemName: "arrow.down.to.line.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 6) {
                Text("Ready to Download")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)

                Text("Paste any YouTube video or shorts link above to get started.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                StepChip(num: "1", text: "Copy link")
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary.opacity(0.4))
                    .font(.system(size: 10))
                StepChip(num: "2", text: "Inspect & choose quality")
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary.opacity(0.4))
                    .font(.system(size: 10))
                StepChip(num: "3", text: "Download in 4K/1080p")
            }
            .padding(.top, 8)

            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct StepChip: View {
    let num: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Text(num)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.blue))

            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlColor).opacity(0.6))
        .cornerRadius(20)
    }
}
