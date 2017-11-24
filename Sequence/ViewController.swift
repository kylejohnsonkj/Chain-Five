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
    var cardsOnBoard = [UIImageView]()
    
    // 2 decks -- 104 cards total (ignoring blanks)
    var cardsInDeck = [UIImageView]()
    
    // 5 at any time
    var cardsInHand = [UIImageView]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the 100 cards to board in correct order
        var i = 0
        for row in 1...10 {
            for col in 1...10 {
                let cardImage = UIImage(named: cardsLayout[i])
                let cardView = UIImageView(image: cardImage)
                cardView.frame = CGRect(x: (col * 35) - 22, y: (row * 35) + 100, width: 35, height: 35)
                view.addSubview(cardView)
                cardsOnBoard.append(cardView)
                i += 1
            }
        }
        
        // generate two decks
        var j = 0
        while (j < 2) {
            for suit in 0..<suits.count {
                for rank in 1...13 {
                    let cardImage = UIImage(named: "\(suits[suit])\(rank)-")
                    let cardView = UIImageView(image: cardImage)
                    cardsInDeck.append(cardView)
                }
            }
            j += 1
        }
        
        // shuffle the cards
        cardsInDeck = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: cardsInDeck) as! [UIImageView]
        
        // choose five cards from the deck
        for col in 1...5 {
            if let cardView = cardsInDeck.popLast() {
                cardView.frame = CGRect(x: (col * 35) + 13, y: 520, width: 35, height: 43)
                view.addSubview(cardView)
                cardsInHand.append(cardView)
            }
        }
        
        // add blank card to represent pile
        let cardImage = UIImage(named: "B0-")
        let cardView = UIImageView(image: cardImage)
        cardView.frame = CGRect(x: 293, y: 520, width: 35, height: 43)
        view.addSubview(cardView)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

