import Foundation

final class KanjiRepository {
    static let shared = KanjiRepository()

    private(set) var kanjiItems: [KanjiItem] = []
    private(set) var vocabularyItems: [VocabularyItem] = []
    private(set) var sentenceItems: [SentenceItem] = []

    private var kanjiCache: [JLPTLevel: [KanjiItem]] = [:]
    private var vocabularyCache: [JLPTLevel: [VocabularyItem]] = [:]
    private let bundles: [Bundle]

    private init(bundle: Bundle = .main, sentenceItems: [SentenceItem] = []) {
        self.bundles = [bundle, Bundle(for: BundleToken.self)]
        self.sentenceItems = sentenceItems
    }

    func loadKanji(level: Int) -> [KanjiItem] {
        guard let jlptLevel = JLPTLevel(jlptValue: level) else { return [] }
        return kanji(for: jlptLevel)
    }

    func loadAllKanji() -> [KanjiItem] {
        let loaded = JLPTLevel.allCases.flatMap { kanji(for: $0) }
        kanjiItems = loaded
        return loaded
    }

    func getKanjiByJLPT(_ level: Int) -> [KanjiItem] {
        loadKanji(level: level)
    }

    func getKanjiByCharacter(_ character: String) -> KanjiItem? {
        if let cached = kanjiCache.values.flatMap({ $0 }).first(where: { $0.kanji == character }) {
            return cached
        }
        return loadAllKanji().first(where: { $0.kanji == character })
    }

    func searchKanji(query: String) -> [KanjiItem] {
        let allKanji = loadAllKanji()
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard needle.isEmpty == false else { return allKanji }

        return allKanji.filter { item in
            item.kanji.contains(needle)
            || item.primaryMeaning.lowercased().contains(needle)
            || item.meanings.joined(separator: " ").lowercased().contains(needle)
            || item.allReadings.joined(separator: " ").contains(needle)
            || item.jlptLevelName.lowercased() == needle
            || (item.heisigEn?.lowercased().contains(needle) ?? false)
        }
    }

    func getRandomKanji(from items: [KanjiItem]) -> KanjiItem? {
        items.randomElement()
    }

    func generateKanjiToReadingQuestion(from items: [KanjiItem]) -> KanjiQuizQuestion? {
        let eligible = items.filter { preferredReadings(for: $0).isEmpty == false }
        guard let source = eligible.randomElement() else { return nil }

        let correct = preferredReadings(for: source).randomElement()
        guard let correct else { return nil }

        let distractors = items
            .filter { $0.kanji != source.kanji }
            .flatMap { preferredReadings(for: $0) }
            .filter { $0 != correct }

        let options = buildFourOptions(correct: correct, distractorPool: distractors)
        guard options.count == 4 else { return nil }

        return KanjiQuizQuestion(
            mode: .kanjiToReading,
            prompt: source.kanji,
            correctAnswer: correct,
            options: options,
            sourceKanji: source
        )
    }

    func generateReadingToKanjiQuestion(from items: [KanjiItem]) -> KanjiQuizQuestion? {
        let candidates = items.compactMap { item -> (KanjiItem, String)? in
            guard let reading = preferredReadings(for: item).first else { return nil }
            return (item, reading)
        }

        guard candidates.isEmpty == false else { return nil }

        let groupedByReading = Dictionary(grouping: candidates, by: { $0.1 })
        let uniqueTargets = groupedByReading.values.compactMap { group -> (KanjiItem, String)? in
            guard group.count == 1, let only = group.first else { return nil }
            return only
        }
        guard let target = uniqueTargets.randomElement() else { return nil }

        let targetKanji = target.0.kanji
        let targetReading = target.1
        let distractors = candidates
            .filter { $0.0.kanji != targetKanji && $0.1 != targetReading }
            .map { $0.0.kanji }

        let options = buildFourOptions(correct: targetKanji, distractorPool: distractors)
        guard options.count == 4 else { return nil }

        return KanjiQuizQuestion(
            mode: .readingToKanji,
            prompt: targetReading,
            correctAnswer: targetKanji,
            options: options,
            sourceKanji: target.0
        )
    }

