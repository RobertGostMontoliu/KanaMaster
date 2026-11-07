import SwiftUI

enum VocabularyStudySource: Hashable {
    case level(String)
    case custom(groupID: UUID)
}

struct VocabularyStudyGroupView: View {
    enum StudyTab: String, CaseIterable, Identifiable {
        case flashcards = "FlashCards"
        case test = "Test"
        case customizable = "Customizable"
        var id: String { rawValue }
    }

    let source: VocabularyStudySource

    @StateObject private var customGroupStore = VocabularyCustomGroupStore.shared
    private let repository = VocabularyRepository.shared

    @State private var selectedTab: StudyTab = .flashcards
    @State private var flashcardIndex = 0
    @State private var flashcardFlipped = false
    @State private var flashcardShuffle = false
    @State private var quizQuestion: (prompt: String, options: [String], answer: String)?
    @State private var quizAnswer = ""
    @State private var feedback = ""
    @State private var answeredCorrect = 0
    @State private var answeredWrong = 0
    @State private var searchQuery = ""
    @State private var selectedWords = Set<String>()
    @State private var targetGroupID: UUID?
    @State private var newGroupName = ""
    @State private var renameValue = ""
    @State private var showDeleteConfirm = false

    private var title: String {
        switch source {
        case .level(let level): return "Vocabulary: \(level)"
        case .custom(let groupID): return customGroupStore.group(id: groupID)?.name ?? "Custom Group"
        }
    }

    private var currentItems: [VocabularyItem] {
        switch source {
        case .level(let level): return repository.vocabulary(for: level)
        case .custom(let groupID):
            let words = customGroupStore.group(id: groupID)?.vocabularyWords ?? []
            return words.compactMap { word in repository.vocabularyItems.first(where: { $0.word == word }) }
        }
    }

    private var flashcardItems: [VocabularyItem] {
        guard flashcardShuffle == false else {
            return currentItems.shuffled()
        }
        return currentItems
    }

