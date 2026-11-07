// VocabularyRepository: Loads and exposes vocabulary from Vocabulary.csv, grouped by levels as per the CSV.
import Foundation

final class VocabularyRepository {
    static let shared = VocabularyRepository()

    private(set) var vocabularyItems: [VocabularyItem]
    private let levelSections: [(level: String, items: [VocabularyItem])]

    private init() {
        let (items, sections) = Self.loadVocabularyFromCSV()
        self.vocabularyItems = items
        self.levelSections = sections
    }

    func vocabulary(for level: String) -> [VocabularyItem] {
        levelSections.first(where: { $0.level == level })?.items ?? []
    }

    func levels() -> [String] {
        levelSections.map { $0.level }
    }

    func searchVocabulary(query: String) -> [VocabularyItem] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard needle.isEmpty == false else { return vocabularyItems }
        return vocabularyItems.filter {
            $0.word.lowercased().contains(needle)
            || $0.reading.lowercased().contains(needle)
            || $0.meaning.lowercased().contains(needle)
        }
    }

    // MARK: - CSV Loading

    private static func loadVocabularyFromCSV() -> ([VocabularyItem], [(level: String, items: [VocabularyItem])]) {
        guard let url = Bundle.main.url(forResource: "Vocabulary", withExtension: "csv"),
              let content = try? String(contentsOf: url) else {
            return ([], [])
        }
        var items: [VocabularyItem] = []
        var levelDict: [String: [VocabularyItem]] = [:]
        var currentLevel = "Uncategorized"
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if trimmed.range(of: "^[0-9]+-[0-9]+", options: .regularExpression) != nil || trimmed.hasSuffix(",,,") {
                // New section header
                currentLevel = trimmed.replacingOccurrences(of: ",,,", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if levelDict[currentLevel] == nil {
                    levelDict[currentLevel] = []
                }
                continue
            }
            let columns = trimmed.components(separatedBy: ",")
            // Expected: [word, reading, meaning]
            guard columns.count >= 3 else { continue }
            let word = columns[1].trimmingCharacters(in: .whitespaces)
            let reading = columns[2].trimmingCharacters(in: .whitespaces)
            let meaning = columns.count > 3 ? columns[3].trimmingCharacters(in: .whitespaces) : ""
            let id = "vocab_\(word)"
            let vocabItem = VocabularyItem(id: id, word: word, reading: reading, meaning: meaning, jlptLevel: .n5, kanjiIds: [])
            items.append(vocabItem)
            levelDict[currentLevel, default: []].append(vocabItem)
        }
        let sections = levelDict.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
        return (items, sections)
    }
}
