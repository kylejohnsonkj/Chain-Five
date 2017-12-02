//
//  GameViewController.swift
//  Sequence
//
//  Created by Kyle Johnson on 11/23/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit
import GameplayKit

// MARK: - Main Class

class GameViewController: UIViewController {
    
    @IBOutlet weak var gameTitle: UIImageView!
    @IBOutlet weak var gameHeader: UILabel!
    @IBOutlet weak var playerTurnLabel: UILabel!
    @IBOutlet weak var cardsLeftLabel: UILabel!
    @IBOutlet weak var playerIndicator: UIImageView!
    @IBOutlet weak var menuLabel: UILabel!
    @IBOutlet weak var menuIconLabel: UILabel!
    
    let suits = ["C", "D", "H", "S"]

    let cardsLayout = ["F0", "C10", "C9", "C8", "C7", "H7", "H8", "H9", "H10", "F0",
                 "D10", "D13", "C6", "C5", "C4", "H4", "H5", "H6", "S13", "S10",
                 "D9", "D6", "D12", "C3", "C2", "H2", "H3", "S12", "S6", "S9",
                  "D8", "D5", "D3", "C12", "C1", "H1", "H12", "S3", "S5", "S8",
                "D7", "D4", "D2", "D1", "C13", "H13", "S1", "S2", "S4", "S7",
                 "S7", "S4", "S2", "S1", "H13", "C13", "D1", "D2", "D4", "D7",
                 "S8", "S5", "S3", "H12", "H1", "C1", "C12", "D3", "D5", "D8",
                 "S9", "S6", "S12", "H3", "H2", "C2", "C3", "D12", "D6", "D9",
                 "S10", "S13", "H6", "H5", "H4", "C4", "C5", "C6", "D13", "D10",
                 "F0", "H10", "H9", "H8", "H7", "C7", "C8", "C9", "C10", "F0"]
    
    // 10x10 grid -- 100 cards total (ignoring jacks)
    var cardsOnBoard = [Card]()
    
    // 2 decks -- 104 cards total (ignoring blanks)
    var cardsInDeck = [Card]() {
        didSet {
            cardsLeftLabel.text = "\(cardsInDeck.count)"
        }
    }
    
    var cardsInHand1 = [Card]()
    var cardsInHand2 = [Card]()
    
    var cardChosen: Bool = false {
        didSet {
            if cardChosen == false {
                for c in cardsOnBoard {
                    c.isSelected = false
                }
                jackOutline.layer.borderWidth = 0
            }
        }
    }
    var chosenCardIndex = -1
    var chosenCardId = ""

    var jackOutline = UIView()
    var gameOver = UIView()
    
    var currentPlayer = 0 {
        didSet {
            playerTurnLabel.text = "Player \(currentPlayer)'s turn"
            if currentPlayer == 1 {
                playerIndicator.image = UIImage(named: "orange")
            } else {
                playerIndicator.image = UIImage(named: "blue")
            }
        }
    }
    
