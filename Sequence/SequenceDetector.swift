//
//  SequenceDetector.swift
//  Sequence
//
//  Created by Kyle Johnson on 12/3/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

// This class was created to hold one gigantic method to detect any length of sequence on a 10x10 game board. Detects horizontal, vertical, and diagonal sequences.

class SequenceDetector {
    
    let sequence = 5
    
    func isValidSequence(_ cardsOnBoard: [Card], _ currentPlayer: Int) -> Bool {
        
        // MARK: - Horizontal Sequences
        
        var length = 0
        for column in 0..<10 {
            for row in 0..<10 {
                let current = (column * 10) + row
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                } else {
                    length = 0
                }
                if length == sequence {
                    return true
                }
            }
            length = 0
        }
        
        // MARK: - Vertical Sequences
        
        length = 0
        for row in 0..<10 {
            for column in 0..<10 {
                let current = (column * 10) + row
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                } else {
                    length = 0
                }
                if length == sequence {
                    return true
                }
            }
            length = 0
        }
        
        // MARK: - Diagonal Sequences
        
        // MARK: left up right
        length = 0
        for left in 1...9 {
            var current = left * 10
            while (current > 0) {
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                } else {
                    length = 0
                }
                if length == sequence {
                    return true
                }
                current -= 9
            }
        }
        
        // MARK: btm up right
        length = 0
        for btm in 91...98 {
            var current = btm
            while (current > 0) {
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                } else {
                    length = 0
                }
                if length == sequence {
                    return true
                }
                current -= 9
            }
        }
        
        // MARK: left down right
        length = 0
        for left in 0...8 {
            var current = left * 10
            while (current < 100) {
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                } else {
                    length = 0
                }
                if length == sequence {
                    return true
                }
                current += 11
            }
        }
        
        // MARK: top down right
        length = 0
        for top in 1...8 {
            var current = top
            while (current < 100) {
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                } else {
                    length = 0
                }
                if length == sequence {
                    return true
                }
                current += 11
            }
        }
        
        return false
    }
}
