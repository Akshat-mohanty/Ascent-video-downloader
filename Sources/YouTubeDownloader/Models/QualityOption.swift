import Foundation

public enum QualityOption: String, CaseIterable, Identifiable, Codable {
    case maxQuality = "max"
    case uhd4k = "4k"
    case qhd1440 = "1440p"
    case fhd1080 = "1080p"
    case hd720 = "720p"
    case audioMp3 = "mp3"
    case audioM4a = "m4a"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .maxQuality: return "Best Quality (Video + Audio)"
        case .uhd4k: return "4K Ultra HD (2160p)"
        case .qhd1440: return "2K Quad HD (1440p)"
        case .fhd1080: return "Full HD (1080p)"
        case .hd720: return "HD (720p)"
        case .audioMp3: return "Audio Only (MP3)"
        case .audioM4a: return "Audio Only (M4A)"
        }
    }

    public var shortTitle: String {
        switch self {
        case .maxQuality: return "MAX"
        case .uhd4k: return "4K"
        case .qhd1440: return "1440p"
        case .fhd1080: return "1080p"
        case .hd720: return "720p"
        case .audioMp3: return "MP3"
        case .audioM4a: return "M4A"
        }
    }

    public var icon: String {
        switch self {
        case .maxQuality: return "sparkles.tv.fill"
        case .uhd4k, .qhd1440, .fhd1080, .hd720: return "film.fill"
        case .audioMp3, .audioM4a: return "music.note"
        }
    }

    public var isAudioOnly: Bool {
        return self == .audioMp3 || self == .audioM4a
    }

    public var badgeColor: String {
        switch self {
        case .maxQuality: return "purple"
        case .uhd4k: return "pink"
        case .qhd1440: return "indigo"
        case .fhd1080: return "blue"
        case .hd720: return "cyan"
        case .audioMp3: return "orange"
        case .audioM4a: return "green"
        }
    }

    public func formatArguments() -> [String] {
        switch self {
        case .maxQuality:
            return ["-f", "bestvideo*+bestaudio/best", "--merge-output-format", "mp4"]
        case .uhd4k:
            return ["-f", "bestvideo[height<=2160]+bestaudio/best[height<=2160]/best", "--merge-output-format", "mp4"]
        case .qhd1440:
            return ["-f", "bestvideo[height<=1440]+bestaudio/best[height<=1440]/best", "--merge-output-format", "mp4"]
        case .fhd1080:
            return ["-f", "bestvideo[height<=1080]+bestaudio/best[height<=1080]/best", "--merge-output-format", "mp4"]
        case .hd720:
            return ["-f", "bestvideo[height<=720]+bestaudio/best[height<=720]/best", "--merge-output-format", "mp4"]
        case .audioMp3:
            return ["-x", "--audio-format", "mp3", "--audio-quality", "0"]
        case .audioM4a:
            return ["-x", "--audio-format", "m4a"]
        }
    }
}
