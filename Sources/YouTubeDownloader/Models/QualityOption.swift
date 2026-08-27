import Foundation

public enum QualityOption: String, CaseIterable, Identifiable, Codable {
    case maxQuality = "max"
    case uhd4k = "4k"
    case qhd1440 = "1440p"
    case fhd1080 = "1080p"
    case hd720 = "720p"
    case audioMp3 = "mp3"
    case audioM4a = "m4a"
    case thumbnail = "thumb"

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
        case .thumbnail: return "HD Thumbnail (JPG)"
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
        case .thumbnail: return "Thumbnail"
        }
    }

    public var icon: String {
        switch self {
        case .maxQuality: return "sparkles.tv.fill"
        case .uhd4k, .qhd1440, .fhd1080, .hd720: return "film.fill"
        case .audioMp3, .audioM4a: return "music.note"
        case .thumbnail: return "photo.fill"
        }
    }

    public var typeLabel: String {
        switch self {
        case .maxQuality, .uhd4k, .qhd1440, .fhd1080, .hd720:
            return "Video"
        case .audioMp3, .audioM4a:
            return "Audio"
        case .thumbnail:
            return "Image"
        }
    }

    public var isAudioOnly: Bool {
        return self == .audioMp3 || self == .audioM4a
    }

    public var isThumbnail: Bool {
        return self == .thumbnail
    }

    public func formatArguments() -> [String] {
        switch self {
        case .maxQuality:
            return [
                "-f", "bestvideo[vcodec^=avc1]+bestaudio[acodec^=mp4a]/bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best",
                "-S", "res,ext:mp4:m4a,vcodec:h264,acodec:m4a",
                "--merge-output-format", "mp4",
                "--recode-video", "mp4"
            ]
        case .uhd4k:
            return [
                "-f", "bestvideo[height<=2160][vcodec^=avc1]+bestaudio[acodec^=mp4a]/bestvideo[height<=2160]+bestaudio/best[height<=2160]/best",
                "-S", "res:2160,ext:mp4:m4a,vcodec:h264,acodec:m4a",
                "--merge-output-format", "mp4",
                "--recode-video", "mp4"
            ]
        case .qhd1440:
            return [
                "-f", "bestvideo[height<=1440][vcodec^=avc1]+bestaudio[acodec^=mp4a]/bestvideo[height<=1440]+bestaudio/best[height<=1440]/best",
                "-S", "res:1440,ext:mp4:m4a,vcodec:h264,acodec:m4a",
                "--merge-output-format", "mp4",
                "--recode-video", "mp4"
            ]
        case .fhd1080:
            return [
                "-f", "bestvideo[height<=1080][vcodec^=avc1]+bestaudio[acodec^=mp4a]/bestvideo[height<=1080]+bestaudio/best[height<=1080]/best",
                "-S", "res:1080,ext:mp4:m4a,vcodec:h264,acodec:m4a",
                "--merge-output-format", "mp4",
                "--recode-video", "mp4"
            ]
        case .hd720:
            return [
                "-f", "bestvideo[height<=720][vcodec^=avc1]+bestaudio[acodec^=mp4a]/bestvideo[height<=720]+bestaudio/best[height<=720]/best",
                "-S", "res:720,ext:mp4:m4a,vcodec:h264,acodec:m4a",
                "--merge-output-format", "mp4",
                "--recode-video", "mp4"
            ]
        case .audioMp3:
            return ["-x", "--audio-format", "mp3", "--audio-quality", "0"]
        case .audioM4a:
            return ["-x", "--audio-format", "m4a"]
        case .thumbnail:
            return ["--skip-download", "--write-thumbnail", "--convert-thumbnails", "jpg"]
        }
    }
}