    func kanji(for level: JLPTLevel) -> [KanjiItem] {
        if let cached = kanjiCache[level] {
            return cached
        }

        let loaded = decodeKanjiDictionary(for: level)
        kanjiCache[level] = loaded
        rebuildFlatCaches()
        return loaded
    }

    func vocabulary(for level: JLPTLevel) -> [VocabularyItem] {
        if let cached = vocabularyCache[level] {
            return cached
        }

        _ = kanji(for: level)
        return vocabularyCache[level] ?? []
    }

    func sentences(for level: JLPTLevel) -> [SentenceItem] {
        sentenceItems
            .filter { $0.jlptLevel == level }
            .sorted { $0.id < $1.id }
    }

    func kanji(by id: String) -> KanjiItem? {
        let canonical = canonicalKanjiID(id)
        if let cached = kanjiCache.values.flatMap({ $0 }).first(where: { canonicalKanjiID($0.id) == canonical }) {
            return cached
        }
        return loadAllKanji().first(where: { canonicalKanjiID($0.id) == canonical })
    }

    func vocabulary(by id: String) -> VocabularyItem? {
        if let cached = vocabularyItems.first(where: { $0.id == id }) {
            return cached
        }
        _ = loadAllKanji()
        return vocabularyItems.first(where: { $0.id == id })
    }

    func sentence(by id: String) -> SentenceItem? {
        sentenceItems.first(where: { $0.id == id })
    }

    func lessons(for level: JLPTLevel) -> [KanjiLesson] {
        let ids = kanji(for: level).map(\.id)
        guard ids.isEmpty == false else { return [] }

        return [
            KanjiLesson(
                id: "lesson_\(level.rawValue)",
                level: level,
                title: "\(level.rawValue) Kanji",
                category: level.rawValue,
                kanjiIds: ids
            )
        ]
    }

    func kanji(for level: JLPTLevel, category: String) -> [KanjiItem] {
        kanji(for: level)
    }

    func vocabulary(forKanjiID kanjiID: String, level: JLPTLevel) -> [VocabularyItem] {
        guard let item = kanji(for: level).first(where: { canonicalKanjiID($0.id) == canonicalKanjiID(kanjiID) }) else {
            return []
        }

        return item.vocabulary.map { vocabularyItem(from: $0, level: level, kanjiIDs: [item.id]) }
    }

    func vocabulary(forKanjiIDs kanjiIDs: [String], level: JLPTLevel) -> [VocabularyItem] {
        let idSet = Set(kanjiIDs.map(canonicalKanjiID))
        return kanji(for: level).flatMap { item -> [VocabularyItem] in
            guard idSet.contains(canonicalKanjiID(item.id)) else { return [] }
            return item.vocabulary.map { vocabularyItem(from: $0, level: level, kanjiIDs: [item.id]) }
        }
    }

    func sentences(forKanjiIDs kanjiIDs: [String], level: JLPTLevel) -> [SentenceItem] {
        let idSet = Set(kanjiIDs.map(canonicalKanjiID))
        return sentences(for: level)
            .filter { !Set($0.kanjiIds.map(canonicalKanjiID)).isDisjoint(with: idSet) }
    }

    func contains(level: JLPTLevel, itemType: StudyItemType, itemId: String) -> Bool {
        switch itemType {
        case .kanji:
            return kanji(for: level).contains {
                canonicalKanjiID($0.id) == canonicalKanjiID(itemId)
            }
        case .vocabulary:
            return vocabulary(for: level).contains { $0.id == itemId }
        case .sentence:
            return sentences(for: level).contains { $0.id == itemId }
        }
    }

    func allItemIDs(for level: JLPTLevel) -> [String] {
        kanji(for: level).map(\.id) + vocabulary(for: level).map(\.id) + sentences(for: level).map(\.id)
    }

