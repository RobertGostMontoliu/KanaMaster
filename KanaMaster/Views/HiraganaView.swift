//
//  HiraganaView.swift
//  KanaMaster
//

import SwiftUI

struct KanaCard: Identifiable, Hashable {
    let id = UUID()
    let question: String
    let answer: String
}

struct CardView: View {
    let card: KanaCard
    var onNext: (() -> Void)? = nil

    @State private var userAnswer = ""
    @State private var isCorrect: Bool?

    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(width: 300, height: 200)
                .overlay(
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.yellow, lineWidth: 4)
                        Text(card.question)
                            .font(.system(size: 80))
                            .foregroundColor(.black)
                    }
                )

            TextField("Enter romaji", text: $userAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .foregroundColor(.black)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit(checkAnswer)

            Button("Check", action: checkAnswer)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
                .disabled(userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let isCorrect {
                Text(isCorrect ? "Correct!" : "Try again")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.headline)

                if isCorrect, let onNext {
                    Button("Next", action: onNext)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onChange(of: card.id) { _, _ in
            userAnswer = ""
            isCorrect = nil
        }
    }

    private func checkAnswer() {
        let normalized = userAnswer
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        isCorrect = normalized == card.answer.lowercased()
    }
}

struct KanaQuizView: View {
    let title: String
    let dictionary: [String: String]

    @State private var cards: [KanaCard] = []
    @State private var index = 0

    private var currentCard: KanaCard? {
        guard cards.indices.contains(index) else { return nil }
        return cards[index]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let currentCard {
                VStack(spacing: 12) {
                    CardView(card: currentCard, onNext: next)

                    Text("\(index + 1) / \(cards.count)")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .appThemeScreen()
        .onAppear(perform: loadCardsIfNeeded)
    }

    private func loadCardsIfNeeded() {
        guard cards.isEmpty else { return }
        cards = dictionary
            .map { KanaCard(question: $0.key, answer: $0.value) }
            .shuffled()
    }

    private func next() {
        guard cards.isEmpty == false else { return }
        index = (index + 1) % cards.count
    }
}

struct HiraganaView: View {
    var body: some View {
        KanaQuizView(title: "Hiragana", dictionary: hiraganaDictionary)
    }
}

struct KatakanaView: View {
    var body: some View {
        KanaQuizView(title: "Katakana", dictionary: katakanaDictionary)
    }
}

struct CardsContainer: View {
    var body: some View {
        KanaQuizView(title: "Hiragana", dictionary: hiraganaDictionary)
    }
}

#Preview {
    NavigationStack {
        CardsContainer()
    }
}
