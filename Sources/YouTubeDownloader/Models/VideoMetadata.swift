import Foundation

public struct VideoMetadata: Identifiable, Codable, Equatable {
    public let id: String
    public let title: String
    public let channel: String
    public let thumbnail: URL?
    public let duration: TimeInterval
    public let viewCount: Int?
    public let webpageUrl: String
    public let availableHeights: [Int]

    public var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    public var formattedViews: String {
        guard let viewCount = viewCount else { return "" }
        if viewCount >= 1_000_000 {
            return String(format: "%.1fM views", Double(viewCount) / 1_000_000)
        } else if viewCount >= 1_000 {
            return String(format: "%.1fK views", Double(viewCount) / 1_000)
        } else {
            return "\(viewCount) views"
        }
    }

    public func approximateSize(for quality: QualityOption) -> String {
        let dur = max(duration, 30)
        let bytesPerSec: Double
        switch quality {
        case .thumbnail:
            return "~1.2 MB"
        case .audioMp3:
            bytesPerSec = 24_000
        case .hd720:
            bytesPerSec = 320_000
        case .fhd1080:
            bytesPerSec = 580_000
        case .qhd1440:
            bytesPerSec = 1_150_000
        case .uhd4k:
            bytesPerSec = 2_300_000
        case .maxQuality:
            let maxH = availableHeights.first ?? 1080
            if maxH >= 2160 {
                bytesPerSec = 2_300_000
            } else if maxH >= 1440 {
                bytesPerSec = 1_150_000
            } else if maxH >= 1080 {
                bytesPerSec = 580_000
            } else {
                bytesPerSec = 320_000
            }
        }
        let totalMB = (bytesPerSec * dur) / 1_000_000.0
        if totalMB >= 1000 {
            return String(format: "~%.1f GB", totalMB / 1000.0)
        } else {
            return String(format: "~%.0f MB", totalMB)
        }
    }

    public static func parse(from jsonData: Data) throws -> VideoMetadata {
        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "VideoMetadata", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
        }

        let id = json["id"] as? String ?? UUID().uuidString
        let title = json["title"] as? String ?? "Untitled Video"
        let channel = (json["uploader"] as? String) ?? (json["channel"] as? String) ?? "YouTube"
        let webpageUrl = json["webpage_url"] as? String ?? ""

        var thumbURL: URL? = nil
        if let thumbStr = json["thumbnail"] as? String {
            thumbURL = URL(string: thumbStr)
        } else if let thumbs = json["thumbnails"] as? [[String: Any]], let lastThumb = thumbs.last?["url"] as? String {
            thumbURL = URL(string: lastThumb)
        }

        let duration = (json["duration"] as? Double) ?? Double(json["duration"] as? Int ?? 0)
        let viewCount = json["view_count"] as? Int

        var heights = Set<Int>()
        if let formats = json["formats"] as? [[String: Any]] {
            for f in formats {
                if let h = f["height"] as? Int, h > 0 {
                    heights.insert(h)
                }
            }
        }
        let sortedHeights = Array(heights).sorted(by: >)

        return VideoMetadata(
            id: id,
            title: title,
            channel: channel,
            thumbnail: thumbURL,
            duration: duration,
            viewCount: viewCount,
            webpageUrl: webpageUrl,
            availableHeights: sortedHeights
        )
    }
}