    private var filteredSearchItems: [VocabularyItem] {
        let sourceItems = searchQuery.isEmpty ? repository.vocabularyItems : repository.searchVocabulary(query: searchQuery)
        return sourceItems.filter { item in
            switch source {
            case .level: return true
            case .custom(let groupID):
                let currentWords = Set(customGroupStore.group(id: groupID)?.vocabularyWords ?? [])
                return currentWords.contains(item.word) == false
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("Tab", selection: $selectedTab) {
                ForEach(StudyTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            switch selectedTab {
            case .flashcards:
                flashcardsTab
            case .test:
                testTab
            case .customizable:
                customizableTab
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            targetGroupID = customGroupStore.groups.first?.id
            renameValue = title
            generateQuizQuestion()
        }
    }

    private var flashcardsTab: some View {
        VStack(spacing: 12) {
            if flashcardItems.isEmpty {
                ContentUnavailableView("No Vocabulary", systemImage: "character.book.closed")
            } else {
                let item = flashcardItems[min(flashcardIndex, max(flashcardItems.count - 1, 0))]
                VStack(spacing: 12) {
                    flashcard(item: item)
                    Text("\(flashcardIndex + 1) / \(flashcardItems.count)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Button("Previous") {
                            flashcardIndex = (flashcardIndex - 1 + flashcardItems.count) % flashcardItems.count
                            flashcardFlipped = false
                        }
                        .buttonStyle(.bordered)
                        Button("Next") {
                            flashcardIndex = (flashcardIndex + 1) % flashcardItems.count
                            flashcardFlipped = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Toggle("Shuffle", isOn: $flashcardShuffle)
                        .padding(.horizontal)
                }
                .padding(.horizontal)
            }
            Spacer(minLength: 0)
        }
    }

    private func flashcard(item: VocabularyItem) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
            .frame(height: 180)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(uiColor: .separator).opacity(0.4), lineWidth: 1)
            )
            .overlay {
                VStack(spacing: 12) {
                    Text(item.word)
                        .font(.system(size: 50, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.primary)
                    if flashcardFlipped {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.reading)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(item.meaning)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 1)
                        )
                    } else {
                        Text("Tap to flip")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onTapGesture {
                flashcardFlipped.toggle()
            }
    }

    private var testTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let quizQuestion {
                Text("What is the meaning of:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(quizQuestion.prompt)
                    .font(.system(size: 42, weight: .bold))
                ForEach(quizQuestion.options, id: \.self) { opt in
                    Button(opt) {
                        answerQuiz(opt)
                    }
                    .buttonStyle(.bordered)
                }
                if !feedback.isEmpty {
                    Text(feedback)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(feedback.hasPrefix("Correct") ? .green : .red)
                }
                HStack {
                    Text("Score: \(answeredCorrect) correct / \(answeredWrong) wrong")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Next") { generateQuizQuestion() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ContentUnavailableView("No Questions", systemImage: "questionmark.circle")
            }
        }
        .padding()
    }

    private var customizableTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                switch source {
                case .level:
                    vocabularyCustomizableSection
                case .custom(let groupID):
                    customGroupManageSection(groupID: groupID)
                }
                Divider()
                Text("Search Vocabulary")
                    .font(.headline)
                TextField("Search by word, reading, meaning", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                LazyVStack(spacing: 8) {
                    ForEach(filteredSearchItems.prefix(80)) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(item.word)  \(item.reading)")
                                    .font(.subheadline.weight(.semibold))
                                Text(item.meaning)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedWords.contains(item.word) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedWords.contains(item.word) {
                                selectedWords.remove(item.word)
                            } else {
                                selectedWords.insert(item.word)
                            }
                        }
                        .padding(10)
                        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .padding()
        }
    }

    private var vocabularyCustomizableSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add selected words to a custom group")
                .font(.headline)
            Picker("Target Group", selection: Binding(get: { targetGroupID ?? customGroupStore.groups.first?.id }, set: { targetGroupID = $0 })) {
                ForEach(customGroupStore.groups) { group in
                    Text(group.name).tag(Optional(group.id))
                }
            }
            .pickerStyle(.menu)
            HStack {
                Button("Add Selected") {
                    guard let targetGroupID else { return }
                    customGroupStore.addWords(Array(selectedWords), toGroupID: targetGroupID)
                    selectedWords.removeAll()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedWords.isEmpty || targetGroupID == nil)
                Spacer()
                Text("Selected: \(selectedWords.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
            Text("Create new group from selection")
                .font(.headline)
            TextField("New group name", text: $newGroupName)
                .textFieldStyle(.roundedBorder)
            Button("Create Group") {
                customGroupStore.createGroup(name: newGroupName, vocabularyWords: Array(selectedWords))
                newGroupName = ""
                selectedWords.removeAll()
                targetGroupID = customGroupStore.groups.first?.id
            }
            .buttonStyle(.bordered)
            .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func customGroupManageSection(groupID: UUID) -> some View {
        let group = customGroupStore.group(id: groupID)
        let words = group?.vocabularyWords ?? []
        return VStack(alignment: .leading, spacing: 10) {
            Text("Manage Group")
                .font(.headline)
            TextField("Group name", text: $renameValue)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Rename") {
                    customGroupStore.renameGroup(id: groupID, to: renameValue)
                }
                .buttonStyle(.bordered)
                Button("Delete Group", role: .destructive) {
                    showDeleteConfirm = true
                }
                .buttonStyle(.bordered)
            }
            if words.isEmpty {
                Text("This group is empty.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Current Words")
                    .font(.subheadline.weight(.semibold))
                FlowLayout(items: words) { word in
                    Button {
                        customGroupStore.removeWords([word], fromGroupID: groupID)
                    } label: {
                        Text(word)
                            .font(.headline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.2), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .alert("Delete this group?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { customGroupStore.deleteGroup(id: groupID) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the folder and its vocabulary list.")
        }
    }

    private func generateQuizQuestion() {
        guard currentItems.count >= 4 else { quizQuestion = nil; return }
        let answerIdx = Int.random(in: 0..<currentItems.count)
        let answer = currentItems[answerIdx]
        var options = [answer.meaning]
        while options.count < 4 {
            let opt = currentItems.randomElement()!.meaning
            if !options.contains(opt) { options.append(opt) }
        }
        options.shuffle()
        quizQuestion = (prompt: answer.word, options: options, answer: answer.meaning)
        feedback = ""
        quizAnswer = ""
    }
    private func answerQuiz(_ answer: String) {
        guard let quizQuestion else { return }
        if answer == quizQuestion.answer {
            answeredCorrect += 1
            feedback = "Correct!"
        } else {
            answeredWrong += 1
            feedback = "Wrong. Correct: \(quizQuestion.answer)"
        }
    }
}

private struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content
    init(items: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.content = content
    }
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
            }
        }
    }
}

#Preview {
    NavigationStack {
        VocabularyStudyGroupView(source: .level("1-1"))
    }
}
