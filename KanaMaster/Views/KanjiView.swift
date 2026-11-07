//
//  KanjiView.swift
//  KanaMaster
//

import SwiftUI

struct KanjiView: View {
    private var availableLevels: [JLPTLevel] {
        JLPTLevel.allCases.filter { level in
            Bundle.main.url(forResource: "kanji_n\(level.jlptValue)_final_v3", withExtension: "json") != nil
        }
    }

    var body: some View {
        ZStack {
            AppThemeBackground()

            List {
                Section {
                    ForEach(availableLevels, id: \.self) { level in
                        NavigationLink {
                            KanjiLevelView(level: level)
                        } label: {
                            HStack {
                                Text(level.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }
                } header: {
                    Text("JLPT Levels")
                        .foregroundStyle(.white.opacity(0.72))
                } footer: {
                    Text("Choose a level to browse its kanji.")
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Kanji")
        .navigationBarTitleDisplayMode(.inline)
        .appThemeScreen()
    }
}

struct KanjiLevelView: View {
    let level: JLPTLevel

    private let repository = KanjiRepository.shared

    @State private var items: [KanjiItem] = []
    @State private var searchText = ""
    @State private var isLoading = true

    private var filteredItems: [KanjiItem] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard needle.isEmpty == false else { return items }

        return items.filter { item in
            item.kanji.contains(needle)
            || item.primaryMeaning.lowercased().contains(needle)
            || item.meanings.joined(separator: " ").lowercased().contains(needle)
            || item.allReadings.joined(separator: " ").contains(needle)
            || (item.heisigEn?.lowercased().contains(needle) ?? false)
        }
    }

    var body: some View {
        ZStack {
            AppThemeBackground()

            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if filteredItems.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Kanji" : "No Results",
                        systemImage: "character.book.closed"
                    )
                    .foregroundStyle(.white)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            KanjiDetailView(item: item)
                        } label: {
                            KanjiRow(item: item)
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(level.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search kanji, reading or meaning")
        .appThemeScreen()
        .task {
            guard items.isEmpty else { return }
            items = repository.kanji(for: level)
            isLoading = false
        }
    }
}

private struct KanjiRow: View {
    let item: KanjiItem

    var body: some View {
        HStack(spacing: 14) {
            Text(item.kanji)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.primaryMeaning)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                let readings = item.allReadings.prefix(6).joined(separator: "、")
                if readings.isEmpty == false {
                    Text(readings)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct KanjiDetailView: View {
    let item: KanjiItem

    var body: some View {
        ZStack {
            AppThemeBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.kanji)
                        .font(.system(size: 96, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)

                    AppThemePanel {
                        VStack(alignment: .leading, spacing: 10) {
                            detailRow(title: "Meaning", value: item.meanings.joined(separator: ", "))
                            if item.kunReadings.isEmpty == false {
                                detailRow(title: "Kun reading", value: item.kunReadings.joined(separator: "、"))
                            }
                            if item.onReadings.isEmpty == false {
                                detailRow(title: "On reading", value: item.onReadings.joined(separator: "、"))
                            }
                            if let strokeCount = item.strokeCount {
                                detailRow(title: "Strokes", value: "\(strokeCount)")
                            }
                            if let heisig = item.heisigEn {
                                detailRow(title: "Heisig", value: heisig)
                            }
                        }
                    }

                    if item.vocabulary.isEmpty == false {
                        AppThemePanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Vocabulary")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                ForEach(item.vocabulary, id: \.self) { entry in
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(entry.word)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.white)
                                            Text(entry.reading)
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.65))
                                        }
                                        Text(entry.meanings.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.72))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(item.kanji)
        .navigationBarTitleDisplayMode(.inline)
        .appThemeScreen()
    }

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(.body)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    NavigationStack {
        KanjiView()
    }
}