    private func rebuildFlatCaches() {
        let loadedLevels = JLPTLevel.allCases.filter { kanjiCache[$0] != nil }
        kanjiItems = loadedLevels.flatMap { kanjiCache[$0] ?? [] }

        vocabularyCache = Dictionary(uniqueKeysWithValues: loadedLevels.map { level in
            let levelVocabulary = (kanjiCache[level] ?? []).flatMap { item in
                item.vocabulary.map { vocabularyItem(from: $0, level: level, kanjiIDs: [item.id]) }
            }
            return (level, levelVocabulary)
        })
        vocabularyItems = loadedLevels.flatMap { vocabularyCache[$0] ?? [] }
    }

    private func decodeKanjiDictionary(for level: JLPTLevel) -> [KanjiItem] {
        let resourceName = resourceName(for: level)

        for bundle in bundles {
            if let loaded = decodeKanjiDictionary(resourceName: resourceName, level: level, bundle: bundle, subdirectory: nil) {
                return loaded
            }

            if let loaded = decodeKanjiDictionary(resourceName: resourceName, level: level, bundle: bundle, subdirectory: "Dictionaries/Kanji") {
                return loaded
            }
        }

        debugPrint("Could not find \(resourceName).json in Bundle.main")
        return []
    }

    private func decodeKanjiDictionary(resourceName: String, level: JLPTLevel, bundle: Bundle, subdirectory: String?) -> [KanjiItem]? {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json", subdirectory: subdirectory) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            guard data.isEmpty == false else {
                debugPrint("\(resourceName).json is empty")
                return []
            }

            let decoded = try JSONDecoder().decode([String: KanjiItem].self, from: data)
            let sorted = decoded.values.sorted(by: kanjiSort)
            debugPrint("Loaded \(sorted.count) Kanji from \(level.rawValue)")
            return sorted
        } catch {
            debugPrint("Failed to decode \(resourceName).json: \(error)")
            return []
        }
    }

    private func kanjiSort(_ lhs: KanjiItem, _ rhs: KanjiItem) -> Bool {
        switch (lhs.freqMainichiShinbun, rhs.freqMainichiShinbun) {
        case let (left?, right?) where left != right:
            return left < right
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        default:
            if lhs.strokeCount != rhs.strokeCount {
                return (lhs.strokeCount ?? Int.max) < (rhs.strokeCount ?? Int.max)
            }
            return lhs.kanji < rhs.kanji
        }
    }

    private func preferredReadings(for item: KanjiItem) -> [String] {
        let preferred = item.kunReadings + item.onReadings
        return Array(Set(preferred.map(normalizeReading).filter { $0.isEmpty == false })).sorted()
    }

    private func normalizeReading(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "-", with: "")
    }

    private func buildFourOptions(correct: String, distractorPool: [String]) -> [String] {
        var unique = Array(Set(distractorPool.filter { $0.isEmpty == false && $0 != correct }))
        unique.shuffle()

        var options = Array(unique.prefix(3))
        options.append(correct)

        options = Array(Set(options)).shuffled()
        if options.count < 4 {
            let missing = 4 - options.count
            let extra = unique.filter { options.contains($0) == false }.prefix(missing)
            options.append(contentsOf: extra)
            options = Array(Set(options)).shuffled()
        }
        return options
    }

    private func canonicalKanjiID(_ raw: String) -> String {
        raw.hasPrefix("kanji_") ? raw : "kanji_\(raw)"
    }

    private func vocabularyItem(from entry: KanjiVocabularyEntry, level: JLPTLevel, kanjiIDs: [String]) -> VocabularyItem {
        VocabularyItem(
            id: "vocab_\(entry.word)_\(entry.reading)",
            word: entry.word,
            reading: entry.reading,
            meaning: entry.primaryMeaning,
            jlptLevel: level,
            kanjiIds: kanjiIDs
        )
    }

    private func resourceName(for level: JLPTLevel) -> String {
        "kanji_n\(level.jlptValue)_final_v3"
    }
}

private final class BundleToken {}
