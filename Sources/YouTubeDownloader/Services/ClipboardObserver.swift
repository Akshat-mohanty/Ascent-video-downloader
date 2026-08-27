import AppKit
import Combine

public final class ClipboardObserver: ObservableObject {
    public static let shared = ClipboardObserver()

    @Published public var detectedYouTubeURL: String? = nil
    private var lastChangeCount: Int = -1
    private var timer: Timer?

    private init() {
        startObserving()
    }

    public func startObserving() {
        checkClipboard()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    public func stopObserving() {
        timer?.invalidate()
        timer = nil
    }

    public func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if let string = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if isYouTubeURL(string) {
                if detectedYouTubeURL != string {
                    detectedYouTubeURL = string
                }
            }
        }
    }

    public func getPasteboardString() -> String? {
        return NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func dismissDetection() {
        detectedYouTubeURL = nil
    }

    private func isYouTubeURL(_ text: String) -> Bool {
        return (text.contains("youtube.com/watch") ||
                text.contains("youtu.be/") ||
                text.contains("youtube.com/shorts/") ||
                text.contains("youtube.com/live/")) &&
               (text.hasPrefix("http://") || text.hasPrefix("https://"))
    }
}
