import SwiftUI

struct GrammarView: View {
    private let repository = GrammarRepository.shared
    @StateObject private var progressStore = StudyProgressStore.shared

    private var continueIndex: Int {
        progressStore.lastIndex(for: "grammar.all", total: repository.grammarItems.count)
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    GrammarStudyView(items: repository.grammarItems, initialIndex: continueIndex, sourceID: "grammar.all")
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Continue Learning")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(repository.grammarItems[safe: continueIndex]?.displayTitle ?? "Start grammar")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        Spacer()
                        Text("\(progressStore.completedCount(for: .grammar, total: repository.grammarItems.count))/\(repository.grammarItems.count)")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .foregroundStyle(.white)
                            .background(Color.blue.opacity(0.22), in: Capsule())
                    }
                }
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(repository.sections) { section in
                    DisclosureGroup {
                        ForEach(section.items) { item in
                            NavigationLink {
                                GrammarStudyView(items: section.items, initialIndex: section.items.firstIndex(of: item) ?? 0, sourceID: "grammar.section.\(section.id)")
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.displayTitle)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    if let example = item.examples.first {
                                        Text(example.japanese)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundStyle(.white.opacity(0.65))
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("\(section.items.count) grammar points")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                            Spacer()
                            Text("\(section.items.count)")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .foregroundStyle(.white)
                                .background(Color.blue.opacity(0.22), in: Capsule())
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            } header: {
                Text("Grammar Lessons")
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppThemeBackground())
        .navigationTitle("Grammar")
        .navigationBarTitleDisplayMode(.inline)
        .appThemeScreen()
    }
}

struct GrammarStudyView: View {
    let items: [GrammarItem]
    let initialIndex: Int
    let sourceID: String

    @StateObject private var progressStore = StudyProgressStore.shared
    @State private var currentIndex: Int
    @State private var selectedAnswer = ""
    @State private var feedback = ""

    init(items: [GrammarItem], initialIndex: Int, sourceID: String) {
        self.items = items
        self.initialIndex = initialIndex
        self.sourceID = sourceID
        _currentIndex = State(initialValue: initialIndex)
    }

    private var currentItem: GrammarItem? {
        items[safe: currentIndex]
    }

    var body: some View {
        ZStack {
            AppThemeBackground()

            if let item = currentItem {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(currentIndex + 1) / \(items.count)")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.65))
                            .frame(maxWidth: .infinity, alignment: .center)

                        explanationCard(item)
                        examplesCard(item)
                        exerciseCard(item)
                        navigationControls(item)
                    }
                    .padding(16)
                }
            } else {
                ContentUnavailableView("No Grammar", systemImage: "text.book.closed")
                    .foregroundStyle(.white)
            }
        }
        .navigationTitle(currentItem?.id ?? "Grammar")
        .navigationBarTitleDisplayMode(.inline)
        .appThemeScreen()
        .onAppear {
            currentIndex = progressStore.lastIndex(for: sourceID, total: items.count)
            if currentIndex == 0 {
                currentIndex = min(initialIndex, max(items.count - 1, 0))
            }
        }
    }

    private func explanationCard(_ item: GrammarItem) -> some View {
        AppThemePanel {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.displayTitle)
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                lessonRow(title: "Meaning / Use", value: item.title)
                lessonRow(title: "How it works", value: item.pattern)
            }
        }
    }

    private func examplesCard(_ item: GrammarItem) -> some View {
        AppThemePanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("Examples")
                    .font(.headline)
                    .foregroundStyle(.white)

                if item.examples.isEmpty {
                    Text("No examples available yet.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                } else {
                    ForEach(Array(item.examples.enumerated()), id: \.offset) { _, example in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(example.japanese)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Text(example.english)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                        }
                    }
                }
            }
        }
    }

    private func exerciseCard(_ item: GrammarItem) -> some View {
        AppThemePanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Exercise")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(exercisePrompt(for: item))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))

                ForEach(exerciseOptions(for: item), id: \.self) { option in
                    Button(option) {
                        selectedAnswer = option
                        feedback = option == item.pattern ? "Correct!" : "Try again."
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tint(selectedAnswer == option ? (feedback == "Correct!" ? .green : .red) : .yellow)
                }

                if feedback.isEmpty == false {
                    Text(feedback)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(feedback == "Correct!" ? .green : .red)
                }
            }
        }
    }

    private func navigationControls(_ item: GrammarItem) -> some View {
        VStack(spacing: 12) {
            Button("Complete Lesson") {
                progressStore.markCompleted(track: .grammar, itemID: item.id)
                moveNext()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                Button("Previous") {
                    currentIndex = (currentIndex - 1 + items.count) % items.count
                    savePosition()
                    resetExercise()
                }
                .buttonStyle(.bordered)

                Button("Next") {
                    moveNext()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func lessonRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(.body)
                .foregroundStyle(.white)
        }
    }

    private func exercisePrompt(for item: GrammarItem) -> String {
        if let example = item.examples.first {
            return "Which grammar point is used here?\n\(example.japanese)"
        }
        return "Choose the matching grammar pattern."
    }

    private func exerciseOptions(for item: GrammarItem) -> [String] {
        var options = [item.pattern]
        let distractors = items
            .filter { $0.id != item.id }
            .map(\.pattern)
            .shuffled()

        for distractor in distractors where options.count < 4 {
            if options.contains(distractor) == false {
                options.append(distractor)
            }
        }

        return options.shuffled()
    }

    private func moveNext() {
        guard items.isEmpty == false else { return }
        currentIndex = (currentIndex + 1) % items.count
        savePosition()
        resetExercise()
    }

    private func savePosition() {
        progressStore.saveLastIndex(currentIndex, sourceID: sourceID, total: items.count)
        if sourceID != "grammar.all",
           let item = currentItem,
           let globalIndex = GrammarRepository.shared.grammarItems.firstIndex(of: item) {
            progressStore.saveLastIndex(globalIndex, sourceID: "grammar.all", total: GrammarRepository.shared.grammarItems.count)
        }
    }

    private func resetExercise() {
        selectedAnswer = ""
        feedback = ""
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    NavigationStack {
        GrammarView()
    }
}