    // MARK: - Setup
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        generateBoard()
        currentPlayer = 1
        cardsInDeck = generateAndShuffleDeck()
        createDeckImage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [unowned self] in
            self.drawCardsForPlayer(1)
        }
        
    }
    
    func generateBoard() {
        
        playerIndicator.alpha = 0
        playerTurnLabel.alpha = 0
        cardsLeftLabel.alpha = 0
        menuLabel.alpha = 0
        menuIconLabel.alpha = 0
        
        // used for jack highlighting
        jackOutline.frame = CGRect(x: 10, y: 132, width: 356, height: 357)
        jackOutline.layer.borderColor = UIColor.green.cgColor
        jackOutline.layer.borderWidth = 0
        view.addSubview(jackOutline)
        
        // aesthetics
        let bottomBorder = UIView()
        bottomBorder.frame = CGRect(x: 13, y: 485, width: 350, height: 1)
        bottomBorder.layer.borderColor = UIColor(red: 63/255, green: 63/255, blue: 63/255, alpha: 1).cgColor
        bottomBorder.layer.borderWidth = 1
        view.addSubview(bottomBorder)
        
        // load the 100 cards
        var i = 0
        for row in 1...10 {
            for col in 1...10 {
                let card = Card(named: self.cardsLayout[i])
                card.frame = CGRect(x: (col * 35) - 22, y: (row * 35) + 100, width: 35, height: 35)
                self.view.addSubview(card)
                self.cardsOnBoard.append(card)
                i += 1
            }
        }

        cardsOnBoard[0].isFreeSpace = true      // top left
        cardsOnBoard[9].isFreeSpace = true      // top right
        cardsOnBoard[90].isFreeSpace = true     // btm left
        cardsOnBoard[99].isFreeSpace = true     // btm right
    }
    
    func generateAndShuffleDeck() -> [Card] {
        // generate two decks
        var j = 0
        while (j < 2) {
            for suit in 0..<suits.count {
                for rank in 1...13 {
                    let card = Card(named: "\(suits[suit])\(rank)-")
                    cardsInDeck.append(card)
                }
            }
            j += 1
        }
        
        // shuffle and return the cards
        return GKRandomSource.sharedRandom().arrayByShufflingObjects(in: cardsInDeck) as! [Card]
    }
    
    func createDeckImage() {
        let deck = Card(named: "B1-")
        deck.frame = CGRect(x: 293, y: 566, width: 35, height: 49)
        view.addSubview(deck)
    }
    
    func drawCardsForPlayer(_ player: Int) {
        
        // choose five cards from the deck for player 1
        for col in 1...5 {
            
            let container = UIView()
            container.frame = CGRect(x: 293, y: 566, width: 35, height: 43)
            container.layer.zPosition = 6 - CGFloat(col)
            view.addSubview(container)
            
            let back = Card(named: "B0-")
            back.frame = CGRect(x: 0, y: 0, width: 35, height: 43)
            back.layer.zPosition = 6 - CGFloat(col)
            container.addSubview(back)
            
            if let card = self.cardsInDeck.popLast() {
                
                UIView.animate(withDuration: 1, delay: TimeInterval(0.75 * Double(col)), options: [.curveEaseOut], animations: {
                    container.frame = CGRect(x: (col * 35) + 13, y: 520, width: 35, height: 43)
                    
                }, completion: { _ in
                    
                    container.frame = CGRect(x: (col * 35) + 13, y: 520, width: 35, height: 43)
                    card.frame = CGRect(x: 0, y: 0, width: 35, height: 43)
                    
                    if player == 1 {
                        self.cardsInHand1.append(card)
                    } else {
                        self.cardsInHand2.append(card)
                    }
                    
                    UIView.transition(from: back, to: card, duration: 1, options: [.transitionFlipFromRight], completion: { _ in
                        card.frame = CGRect(x: (col * 35) + 13, y: 520, width: 35, height: 43)
                        self.view.addSubview(card)
                    })
                    
                    if col == 5 {
                        UIView.animate(withDuration: 1) {
                            self.playerIndicator.alpha = 1
                            self.playerTurnLabel.alpha = 1
                            self.cardsLeftLabel.alpha = 1
                            self.menuLabel.alpha = 1
                            self.menuIconLabel.alpha = 1
                        }
                    }
                })
            }
        }
    }
    
    // MARK: - Gameplay
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self.view)
            
            if menuLabel.frame.contains(touchLocation) || menuIconLabel.frame.contains(touchLocation) {
                self.modalPresentationStyle = .overCurrentContext
                dismiss(animated: true)
            }
            
            var cardsInHand = getCurrentHand()
            for c in cardsOnBoard {
                if ((c.isSelected || isJack()) && !c.isFreeSpace && c.frame.contains(touchLocation)) {
                    
                    c.owner = currentPlayer
                    c.isMarked = true
                    
                    let container = UIView()
                    container.frame = CGRect(x: 293, y: 566, width: 35, height: 43)
                    view.addSubview(container)
                    
                    let blank = Card(named: "B0-")
                    blank.frame = CGRect(x: 0, y: 0, width: 35, height: 43)
                    container.addSubview(blank)
                    
                    if isValidSequence() {
                        let ac = UIAlertController(title: "It's a Sequence!", message: "Player \(currentPlayer) has won the game.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: hitOk))
                        self.present(ac, animated: true)
                        
                        gameOver.frame = view.frame
                        var bgColor: CGColor
                        if currentPlayer == 1 {
                            bgColor = UIColor(red: 255/255, green: 180/255, blue: 1/255, alpha: 1).cgColor
                        } else {
                            bgColor = UIColor(red: 94/255, green: 208/255, blue: 255/255, alpha: 1).cgColor
                        }
                        
                        gameOver.layer.backgroundColor = bgColor
                        gameOver.layer.zPosition = 2
                        view.addSubview(gameOver)
                        gameOver.alpha = 0
                        
                        UIView.animate(withDuration: 1.0, animations: {
                            self.gameOver.alpha = 1
                        })
                    }
                    
                    guard isValidSequence() == false else { return }
                    cardsLeftLabel.text = "\(cardsInDeck.count - 1)"
                    
                    UIView.animate(withDuration: 1, delay: 0.75, options: [.curveEaseOut], animations: {
                        container.frame.origin = cardsInHand[self.chosenCardIndex].frame.origin
                        cardsInHand[self.chosenCardIndex].removeFromSuperview()
                        
                    }, completion: { _ in
//                        blank.removeFromSuperview()
                        if let nextCard = self.getNextCardFromDeck() {
                            if self.currentPlayer == 1 {
                                self.cardsInHand1[self.chosenCardIndex] = nextCard
                            } else {
                                self.cardsInHand2[self.chosenCardIndex] = nextCard
                            }
                        
                            nextCard.frame = CGRect(x: 0, y: 0, width: 35, height: 43)
                            
                            UIView.transition(from: blank, to: nextCard, duration: 1, options: [.transitionFlipFromRight], completion: nil)
                        }
                        
                        if self.cardsInDeck.count >= 93 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [unowned self] in
                                self.drawCardsForPlayer(2)
                                self.cardsLeftLabel.text = "\(self.cardsInDeck.count + 5)"
                            }
                        }
                        self.swapPlayers(cardsInHand)
                    })
                    
                }
            }
            
            cardChosen = false
            chosenCardId = ""
            
            // needed for grabbing indices
            for i in 0..<cardsInHand.count {
                cardsInHand[i].isSelected = false
                
                if (cardsInHand[i].frame.contains(touchLocation)) {
                    cardsInHand[i].isSelected = true
                    
                    cardChosen = true
                    chosenCardIndex = i
                    chosenCardId = cardsInHand[i].id
                    
                    for c in cardsOnBoard {
                        c.isSelected = false
                        if !c.isMarked && chosenCardId == "\(c.id)-" {
                            c.isSelected = true
                        }
                    }
                    
                    // special case for jacks
                    if isJack() {
                        jackOutline.layer.borderWidth = 3
                    } else {
                        jackOutline.layer.borderWidth = 0
                    }
                }
            }
        }
    }
    
    func hitOk(action: UIAlertAction) {
        UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseOut], animations: {
            self.gameOver.alpha = 0.99
            self.gameOver.alpha = 1
        }, completion: { _ in
            self.gameOver.removeFromSuperview()
            self.modalPresentationStyle = .overCurrentContext
            self.dismiss(animated: true)
        })
    }
    
    func isValidSequence() -> Bool {
        
        var length = 0
        let sequence = 2    // TODO: Set to 5 for release
        
        // horizontal sequences
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
        
        // vertical sequences
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
        
        // TODO: diagonal sequences
        
        
        return false
    }
    
    func getCurrentHand() -> [Card] {
        return currentPlayer == 1 ? cardsInHand1 : cardsInHand2
    }
    
    func getNextCardFromDeck() -> Card? {
        // grab next card from deck
        if let nextCard = self.cardsInDeck.popLast() {
            nextCard.frame = CGRect(x: ((self.chosenCardIndex+1) * 35) + 13, y: 520, width: 35, height: 43)
            self.view.addSubview(nextCard)
            return nextCard
        }
        return nil
    }
    
    func swapPlayers(_ hand: [Card]) {
        
        var cardsInHand = getCurrentHand()
        
        UIView.animate(withDuration: 0.5, delay: 1.5, options: [], animations: {
            self.playerIndicator.alpha = 0
            self.playerTurnLabel.alpha = 0
            if self.cardsInDeck.count >= 93 {
                self.cardsLeftLabel.alpha = 0
            }
            
            for card in cardsInHand {
                card.alpha = 0
            }
            
        }, completion: { _ in
            
            for card in cardsInHand {
                card.removeFromSuperview()
            }
            
            if self.currentPlayer == 1 {
                self.cardsInHand1 = hand
                self.currentPlayer = 2
                if self.cardsInDeck.count < 93 {
                    for i in 0..<5 {
                        self.cardsInHand2[i].frame = CGRect(x: ((i+1) * 35) + 13, y: 520, width: 35, height: 43)
                        self.view.addSubview(self.cardsInHand2[i])
                    }
                }
            } else {
                self.cardsInHand2 = hand
                self.currentPlayer = 1
                for i in 0..<5 {
                    self.cardsInHand1[i].frame = CGRect(x: ((i+1) * 35) + 13, y: 520, width: 35, height: 43)
                    self.view.addSubview(self.cardsInHand1[i])
                }
            }
            
            cardsInHand = self.getCurrentHand()
            
            for card in cardsInHand {
                card.alpha = 0
            }
            
            UIView.animate(withDuration: 0.5, animations: {
                for card in cardsInHand {
                    card.alpha = 1
                }
                
                if self.cardsInDeck.count < 93 {
                    self.playerIndicator.alpha = 1
                    self.playerTurnLabel.alpha = 1
                }

            })
            
        })
    }
    
    func isJack() -> Bool {
        return (chosenCardId == "C11-" || chosenCardId == "D11-" || chosenCardId == "H11-" || chosenCardId == "S11-")
    }
}

