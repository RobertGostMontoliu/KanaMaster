import Foundation

final class StudyProgressStore: ObservableObject {
    static let shared = StudyProgressStore()

    enum Track: String, CaseIterable {
        case hiragana
        case katakana
        case kanji
        case vocabulary
        case grammar
    }

    @Published private(set) var completedIDsByTrack: [String: Set<String>] = [:]
    @Published private(set) var lastIndexBySource: [String: Int] = [:]

    private let completedKey = "study_progress_completed_ids_v1"
    private let lastIndexKey = "study_progress_last_indexes_v1"

    private init() {
        load()
    }

    func completedCount(for track: Track, total: Int) -> Int {
        min(completedIDsByTrack[track.rawValue]?.count ?? 0, total)
    }

    func lastIndex(for sourceID: String, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return min(max(lastIndexBySource[sourceID] ?? 0, 0), total - 1)
    }

    func markCompleted(track: Track, itemID: String) {
        let trimmed = itemID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        var ids = completedIDsByTrack[track.rawValue] ?? []
        ids.insert(trimmed)
        completedIDsByTrack[track.rawValue] = ids
        saveCompleted()
    }

    func saveLastIndex(_ index: Int, sourceID: String, total: Int) {
        guard total > 0 else { return }
        lastIndexBySource[sourceID] = min(max(index, 0), total - 1)
        saveLastIndexes()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: completedKey),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            completedIDsByTrack = decoded.mapValues { Set($0) }
        }

        if let decoded = UserDefaults.standard.dictionary(forKey: lastIndexKey) as? [String: Int] {
            lastIndexBySource = decoded
        }
    }

    private func saveCompleted() {
        let encodable = completedIDsByTrack.mapValues { Array($0) }
        if let data = try? JSONEncoder().encode(encodable) {
            UserDefaults.standard.set(data, forKey: completedKey)
        }
    }

    private func saveLastIndexes() {
        UserDefaults.standard.set(lastIndexBySource, forKey: lastIndexKey)
    }
}
