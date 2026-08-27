import Foundation
import Combine

public struct ProgressUpdate {
    public let progress: Double // 0.0 to 1.0
    public let speed: String
    public let eta: String
    public let downloadedSize: String
    public let totalSize: String
    public let statusText: String
}

public final class YtDlpService: ObservableObject {
    public static let shared = YtDlpService()

    private var activeProcesses: [UUID: Process] = [:]
    private let queue = DispatchQueue(label: "com.antigravity.ytdlp.service", qos: .userInitiated)

    private init() {}

    public func fetchMetadata(for urlString: String) async throws -> VideoMetadata {
        guard let ytdlpPath = BinaryResolver.shared.resolveYtDlp() else {
            throw NSError(
                domain: "YtDlpService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "yt-dlp was not found on your system. Please install it or specify its path in Settings."]
            )
        }

        guard let cleanedURL = cleanYouTubeURL(urlString), !cleanedURL.isEmpty else {
            throw NSError(
                domain: "YtDlpService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid YouTube URL format."]
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: ytdlpPath)
                process.arguments = [
                    "--dump-json",
                    "--no-playlist",
                    "--no-warnings",
                    "--skip-download",
                    cleanedURL
                ]

                var env = ProcessInfo.processInfo.environment
                let path = env["PATH"] ?? ""
                env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:~/.local/bin:\(path)"
                process.environment = env

                let outPipe = Pipe()
                let errPipe = Pipe()
                process.standardOutput = outPipe
                process.standardError = errPipe

                do {
                    try process.run()
                    let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()

                    if process.terminationStatus == 0 && !data.isEmpty {
                        do {
                            let metadata = try VideoMetadata.parse(from: data)
                            continuation.resume(returning: metadata)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    } else {
                        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                        let errMsg = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Failed to fetch video details."
                        continuation.resume(throwing: NSError(
                            domain: "YtDlpService",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: errMsg.isEmpty ? "Failed to retrieve video metadata." : errMsg]
                        ))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func download(
        taskID: UUID,
        url: String,
        quality: QualityOption,
        outputDirectory: URL,
        onProgress: @escaping (ProgressUpdate) -> Void,
        onStatusChange: @escaping (DownloadStatus) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let ytdlpPath = BinaryResolver.shared.resolveYtDlp() else {
            completion(.failure(NSError(
                domain: "YtDlpService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "yt-dlp was not found on your system."]
            )))
            return
        }

        let ffmpegPath = BinaryResolver.shared.resolveFfmpeg()

        guard let cleanedURL = cleanYouTubeURL(url) else {
            completion(.failure(NSError(
                domain: "YtDlpService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid YouTube URL."]
            )))
            return
        }

        queue.async { [weak self] in
            guard let self = self else { return }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: ytdlpPath)

            let outputTemplate = outputDirectory.appendingPathComponent("%(title)s [%(id)s].%(ext)s").path

            var args: [String] = [
                "--newline",
                "--no-playlist",
                "--no-mtime",
                "--no-simulate",
                "--progress",
                "-o", outputTemplate
            ]

            if let ffmpeg = ffmpegPath {
                args.append(contentsOf: ["--ffmpeg-location", ffmpeg])
            }

            args.append(contentsOf: quality.formatArguments())
            args.append(cleanedURL)

            process.arguments = args

            var env = ProcessInfo.processInfo.environment
            let path = env["PATH"] ?? ""
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:~/.local/bin:\(path)"
            process.environment = env

            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            self.activeProcesses[taskID] = process

            var finalFilePath: String? = nil
            var rawOutput = ""

            outPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
                rawOutput.append(line)

                for singleLine in line.components(separatedBy: .newlines) {
                    let trimmed = singleLine.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty { continue }

                    // Parse destination from merger: [Merger] Merging formats into "/path/to/file.mp4"
                    if trimmed.contains("[Merger]") || trimmed.contains("Merging formats into") {
                        if let firstQuote = trimmed.firstIndex(of: "\""),
                           let lastQuote = trimmed.lastIndex(of: "\""),
                           firstQuote < lastQuote {
                            let path = String(trimmed[trimmed.index(after: firstQuote)..<lastQuote])
                            if !path.isEmpty {
                                finalFilePath = path
                            }
                        }
                    }

                    // Parse destination from direct download or extract: [download] Destination: ...
                    if (trimmed.contains("[download] Destination:") || trimmed.contains("[ExtractAudio] Destination:")) {
                        let parts = trimmed.components(separatedBy: "Destination:")
                        if let dest = parts.last?.trimmingCharacters(in: .whitespacesAndNewlines), !dest.isEmpty {
                            if !dest.contains(".f") { // Ignore intermediate temporary format parts like .f395.mp4
                                finalFilePath = dest
                            }
                        }
                    }

                    if trimmed.contains("[VideoConvertor]") || trimmed.contains("Converting video") {
                        DispatchQueue.main.async {
                            onStatusChange(.merging)
                            onProgress(ProgressUpdate(
                                progress: 0.98,
                                speed: "",
                                eta: "",
                                downloadedSize: "",
                                totalSize: "",
                                statusText: "Optimizing for QuickTime Player..."
                            ))
                        }
                    } else if trimmed.contains("[Merger]") || trimmed.contains("[ffmpeg]") || trimmed.contains("Merging formats") {
                        DispatchQueue.main.async {
                            onStatusChange(.merging)
                            onProgress(ProgressUpdate(
                                progress: 0.95,
                                speed: "",
                                eta: "",
                                downloadedSize: "",
                                totalSize: "",
                                statusText: "Merging audio & video with FFmpeg..."
                            ))
                        }
                    } else if trimmed.contains("[download]") {
                        if let update = self.parseDownloadProgress(line: trimmed) {
                            DispatchQueue.main.async {
                                onStatusChange(.downloading)
                                onProgress(update)
                            }
                        }
                    }
                }
            }

            do {
                try process.run()
                process.waitUntilExit()
                outPipe.fileHandleForReading.readabilityHandler = nil
                self.activeProcesses.removeValue(forKey: taskID)

                if process.terminationStatus == 0 {
                    DispatchQueue.main.async {
                        if let finalPath = finalFilePath, FileManager.default.fileExists(atPath: finalPath) {
                            completion(.success(URL(fileURLWithPath: finalPath)))
                        } else {
                            // Fallback: check most recently modified file in outputDirectory
                            if let recent = self.findRecentlyModifiedFile(in: outputDirectory) {
                                completion(.success(recent))
                            } else {
                                completion(.success(outputDirectory))
                            }
                        }
                    }
                } else {
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    let errMsg = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    DispatchQueue.main.async {
                        completion(.failure(NSError(
                            domain: "YtDlpService",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: errMsg.isEmpty ? "Download was cancelled or interrupted." : errMsg]
                        )))
                    }
                }
            } catch {
                outPipe.fileHandleForReading.readabilityHandler = nil
                self.activeProcesses.removeValue(forKey: taskID)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    public func cancel(taskID: UUID) {
        if let process = activeProcesses[taskID], process.isRunning {
            process.terminate()
            activeProcesses.removeValue(forKey: taskID)
        }
    }

    private func parseDownloadProgress(line: String) -> ProgressUpdate? {
        // Example lines:
        // [download]  45.2% of  125.40MiB at   12.34MiB/s ETA 00:08
        // [download]  100% of  125.40MiB in 00:05
        guard line.contains("%") else { return nil }

        var percent: Double = 0.0
        var totalSize = ""
        var downloadedSize = ""
        var speed = ""
        var eta = ""

        // Extract percentage:
        let percentPattern = #"(\d+(?:\.\d+)?)%"#
        if let match = matches(for: percentPattern, in: line).first, let p = Double(match) {
            percent = p / 100.0
        }

        // Extract total size:
        let totalSizePattern = #"of\s+~?\s*(\d+(?:\.\d+)?[a-zA-Z]+)"#
        if let match = matches(for: totalSizePattern, in: line).first {
            totalSize = match
        }

        // Extract speed:
        let speedPattern = #"at\s+(\d+(?:\.\d+)?[a-zA-Z]+/s)"#
        if let match = matches(for: speedPattern, in: line).first {
            speed = match
        }

        // Extract ETA:
        let etaPattern = #"ETA\s+([0-9:]+)"#
        if let match = matches(for: etaPattern, in: line).first {
            eta = match
        }

        if percent > 0.0 && !totalSize.isEmpty {
            // Rough estimate of downloaded size
            let numericTotal = totalSize.filter { "0123456789.".contains($0) }
            let unit = totalSize.filter { !"0123456789.".contains($0) }
            if let tot = Double(numericTotal) {
                let down = tot * percent
                downloadedSize = String(format: "%.1f%@", down, unit)
            }
        }

        let cleanSpeed = normalizeUnits(speed)
        let cleanTotal = normalizeUnits(totalSize)
        let cleanDownloaded = normalizeUnits(downloadedSize)

        return ProgressUpdate(
            progress: min(max(percent, 0.0), 1.0),
            speed: cleanSpeed.isEmpty ? "--" : cleanSpeed,
            eta: eta.isEmpty ? "--" : eta,
            downloadedSize: cleanDownloaded,
            totalSize: cleanTotal,
            statusText: percent >= 0.999 ? "Finalizing download..." : "Downloading..."
        )
    }

    private func normalizeUnits(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "GiB/s", with: "GB/s")
            .replacingOccurrences(of: "MiB/s", with: "MB/s")
            .replacingOccurrences(of: "KiB/s", with: "KB/s")
            .replacingOccurrences(of: "TiB/s", with: "TB/s")
            .replacingOccurrences(of: "gib/s", with: "GB/s")
            .replacingOccurrences(of: "mib/s", with: "MB/s")
            .replacingOccurrences(of: "kib/s", with: "KB/s")
            .replacingOccurrences(of: "GiB", with: "GB")
            .replacingOccurrences(of: "MiB", with: "MB")
            .replacingOccurrences(of: "KiB", with: "KB")
            .replacingOccurrences(of: "TiB", with: "TB")
            .replacingOccurrences(of: "gib", with: "GB")
            .replacingOccurrences(of: "mib", with: "MB")
            .replacingOccurrences(of: "kib", with: "KB")
    }

    private func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.compactMap { result in
                if result.numberOfRanges > 1 {
                    let range = result.range(at: 1)
                    return range.location != NSNotFound ? nsString.substring(with: range) : nil
                }
                return nil
            }
        } catch {
            return []
        }
    }

    private func findRecentlyModifiedFile(in directory: URL) -> URL? {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
            return files.max { a, b in
                let aDate = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let bDate = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return aDate < bDate
            }
        } catch {
            return nil
        }
    }

    public func cleanYouTubeURL(_ urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.contains("youtube.com") || trimmed.contains("youtu.be") {
            return trimmed
        }
        return nil
    }
}
