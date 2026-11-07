import Foundation

enum JLPTLevel: String, CaseIterable, Codable, Hashable {
    case n1 = "N1"
    case n2 = "N2"
    case n3 = "N3"
    case n4 = "N4"
    case n5 = "N5"

    init?(jlptValue: Int) {
        self.init(rawValue: "N\(jlptValue)")
    }

    var jlptValue: Int {
        Int(rawValue.dropFirst()) ?? 5
    }
}

enum StudyItemType: String, Codable, Hashable {
    case kanji
    case vocabulary
    case sentence
}

struct KanjiVocabularyEntry: Codable, Hashable {
    let word: String
    let reading: String
    let meanings: [String]
    let common: Bool?

    var primaryMeaning: String {
        meanings.first ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case word
        case reading
        case meanings
        case common
    }
}

struct KanjiItem: Identifiable, Codable, Hashable {
    let kanji: String
    let meanings: [String]
    let kunReadings: [String]
    let onReadings: [String]
    let nameReadings: [String]
    let notes: [String]
    let alternateStrokeCounts: [Int]
    let freqMainichiShinbun: Int?
    let grade: Int?
    let heisigEn: String?
    let jlpt: Int?
    let strokeCount: Int?
    let unicode: String?
    let vocabulary: [KanjiVocabularyEntry]

    var id: String { "kanji_\(kanji)" }

    var primaryMeaning: String {
        meanings.first ?? ""
    }

    var allReadings: [String] {
        kunReadings + onReadings
    }

    var jlptLevelName: String {
        jlpt.map { "N\($0)" } ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case kanji
        case meanings
        case kunReadings = "kun_readings"
        case onReadings = "on_readings"
        case nameReadings = "name_readings"
        case notes
        case alternateStrokeCounts = "alternate_stroke_counts"
        case freqMainichiShinbun = "freq_mainichi_shinbun"
        case grade
        case heisigEn = "heisig_en"
        case jlpt
        case strokeCount = "stroke_count"
        case unicode
        case vocabulary
    }
}

struct VocabularyItem: Identifiable, Codable, Hashable {
    let id: String
    let word: String
    let reading: String
    let meaning: String
    let jlptLevel: JLPTLevel
    let kanjiIds: [String]

    init(id: String, word: String, reading: String, meaning: String, jlptLevel: JLPTLevel, kanjiIds: [String]) {
        self.id = id
        self.word = word
        self.reading = reading
        self.meaning = meaning
        self.jlptLevel = jlptLevel
        self.kanjiIds = kanjiIds
    }
}

struct SentenceItem: Identifiable, Codable, Hashable {
    let id: String
    let sentence: String
    let translation: String
    let jlptLevel: JLPTLevel
    let kanjiIds: [String]

    init(id: String, sentence: String = "", translation: String = "", jlptLevel: JLPTLevel, kanjiIds: [String]) {
        self.id = id
        self.sentence = sentence
        self.translation = translation
        self.jlptLevel = jlptLevel
        self.kanjiIds = kanjiIds
    }
}

struct KanjiLesson: Identifiable, Codable, Hashable {
    let id: String
    let level: JLPTLevel
    let title: String
    let category: String
    let kanjiIds: [String]
}

enum KanjiQuizMode: String, Codable, Hashable {
    case kanjiToReading
    case readingToKanji
}

struct KanjiQuizQuestion: Identifiable, Hashable {
    let id = UUID()
    let mode: KanjiQuizMode
    let prompt: String
    let correctAnswer: String
    let options: [String]
    let sourceKanji: KanjiItem
}
