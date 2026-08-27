import Foundation

public final class BinaryResolver {
    public static let shared = BinaryResolver()

    private let userDefaults = UserDefaults.standard
    private let ytDlpCustomKey = "custom_ytdlp_path"
    private let ffmpegCustomKey = "custom_ffmpeg_path"

    private init() {}

    public var customYtDlpPath: String? {
        get { userDefaults.string(forKey: ytDlpCustomKey) }
        set { userDefaults.set(newValue, forKey: ytDlpCustomKey) }
    }

    public var customFfmpegPath: String? {
        get { userDefaults.string(forKey: ffmpegCustomKey) }
        set { userDefaults.set(newValue, forKey: ffmpegCustomKey) }
    }

    public func resolveYtDlp() -> String? {
        if let custom = customYtDlpPath, !custom.isEmpty, FileManager.default.isExecutableFile(atPath: custom) {
            return custom
        }

        let standardPaths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "\(NSHomeDirectory())/.local/bin/yt-dlp",
            "\(NSHomeDirectory())/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]

        for path in standardPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        if let whichPath = findInPath(command: "yt-dlp") {
            return whichPath
        }

        return nil
    }

    public func resolveFfmpeg() -> String? {
        if let custom = customFfmpegPath, !custom.isEmpty, FileManager.default.isExecutableFile(atPath: custom) {
            return custom
        }

        let standardPaths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "\(NSHomeDirectory())/.local/bin/ffmpeg",
            "\(NSHomeDirectory())/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]

        for path in standardPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        if let whichPath = findInPath(command: "ffmpeg") {
            return whichPath
        }

        return nil
    }

    private func findInPath(command: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [command]

        var env = ProcessInfo.processInfo.environment
        let path = env["PATH"] ?? ""
        let extraPaths = "/opt/homebrew/bin:/usr/local/bin:~/.local/bin"
        env["PATH"] = "\(extraPaths):\(path)"
        task.environment = env

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty, FileManager.default.isExecutableFile(atPath: output) {
                return output
            }
        } catch {
            return nil
        }
        return nil
    }
}
