//
//  ChainDetector.swift
//  Chain Five
//
//  Created by Kyle Johnson on 12/3/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

// This class was created to hold one gigantic method to detect any length of chain on a 10x10 game board. Detects horizontal, vertical, and diagonal chains.

class ChainDetector {
    
    let chain = 5
    
    func isValidChain(_ cardsOnBoard: [Card], _ currentPlayer: Int) -> (Bool, [Int]) {
        
        var winningIndices: [Int] = []
        
        // MARK: - Horizontal Chains
        var length = 0
        for column in 0..<10 {
            for row in 0..<10 {
                let current = (column * 10) + row
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                    if cardsOnBoard[current].isFreeSpace {
                        cardsOnBoard[current].owner = currentPlayer
                    }
                    winningIndices.append(current)
                } else {
                    length = 0
                    winningIndices = []
                }
                if length == chain {
                    print("horizontal chain")
                    print(winningIndices)
                    return (true, winningIndices)
                }
            }
            length = 0
        }
        winningIndices = []
        
        // MARK: - Vertical Chains
        length = 0
        for row in 0..<10 {
            for column in 0..<10 {
                let current = (column * 10) + row
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                    if cardsOnBoard[current].isFreeSpace {
                        cardsOnBoard[current].owner = currentPlayer
                    }
                    winningIndices.append(current)
                } else {
                    length = 0
                    winningIndices = []
                }
                if length == chain {
                    print("vertical chain")
                    print(winningIndices)
                    return (true, winningIndices)
                }
            }
            length = 0
        }
        winningIndices = []
        
        // MARK: - Diagonal Chains
        // top down left
        length = 0
        var iterations = 0
        for top in 1...9 {
            var current = top
            while (iterations < top + 1) {
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                    if cardsOnBoard[current].isFreeSpace {
                        cardsOnBoard[current].owner = currentPlayer
                    }
                    winningIndices.append(current)
                } else {
                    length = 0
                    winningIndices = []
                }
                if length == chain {
                    print("diagonal top down left")
                    print(winningIndices)
                    return (true, winningIndices)
                }
                current += 9
                iterations += 1
            }
            length = 0
            iterations = 0
        }
        winningIndices = []
        
        // right down left
        length = 0
        iterations = 0
        for right in 1...8 {
            var current = (right * 10) + 9
            while (iterations < 10 - right) {
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                    if cardsOnBoard[current].isFreeSpace {
                        cardsOnBoard[current].owner = currentPlayer
                    }
                    winningIndices.append(current)
                } else {
                    length = 0
                    winningIndices = []
                }
                if length == chain {
                    print("diagonal right down left")
                    print(winningIndices)
                    return (true, winningIndices)
                }
                current += 9
                iterations += 1
            }
            length = 0
            iterations = 0
        }
        winningIndices = []
        
        // top down right
        length = 0
        iterations = 0
        for top in (0...8).reversed() {
            var current = top
            while (iterations < 10 - top) {
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                    if cardsOnBoard[current].isFreeSpace {
                        cardsOnBoard[current].owner = currentPlayer
                    }
                    winningIndices.append(current)
                } else {
                    length = 0
                    winningIndices = []
                }
                if length == chain {
                    print("diagonal top down right")
                    print(winningIndices)
                    return (true, winningIndices)
                }
                current += 11
                iterations += 1
            }
            length = 0
            iterations = 0
        }
        winningIndices = []
        
        // left down right
        length = 0
        iterations = 0
        for left in 1...8 {
            var current = left * 10
            while (iterations < 10 - left) {
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                    if cardsOnBoard[current].isFreeSpace {
                        cardsOnBoard[current].owner = currentPlayer
                    }
                    winningIndices.append(current)
                } else {
                    length = 0
                    winningIndices = []
                }
                if length == chain {
                    print("diagonal left down right")
                    print(winningIndices)
                    return (true, winningIndices)
                }
                current += 11
                iterations += 1
            }
            length = 0
            iterations = 0
        }
        winningIndices = []
        
        return (false, winningIndices)
    }
}
