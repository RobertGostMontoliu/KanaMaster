import Foundation

struct GrammarPayload: Codable {
    let schemaVersion: Int?
    let language: String?
    let sourceFile: String?
    let entryCount: Int?
    let entries: [GrammarItem]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case language
        case sourceFile = "source_file"
        case entryCount = "entry_count"
        case entries
    }
}

struct GrammarItem: Identifiable, Codable, Hashable {
    let order: Int
    let id: String
    let section: String
    let titleJa: String
    let titleEn: String
    let source: String
    let sourceExample: String?
    let pattern: String
    let meaningEn: String
    let meaningJa: String
    let usageEn: String
    let usageJa: String
    let examples: [GrammarExample]
    let exercises: [GrammarExercise]

    enum CodingKeys: String, CodingKey {
        case order
        case id
        case section
        case titleJa = "title_ja"
        case titleEn = "title_en"
        case source
        case sourceExample = "source_example"
        case pattern
        case meaningEn = "meaning_en"
        case meaningJa = "meaning_ja"
        case usageEn = "usage_en"
        case usageJa = "usage_ja"
        case examples
        case exercises
    }

    var title: String {
        titleEn.isEmpty ? titleJa : titleEn
    }

    var displayTitle: String {
        "\(id)  \(titleEn)"
    }
}

struct GrammarExample: Codable, Hashable {
    let japanese: String
    let english: String
}

struct GrammarExercise: Identifiable, Codable, Hashable {
    let type: String
    let promptEn: String?
    let promptJa: String?
    let prompt: String?
    let options: [String]?
    let answerIndex: Int?
    let answer: String?
    let acceptableAnswers: [String]?
    let explanationEn: String?
    let explanationJa: String?

    enum CodingKeys: String, CodingKey {
        case type
        case promptEn = "prompt_en"
        case promptJa = "prompt_ja"
        case prompt
        case options
        case answerIndex = "answer_index"
        case answer
        case acceptableAnswers = "acceptable_answers"
        case explanationEn = "explanation_en"
        case explanationJa = "explanation_ja"
    }

    var id: String {
        "\(type)-\(promptEn ?? prompt ?? answer ?? "")"
    }

    var displayPrompt: String {
        promptJa ?? promptEn ?? prompt ?? "Exercise"
    }

    var correctOption: String? {
        guard let options, let answerIndex, options.indices.contains(answerIndex) else { return nil }
        return options[answerIndex]
    }

    var correctAnswers: [String] {
        if let acceptableAnswers, acceptableAnswers.isEmpty == false {
            return acceptableAnswers
        }
        if let answer {
            return [answer]
        }
        return []
    }

    var explanation: String {
        explanationJa ?? explanationEn ?? answer ?? ""
    }
}

struct GrammarSection: Identifiable, Hashable {
    let id: String
    let title: String
    let items: [GrammarItem]
}

final class GrammarRepository {
    static let shared = GrammarRepository()

    private(set) var grammarItems: [GrammarItem]
    private(set) var sections: [GrammarSection]

    private init() {
        let items = Self.loadGrammarFromJSON()
        self.grammarItems = items
        self.sections = Self.makeSections(from: items)
    }

    func item(id: String) -> GrammarItem? {
        grammarItems.first(where: { $0.id == id })
    }

    private static func loadGrammarFromJSON() -> [GrammarItem] {
        guard let url = Bundle.main.url(forResource: "grammar", withExtension: "json") else {
            debugPrint("Could not find grammar.json in Bundle.main")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(GrammarPayload.self, from: data)
            debugPrint("Loaded \(payload.entries.count) grammar entries")
            return payload.entries.sorted { $0.order < $1.order }
        } catch {
            debugPrint("Failed to decode grammar.json: \(error)")
            return []
        }
    }

    private static func makeSections(from items: [GrammarItem]) -> [GrammarSection] {
        let grouped = Dictionary(grouping: items, by: \.section)

        return grouped.map { section, items in
            GrammarSection(
                id: section,
                title: sectionTitle(for: section),
                items: items.sorted { $0.order < $1.order }
            )
        }
        .sorted { first, second in
            sectionSortValue(first.id) < sectionSortValue(second.id)
        }
    }

    private static func sectionTitle(for section: String) -> String {
        if Int(section) == nil {
            return section
        }
        return "Lesson \(section)"
    }

    private static func sectionSortValue(_ section: String) -> Int {
        Int(section) ?? Int.max
    }
}
