//
//  Cards.swift
//  KanaMaster
//
//  Created by robert gost montoliu on 2/4/07 Reiwa.
//

import Foundation

func cards() -> [(question: String, answer: String)] {
    // Convert dictionary to array of tuples
    let cardPairs = Array(hiraganaDictionary)
    
    // Shuffle and take all pairs
    let shuffledPairs = cardPairs.shuffled()
    
    // Convert to required format
    return shuffledPairs.map { pair in
        (question: pair.key, answer: pair.value)
    }
}
