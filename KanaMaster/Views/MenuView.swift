//
//  MenuView.swift
//  KanaMaster
//
//  Created by robert gost montoliu on 2/4/25.
//

import SwiftUI

struct MenuView: View {
    var body: some View {
        ZStack {
            AppThemeBackground()

            List {
                Section {
                    VStack(spacing: 10) {
                        Image("AppIconStart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                        Text("KanaMaster")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text("Learn Japanese kana, kanji, vocabulary and grammar")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                Section {
                    NavigationLink {
                        HiraganaView()
                    } label: {
                        MenuRow(
                            title: "Hiragana",
                            subtitle: "Practise the basic Japanese syllabary",
                            image: "HiraganaIcon",
                            tint: .pink
                        )
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    NavigationLink {
                        KatakanaView()
                    } label: {
                        MenuRow(
                            title: "Katakana",
                            subtitle: "Practise katakana characters",
                            image: "KatakanaIcon",
                            tint: .purple
                        )
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    NavigationLink {
                        KanjiView()
                    } label: {
                        MenuRow(
                            title: "Kanji",
                            subtitle: "Browse kanji by JLPT level",
                            image: "KanjiIcon",
                            tint: .orange
                        )
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    NavigationLink {
                        VocabularyView()
                    } label: {
                        MenuRow(
                            title: "Vocabulary",
                            subtitle: "Study words and build custom groups",
                            image: "VocabularyIcon",
                            tint: .green
                        )
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    NavigationLink {
                        GrammarView()
                    } label: {
                        MenuRow(
                            title: "Grammar",
                            subtitle: "Learn grammar points with examples",
                            image: "VerbsIcon",
                            tint: .blue
                        )
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                } header: {
                    Text("Study")
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Menu")
        .navigationBarTitleDisplayMode(.inline)
        .appThemeScreen()
    }
}

private struct MenuRow: View {
    let title: String
    let subtitle: String
    let image: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(8)
                .background(tint.opacity(0.2), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        MenuView()
    }
}
