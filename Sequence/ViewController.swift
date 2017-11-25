//
//  ViewController.swift
//  Sequence
//
//  Created by Kyle Johnson on 11/23/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit
import GameplayKit

class ViewController: UIViewController {
    
    @IBOutlet weak var playerTurnLabel: UILabel!
    @IBOutlet weak var cardsLeftLabel: UILabel!
    
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
    var cardsInDeck = [Card]()
    
    // 5 at any time
    var cardsInHand1 = [Card]()
    var cardsInHand2 = [Card]()
    
    var table = UIView()
    
    var chosenCardId = ""
    var currentPlayer = 0 {
        didSet {
            playerTurnLabel.text = "Player \(currentPlayer)'s turn"
//            for card in cardsOnBoard {
//                if card.id == "B0" {
//                    card.mark(player: currentPlayer)
//                }
//            }
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.frame = CGRect(x: 11, y: 133, width: 354, height: 354)
        table.layer.borderColor = UIColor.green.cgColor
        table.layer.borderWidth = 0
        view.addSubview(table)
        
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
        
        currentPlayer = 1
        
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
        
        // shuffle the cards
        cardsInDeck = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: cardsInDeck) as! [Card]
        
        // choose five cards from the deck for player 1
        for col in 1...5 {
            if let card = cardsInDeck.popLast() {
                card.frame = CGRect(x: (col * 35) + 13, y: 520, width: 35, height: 43)
                cardsInHand1.append(card)
                view.addSubview(card)
            }
        }
        // choose five cards from the deck for player 2
        for col in 1...5 {
            if let card = cardsInDeck.popLast() {
                card.frame = CGRect(x: (col * 35) + 13, y: 520, width: 35, height: 43)
                cardsInHand2.append(card)
            }
        }
        
        cardsLeftLabel.text = "\(cardsInDeck.count) left"
        
        // add blank card to represent pile
        let card = Card(named: "B0-")
        card.frame = CGRect(x: 293, y: 520, width: 35, height: 43)
        view.addSubview(card)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self.view)
            
            var cardsInHand: [Card] = []
            if currentPlayer == 1 {
                cardsInHand = cardsInHand1
            } else {
                cardsInHand = cardsInHand2
            }
            
            for c in cardsOnBoard {
                if ((c.isSelected || (chosenCardId == "C11-" || chosenCardId == "D11-" || chosenCardId == "H11-" || chosenCardId == "S11-")) && c.frame.contains(touchLocation)) {
                    c.mark(player: currentPlayer)
                    for id in 0..<cardsInHand.count {
                        if chosenCardId == cardsInHand[id].id {
                            cardsInHand[id].removeFromSuperview()
                            
                            // check for win
                            
                            
                            
                            
                            if let nextCard = cardsInDeck.popLast() {
                                nextCard.frame = CGRect(x: ((id+1) * 35) + 13, y: 520, width: 35, height: 43)
                                view.addSubview(nextCard)
                                cardsInHand[id] = nextCard
                                cardsLeftLabel.text = "\(cardsInDeck.count) left"
                            }
                        }
                    }
                    for card in cardsInHand {
                        card.removeFromSuperview()
                    }
                    if currentPlayer == 1 {
                        cardsInHand1 = cardsInHand
                        currentPlayer = 2
                        for i in 0..<5 {
                            cardsInHand2[i].frame = CGRect(x: ((i+1) * 35) + 13, y: 520, width: 35, height: 43)
                            view.addSubview(cardsInHand2[i])
                        }
                    } else {
                        cardsInHand2 = cardsInHand
                        currentPlayer = 1
                        for i in 0..<5 {
                            cardsInHand1[i].frame = CGRect(x: ((i+1) * 35) + 13, y: 520, width: 35, height: 43)
                            view.addSubview(cardsInHand1[i])
                        }
                    }
                }
            }
            
            var cardChosen = false
            chosenCardId = ""
            for card in cardsInHand {
                card.isSelected = false
                if (card.frame.contains(touchLocation)) {
                    card.isSelected = true
                    cardChosen = true
                    chosenCardId = card.id
                    for c in cardsOnBoard {
                        c.isSelected = false
                        if !c.isMarked && card.id == "\(c.id)-" {
                            c.isSelected = true
                        }
                    }
                    // special case for jacks
                    if chosenCardId == "C11-" || chosenCardId == "D11-" || chosenCardId == "H11-" || chosenCardId == "S11-" {
                        table.layer.borderWidth = 2
                    } else {
                        table.layer.borderWidth = 0
                    }
                }
            }
            
            if cardChosen == false {
                for c in cardsOnBoard {
                    c.isSelected = false
                }
                table.layer.borderWidth = 0
            }
        
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

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
            } else if owner == 2 {
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
        self.isMarked = false
        self.owner = 0
        let image = UIImage(named: id)
        super.init(image: image)
        
        self.layer.borderColor = UIColor.green.cgColor
    }
    
    func mark(player: Int) {
        self.owner = player
        self.isMarked = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

