//
//  ViewController.swift
//  Sequence
//
//  Created by Kyle Johnson on 11/23/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit
import GameplayKit

// MARK: - Main Class

class ViewController: UIViewController {
    
    @IBOutlet weak var playerTurnLabel: UILabel!
    @IBOutlet weak var cardsLeftLabel: UILabel!
    @IBOutlet weak var playerIndicator: UIImageView!
    
    let suits = ["C", "D", "H", "S"]

    let cardsLayout = ["B0", "C10", "C9", "C8", "C7", "H7", "H8", "H9", "H10", "B0",
                 "D10", "D13", "C6", "C5", "C4", "H4", "H5", "H6", "S13", "S10",
                 "D9", "D6", "D12", "C3", "C2", "H2", "H3", "S12", "S6", "S9",
                 "D8", "D5", "D3", "C12", "C1", "H1", "H12", "S3", "S5", "S8",
                 "D7", "D4", "D2", "D1", "C13", "H13", "S1", "S2", "S4", "S7",
                 "S7", "S4", "S2", "S1", "H13", "C13", "D1", "D2", "D4", "D7",
                 "S8", "S5", "S3", "H12", "H1", "C1", "C12", "D3", "D5", "D8",
                 "S9", "S6", "S12", "H3", "H2", "C2", "C3", "D12", "D6", "D9",
                 "S10", "S13", "H6", "H5", "H4", "C4", "C5", "C6", "D13", "D10",
                 "B0", "H10", "H9", "H8", "H7", "C7", "C8", "C9", "C10", "B0"]
    
    // 10x10 grid -- 100 cards total (ignoring jacks)
    var cardsOnBoard = [Card]()
    
    // 2 decks -- 104 cards total (ignoring blanks)
    var cardsInDeck = [Card]() {
        didSet {
            cardsLeftLabel.text = "\(cardsInDeck.count) left"
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
                boardOutline.layer.borderWidth = 0
            }
        }
    }
    var chosenCardIndex = -1
    var chosenCardId = ""

    var boardOutline = UIView()
    
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
        drawCardsForHands()
        createDeck()
    }
    
    func generateBoard() {
        boardOutline.frame = CGRect(x: 11, y: 133, width: 354, height: 354)
        boardOutline.layer.borderColor = UIColor.green.cgColor
        boardOutline.layer.borderWidth = 0
        view.addSubview(boardOutline)
        
        // add the 100 cards to board in correct order
        var i = 0
        for row in 1...10 {
            for col in 1...10 {
                let card = Card(named: cardsLayout[i])
                card.frame = CGRect(x: (col * 35) - 22, y: (row * 35) + 100, width: 35, height: 35)
                view.addSubview(card)
                cardsOnBoard.append(card)
                i += 1
            }
        }
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
    
    func drawCardsForHands() {
        // choose five cards from the deck for player 1
        for col in 1...5 {
            if let card = self.cardsInDeck.popLast() {
                card.frame = CGRect(x: (col * 35) + 13, y: 520, width: 35, height: 43)
                cardsInHand1.append(card)
                view.addSubview(card)      // show Player 1's cards first
            }
        }
        
        // choose five cards from the deck for player 2
        for col in 1...5 {
            if let card = cardsInDeck.popLast() {
                card.frame = CGRect(x: (col * 35) + 13, y: 520, width: 35, height: 43)
                cardsInHand2.append(card)
            }
        }
    }
    
    func createDeck() {
        // TODO: Make larger and animate transition
        let deck = Card(named: "B0-")
        deck.frame = CGRect(x: 293, y: 520, width: 35, height: 43)
        view.addSubview(deck)
    }
    
    // MARK: - Gameplay
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self.view)
            
            var cardsInHand = getCurrentHand()
            for c in cardsOnBoard {
                if ((c.isSelected || isJack()) && c.frame.contains(touchLocation)) {
                    
                    c.owner = currentPlayer
                    c.isMarked = true
                    
                    let blank = Card(named: "B0-")
                    blank.frame = CGRect(x: 293, y: 520, width: 35, height: 43)
                    view.addSubview(blank)
                    
                    // TODO: Check for valid sequence here
                    
                    UIView.animate(withDuration: 1, delay: 0.75, options: [.curveEaseOut], animations: {
                        blank.frame.origin = cardsInHand[self.chosenCardIndex].frame.origin
                        cardsInHand[self.chosenCardIndex].removeFromSuperview()
                        
                    }, completion: { _ in
                        blank.removeFromSuperview()
                        if let nextCard = self.getNextCardFromDeck() {
                            cardsInHand[self.chosenCardIndex] = nextCard
                        }
                    })
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.75) {
                        for card in cardsInHand {
                            card.removeFromSuperview()
                        }
                        self.swapPlayers(cardsInHand)
                    }
                }
            }
            
            cardChosen = false
            chosenCardId = ""
            
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
                        boardOutline.layer.borderWidth = 2
                    } else {
                        boardOutline.layer.borderWidth = 0
                    }
                }
            }
        }
    }
    
    func getCurrentHand() -> [Card] {
        if currentPlayer == 1 {
            return cardsInHand1
        } else {
            return cardsInHand2
        }
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
        if currentPlayer == 1 {
            cardsInHand1 = hand
            currentPlayer = 2
            for i in 0..<5 {
                self.cardsInHand2[i].frame = CGRect(x: ((i+1) * 35) + 13, y: 520, width: 35, height: 43)
                self.view.addSubview(self.cardsInHand2[i])
            }
        } else {
            cardsInHand2 = hand
            currentPlayer = 1
            for i in 0..<5 {
                self.cardsInHand1[i].frame = CGRect(x: ((i+1) * 35) + 13, y: 520, width: 35, height: 43)
                self.view.addSubview(self.cardsInHand1[i])
            }
        }
    }
    
    func isJack() -> Bool {
        return (chosenCardId == "C11-" || chosenCardId == "D11-" || chosenCardId == "H11-" || chosenCardId == "S11-")
    }
}

// MARK: - Card Class

class Card: UIImageView {
    var id: String
    var isSelected: Bool {
        didSet {
            if isSelected == true {
                self.layer.borderWidth = 2
            } else {
                self.layer.borderWidth = 0
            }
        }
    }
    
    var owner: Int
    var isMarked: Bool {
        didSet {
            guard owner != 0 else { return }
            var color = ""
            if owner == 1 {
                color = "orange"
            } else {
                color = "blue"
            }
            let image = UIImage(named: color)
            let marker = UIImageView(image: image)
            marker.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
            self.addSubview(marker)
        }
    }
    
    init(named id: String) {
        self.id = id
        self.isSelected = false
        self.owner = 0
        self.isMarked = false
        
        let image = UIImage(named: id)
        super.init(image: image)
        
        self.layer.borderColor = UIColor.green.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

