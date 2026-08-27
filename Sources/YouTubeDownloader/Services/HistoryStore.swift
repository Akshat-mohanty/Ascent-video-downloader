import Foundation
import Combine

public final class HistoryStore: ObservableObject {
    public static let shared = HistoryStore()

    @Published public var items: [DownloadTask] = []

    private let saveKey = "youtube_downloader_history_v1"

    private init() {
        loadHistory()
    }

    public func addTask(_ task: DownloadTask) {
        if let idx = items.firstIndex(where: { $0.id == task.id }) {
            items[idx] = task
        } else {
            items.insert(task, at: 0)
        }
        saveHistory()
    }

    public func updateTask(_ task: DownloadTask) {
        if let idx = items.firstIndex(where: { $0.id == task.id }) {
            items[idx] = task
            saveHistory()
        }
    }

    public func removeTask(id: UUID) {
        items.removeAll { $0.id == id }
        saveHistory()
    }

    public func clearAll() {
        items.removeAll()
        saveHistory()
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save history: \(error)")
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        do {
            items = try JSONDecoder().decode([DownloadTask].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
        }
    }
}
