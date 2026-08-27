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
            // Elegant Warm Ivory Backdrop (Adaptive for Light/Dark Mode)
            Color(nsColor: .windowBackgroundColor)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(0.015),
                            Color.clear,
                            Color.primary.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Floating Navbar
                HStack {
                    // Logo & Brand
                    HStack(spacing: 9) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                                .frame(width: 28, height: 28)

                            Text("A")
                                .font(.system(size: 15, weight: .black, design: .serif))
                                .foregroundColor(.white)
                        }

                        Text("Ascent")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    // Tab Segment
                    Picker("", selection: $selectedTab) {
                        Text("Download").tag(0)
                        Text("History (\(historyStore.items.count))").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)

                    // Settings Button
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Preferences")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Rectangle()
                        .fill(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.primary.opacity(0.06)),
                            alignment: .bottom
                        )
                )

                // Main Scrollable Area
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 30)

                        VStack(spacing: 24) {
                            if selectedTab == 0 {
                                // Editorial Hero Header (Matching Screenshot Design)
                                VStack(spacing: 8) {
                                    Text("Download any\nYouTube video\n*instantly.*")
                                        .font(.system(size: 34, weight: .bold, design: .serif))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.primary)
                                        .lineSpacing(2)

                                    Text("Paste any YouTube link to download video + audio\nin the highest possible quality.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(3)
                                        .padding(.top, 2)

                                    // Stepper Pill Tracker
                                    HStack(spacing: 12) {
                                        StepIndicator(number: "1", title: "Paste Link", isActive: currentMetadata == nil && currentDownloadTask == nil)
                                        StepDivider()
                                        StepIndicator(number: "2", title: "Inspect Quality", isActive: currentMetadata != nil && currentDownloadTask == nil)
                                        StepDivider()
                                        StepIndicator(number: "3", title: "Download & Merge", isActive: currentDownloadTask != nil)
                                    }
                                    .padding(.top, 12)
                                }

                                // Main Input Box (Design from Screenshot)
                                URLInputView(
                                    urlText: $urlInput,
                                    isLoading: isFetchingMetadata,
                                    onFetch: { fetchVideoInfo() },
                                    onPasteAndFetch: { fetchVideoInfo() },
                                    onReset: { resetState() }
                                )
                                .frame(maxWidth: 640)

                                // Active Download Progress or Video Preview
                                if let task = currentDownloadTask {
                                    DownloadProgressView(
                                        task: task,
                                        onCancel: { cancelDownload() },
                                        onReset: { resetState() }
                                    )
                                    .frame(maxWidth: 640)
                                    .transition(.scale.combined(with: .opacity))
                                } else if let metadata = currentMetadata {
                                    VideoPreviewCardView(
                                        metadata: metadata,
                                        selectedQuality: $selectedQuality,
                                        downloadDirectory: $downloadDirectory,
                                        onStartDownload: { startDownload() }
                                    )
                                    .frame(maxWidth: 640)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                }
                            } else {
                                // History Tab
                                HistoryListView()
                                    .frame(maxWidth: 680)
                            }
                        }
                        .frame(maxWidth: 680)

                        Spacer(minLength: 40)
                    }
                    .frame(minHeight: 480)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                }
            }
        }
        .frame(minWidth: 720, minHeight: 580)
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

struct StepIndicator: View {
    let number: String
    let title: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(number)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isActive ? .white : .secondary)
                .frame(width: 18, height: 18)
                .background(Circle().fill(isActive ? Color.primary : Color.primary.opacity(0.12)))

            Text(title)
                .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .primary : .secondary)
        }
    }
}

struct StepDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.15))
            .frame(width: 20, height: 1)
    }
}
