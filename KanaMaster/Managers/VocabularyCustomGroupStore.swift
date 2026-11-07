import Foundation
import SwiftUI

struct VocabularyCustomGroup: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var vocabularyWords: [String]
    var createdAt: Date
    var updatedAt: Date
}

final class VocabularyCustomGroupStore: ObservableObject {
    static let shared = VocabularyCustomGroupStore()

    @Published private(set) var groups: [VocabularyCustomGroup] = []
    private let storageKey = "vocab_custom_groups_v1"

    private init() { load() }

    func group(id: UUID) -> VocabularyCustomGroup? {
        groups.first(where: { $0.id == id })
    }

    func createGroup(name: String, vocabularyWords: [String] = []) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        let now = Date()
        let group = VocabularyCustomGroup(id: UUID(), name: trimmed, vocabularyWords: Array(Set(vocabularyWords)).sorted(), createdAt: now, updatedAt: now)
        groups.append(group)
        groups.sort { $0.updatedAt > $1.updatedAt }
        save()
    }

    func renameGroup(id: UUID, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false,
              let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index].name = trimmed
        groups[index].updatedAt = Date()
        save()
    }

    func deleteGroup(id: UUID) {
        groups.removeAll(where: { $0.id == id })
        save()
    }

    func addWords(_ words: [String], toGroupID id: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        var merged = Set(groups[index].vocabularyWords)
        merged.formUnion(words.filter { $0.isEmpty == false })
        groups[index].vocabularyWords = Array(merged).sorted()
        groups[index].updatedAt = Date()
        save()
    }

    func removeWords(_ words: [String], fromGroupID id: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        let removeSet = Set(words)
        groups[index].vocabularyWords.removeAll(where: { removeSet.contains($0) })
        groups[index].updatedAt = Date()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            groups = []
            return
        }
        do {
            groups = try JSONDecoder().decode([VocabularyCustomGroup].self, from: data)
        } catch {
            groups = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(groups)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {}
    }
}
