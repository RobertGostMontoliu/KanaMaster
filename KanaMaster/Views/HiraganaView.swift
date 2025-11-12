import SwiftUI

struct CardView: View {
    let card: (question: String, answer: String)
    @State private var userAnswer: String = ""
    @State private var isCorrect: Bool? = nil
    
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Question Card
                RoundedRectangle(cornerRadius: 10.0)
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
                
                // Answer Input
                TextField("Enter romanji", text: $userAnswer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                    .foregroundColor(.black)
                
                // Check Button
                Button("Check") {
                    isCorrect = userAnswer.lowercased() == card.answer.lowercased()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
                
                // Feedback Text
                if let isCorrect = isCorrect {
                    Text(isCorrect ? "Correct!" : "Try again")
                        .foregroundColor(isCorrect ? .green : .red)
                        .font(.headline)
                }
            }
        }
    }
}

struct CardsContainer: View {
    let cards: [(question: String, answer: String)] = Array(hiraganaDictionary).shuffled().map {
        (question: $0.key, answer: $0.value)
    }
    
    var body: some View {
        CardView(card: cards[0])
    }
}

#Preview {
    CardsContainer()
}
