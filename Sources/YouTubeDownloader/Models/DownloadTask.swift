import Foundation

public enum DownloadStatus: String, Codable, Equatable {
    case idle
    case fetchingInfo
    case downloading
    case merging
    case completed
    case failed
    case cancelled

    public var title: String {
        switch self {
        case .idle: return "Ready"
        case .fetchingInfo: return "Fetching Details..."
        case .downloading: return "Downloading..."
        case .merging: return "Merging Audio & Video with FFmpeg..."
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    public var isTerminal: Bool {
        return self == .completed || self == .failed || self == .cancelled
    }

    public var isActive: Bool {
        return self == .fetchingInfo || self == .downloading || self == .merging
    }
}

public struct DownloadTask: Identifiable, Codable, Equatable {
    public let id: UUID
    public var url: String
    public var metadata: VideoMetadata?
    public var quality: QualityOption
    public var status: DownloadStatus
    public var progress: Double // 0.0 to 1.0
    public var downloadSpeed: String
    public var eta: String
    public var downloadedSize: String
    public var totalSize: String
    public var destinationPath: String?
    public var errorMessage: String?
    public var createdAt: Date
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        url: String,
        metadata: VideoMetadata? = nil,
        quality: QualityOption = .maxQuality,
        status: DownloadStatus = .idle,
        progress: Double = 0.0,
        downloadSpeed: String = "",
        eta: String = "",
        downloadedSize: String = "",
        totalSize: String = "",
        destinationPath: String? = nil,
        errorMessage: String? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.url = url
        self.metadata = metadata
        self.quality = quality
        self.status = status
        self.progress = progress
        self.downloadSpeed = downloadSpeed
        self.eta = eta
        self.downloadedSize = downloadedSize
        self.totalSize = totalSize
        self.destinationPath = destinationPath
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    public var destinationFileURL: URL? {
        guard let path = destinationPath else { return nil }
        return URL(fileURLWithPath: path)
    }

    public var displayTitle: String {
        return metadata?.title ?? "YouTube Video"
    }

    public var displayChannel: String {
        return metadata?.channel ?? "YouTube"
    }
}
