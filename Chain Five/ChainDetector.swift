//
//  ChainDetector.swift
//  Chain Five
//
//  Created by Kyle Johnson on 12/3/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

/// This class was created to hold one gigantic method to detect any length of chain on a 10x10 game board. Detects horizontal, vertical, and diagonal chains. Also keeps track of the winning indices.
class ChainDetector {
    
    let chain = 5
    
    func isValidChain(_ cardsOnBoard: [Card], _ currentPlayer: Int) -> (Bool, [Int]) {
        
        var winningIndices: [Int] = []
        var length = Int() {
            didSet {
                if length == 0 {
                    winningIndices = []
                }
            }
        }
        
        // MARK: - Horizontal Chains
        length = 0
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
                }
                if length == chain {
                    print("horizontal chain")
                    print(winningIndices)
                    return (true, winningIndices)
                }
            }
            length = 0
        }
        
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
                }
                if length == chain {
                    print("vertical chain")
                    print(winningIndices)
                    return (true, winningIndices)
                }
            }
            length = 0
        }
        
        // MARK: - Diagonal Chains
        var iterations: Int
        
        // left up right
        length = 0
        iterations = 0
        for left in 1...8 {
            var current = (left * 10)
            while (iterations < left + 1) {
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                    if cardsOnBoard[current].isFreeSpace {
                        cardsOnBoard[current].owner = currentPlayer
                    }
                    winningIndices.append(current)
                } else {
                    length = 0
                }
                if length == chain {
                    print("diagonal left up right")
                    print(winningIndices)
                    return (true, winningIndices)
                }
                current -= 9
                iterations += 1
            }
            length = 0
            iterations = 0
        }
        
        // btm up right
        length = 0
        iterations = 0
        for btm in 0...8 {
            var current = 90 + btm
            while (iterations < 10 - btm) {
                if cardsOnBoard[current].isFreeSpace || (cardsOnBoard[current].isMarked && cardsOnBoard[current].owner == currentPlayer) {
                    length += 1
                    if cardsOnBoard[current].isFreeSpace {
                        cardsOnBoard[current].owner = currentPlayer
                    }
                    winningIndices.append(current)
                } else {
                    length = 0
                }
                if length == chain {
                    print("diagonal btm up right")
                    print(winningIndices)
                    return (true, winningIndices)
                }
                current -= 9
                iterations += 1
            }
            length = 0
            iterations = 0
        }
        
        // left down right
        length = 0
        iterations = 0
        for left in (1...8).reversed() {
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
        
        // top down right
        length = 0
        iterations = 0
        for top in 0...8 {
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
        
        return (false, winningIndices)
    }
}

