//
//  GameViewController.swift
//  Chain Five
//
//  Created by Kyle Johnson on 11/23/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit
import GameplayKit
import AudioToolbox
import MultipeerConnectivity

// MARK: - Main Class

class GameViewController: UIViewController {
    
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

    var isMPCGame = false
    var isHost = false
    var needSeedForShuffle = false
    
    let detector = ChainDetector()
    var appDelegate: AppDelegate!
    
    // 10x10 grid -- 100 cards total (ignoring jacks)
    var cardsOnBoard = [Card]()
    
    // 2 decks -- 104 cards total (ignoring backs)
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
    var lastSelectedCardId = ""

    var jackOutline = UIView()
    var gameOver = UIView()
    var waitForAnimations = false
    
    var playerID = 0
    var currentPlayer = 0 {
        didSet {
            if isMPCGame {
                if playerID == currentPlayer {
                    
                    playerTurnLabel.text = "Your turn"
                    if playerID == 1 {
                        playerIndicator.image = UIImage(named: "orange")
                    } else {
                        playerIndicator.image = UIImage(named: "blue")
                    }
                } else {
                    
                    playerTurnLabel.text = "Their turn"
                    if playerID != 1 {
                        playerIndicator.image = UIImage(named: "orange")
                    } else {
                        playerIndicator.image = UIImage(named: "blue")
                    }
                }
                
            } else {
                playerTurnLabel.text = "Player \(currentPlayer)'s turn"
                if currentPlayer == 1 {
                    playerIndicator.image = UIImage(named: "orange")
                } else {
                    playerIndicator.image = UIImage(named: "blue")
                }
            }
            
            waitForAnimations = false
        }
    }
    
    // MARK: - Setup
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        generateBoard()
        
        // load the deck image
        let deck = Card(named: "B1-")
        deck.frame = CGRect(x: 293, y: 566, width: 35, height: 49)
        view.addSubview(deck)
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        NotificationCenter.default.addObserver(self, selector: #selector(peerChangedStateWithNotification(notification:)), name: .didChangeState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleReceivedDataWithNotification(notification:)), name: .didReceive, object: nil)
        
        print("isMPCGame: \(isMPCGame)")
        print("isHost? \(isHost)")
        
        if isMPCGame {
            if isHost {
                playerID = 1
                generateDeckWithSeedAndSend()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [unowned self] in
                    self.drawCards(forPlayer: 1)
                }
            } else {
                playerID = 2
                needSeedForShuffle = true
            }
            
        } else {
            cardsInDeck = createAndShuffleDeck(seed: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [unowned self] in
                self.drawCards(forPlayer: 1)
            }
        }
        currentPlayer = 1
    }
    
    func generateDeckWithSeedAndSend() {
        
        let seed = Int(arc4random_uniform(1000000))  // 1 million
        
        // convert data to json
        let seedDict = ["seed": seed] as [String : Int]
        let seedData = try! JSONSerialization.data(withJSONObject: seedDict, options: .prettyPrinted)
        
        cardsInDeck = createAndShuffleDeck(seed: seed)
        
        // try to send the data
        do {
            try appDelegate.mpcHandler.session.send(seedData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: .reliable)
        } catch let error as NSError {
            let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    // only called in multiplayer
    @objc func peerChangedStateWithNotification(notification: Notification) {
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        appDelegate.mpcHandler.state = userInfo.object(forKey: "state") as? Int
        
        if appDelegate.mpcHandler.state != 2 {
            let ac = UIAlertController(title: "Connection Lost", message: "A player has left the game.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.performSegue(withIdentifier: "toMain", sender: self)
            })
            self.present(ac, animated: true)
        }
    }
    
    // only called in multiplayer
    @objc func handleReceivedDataWithNotification(notification: Notification) {
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let receivedData: NSData = userInfo["data"] as! NSData

        do {
            let data = try JSONSerialization.jsonObject(with: receivedData as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
            let senderPeerID: MCPeerID = userInfo["peerID"] as! MCPeerID
            let senderDisplayName = senderPeerID.displayName
            print(senderDisplayName)
            
            // receiving seed
            if data.count == 1 {
                if needSeedForShuffle {
                    let seed = (data.object(forKey: "seed") as AnyObject).integerValue
                    cardsInDeck = createAndShuffleDeck(seed: seed!)
                    self.drawCards(forPlayer: 1)
                    needSeedForShuffle = false
                }
            }
            
            // receiving placed card info
            if data.count == 2 {
                let cardIndex = (data.object(forKey: "cardIndex") as AnyObject).integerValue
                let owner = (data.object(forKey: "owner") as AnyObject).integerValue
                
                print("cardIndex: \(cardIndex!)  owner: \(owner!)")
                cardsOnBoard[cardIndex!].owner = owner!
                cardsOnBoard[cardIndex!].isMarked = true
                changeTurns()
            }

        } catch let error as NSError {
            let ac = UIAlertController(title: "Receive error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    func generateBoard() {
        
        playerIndicator.alpha = 0
        playerTurnLabel.alpha = 0
        cardsLeftLabel.alpha = 0

        // used for jack highlighting
        jackOutline.frame = CGRect(x: 10, y: 132, width: 356, height: 357)
        jackOutline.layer.borderColor = UIColor.green.cgColor
        jackOutline.layer.borderWidth = 0
        view.addSubview(jackOutline)
        
        // adds black line below bottom row of cards
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
                card.index = i
                i += 1
            }
        }

        // mark the free spaces
        cardsOnBoard[0].isFreeSpace = true      // top left
        cardsOnBoard[9].isFreeSpace = true      // top right
        cardsOnBoard[90].isFreeSpace = true     // btm left
        cardsOnBoard[99].isFreeSpace = true     // btm right
    }
    
    func createAndShuffleDeck(seed: Int?) -> [Card] {
        
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
        
        if seed == nil {
            return GKRandomSource.sharedRandom().arrayByShufflingObjects(in: cardsInDeck) as! [Card]
        } else {
            let lcg = GKLinearCongruentialRandomSource(seed: UInt64(seed!))
            return lcg.arrayByShufflingObjects(in: cardsInDeck) as! [Card]
        }
        
    }
    
    func drawCards(forPlayer player: Int) {
        
        // choose five cards from the deck
        for col in 1...5 {
            
            // need image container for flipping animation
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
                        self.cardsLeftLabel.text = "\(self.cardsInDeck.count)"
                        UIView.animate(withDuration: 1) {
                            self.playerIndicator.alpha = 1
                            self.playerTurnLabel.alpha = 1
                            self.cardsLeftLabel.alpha = 1
                        }
                    }
                })
            }
        }
    }
    
    // MARK: - Gameplay
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesBegan(touches, with: event)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self.view)
            
            // go back to main menu
            if menuLabel.frame.contains(touchLocation) || menuIconLabel.frame.contains(touchLocation) {
                
                AudioServicesPlaySystemSound(1520)
                self.performSegue(withIdentifier: "toMain", sender: self)
            }
            
            var cardsInHand = getCurrentHand()
            
            // reset taptic feedback if no cards in hand are selected
            for i in 0..<cardsInHand.count {
                if (cardsInHand[i].frame.contains(touchLocation)) {
                    break
                } else {
                    if i == cardsInHand.count - 1 {
                        lastSelectedCardId = ""
                    }
                }
            }
            
            for c in cardsOnBoard {
                if ((c.isSelected || isJack()) && !c.isFreeSpace && c.frame.contains(touchLocation)) {
                    
                    if isMPCGame && currentPlayer != playerID {
                        break
                    }
                    
                    waitForAnimations = true
                    
                    if isMPCGame {
                        c.owner = playerID
                    } else {
                        c.owner = currentPlayer
                    }
                    c.isMarked = true

                    if isMPCGame && appDelegate.mpcHandler.session.connectedPeers.count > 0 {
                        
                        // convert data to json
                        let cardIndexDict = ["cardIndex": c.index, "owner": c.owner] as [String : Int]
                        let cardIndexData = try! JSONSerialization.data(withJSONObject: cardIndexDict, options: .prettyPrinted)
                        
                        // try to send the data
                        do {
                            try appDelegate.mpcHandler.session.send(cardIndexData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: .reliable)
                        } catch let error as NSError {
                            let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "OK", style: .default))
                            present(ac, animated: true)
                        }
                        
                    }

                    let container = UIView()
                    container.frame = CGRect(x: 293, y: 566, width: 35, height: 43)
                    view.addSubview(container)
                    
                    let back = Card(named: "B0-")
                    back.frame = CGRect(x: 0, y: 0, width: 35, height: 43)
                    container.addSubview(back)
                    
                    if detector.isValidChain(cardsOnBoard, currentPlayer) {
                        
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                        
                        let ac = UIAlertController(title: "It's a Chain!", message: "Player \(currentPlayer) has won the game.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self.gameOver.removeFromSuperview()
                            self.performSegue(withIdentifier: "toMain", sender: self)
                        })
                        self.present(ac, animated: true)
                        
                        var gameOverColor: CGColor
                        if currentPlayer == 1 {
                            gameOverColor = UIColor(red: 255/255, green: 180/255, blue: 1/255, alpha: 1).cgColor
                        } else {
                            gameOverColor = UIColor(red: 94/255, green: 208/255, blue: 255/255, alpha: 1).cgColor
                        }
                        
                        gameOver.frame = view.frame
                        gameOver.layer.backgroundColor = gameOverColor
                        gameOver.layer.zPosition = 2
                        view.addSubview(gameOver)
                        gameOver.alpha = 0
                        
                        // fade in color
                        UIView.animate(withDuration: 1.0, animations: {
                            self.gameOver.alpha = 1
                        })
                    }
                    
                    // only continue from here if no valid chain was found
                    guard detector.isValidChain(cardsOnBoard, currentPlayer) == false
                        else { return }
                    
                    AudioServicesPlaySystemSound(1519)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [unowned self] in
                        self.cardsLeftLabel.text = "\(self.cardsInDeck.count - 1)"
                    }

                    UIView.animate(withDuration: 1, delay: 0.75, options: [.curveEaseOut], animations: {
                        container.frame.origin = cardsInHand[self.chosenCardIndex].frame.origin
                        cardsInHand[self.chosenCardIndex].removeFromSuperview()
                        
                    }, completion: { _ in
                        
                        if let nextCard = self.getNextCardFromDeck() {
                            cardsInHand[self.chosenCardIndex] = nextCard
                            
                            if self.currentPlayer == 1 || self.isMPCGame {
                                self.cardsInHand1[self.chosenCardIndex] = nextCard
                            } else {
                                self.cardsInHand2[self.chosenCardIndex] = nextCard
                            }
                        
                            nextCard.frame = CGRect(x: 0, y: 0, width: 35, height: 43)
                            
                            UIView.transition(from: back, to: nextCard, duration: 1, options: [.transitionFlipFromRight], completion: nil)
                        }
                        
                        if self.isMPCGame {
                            self.changeTurns()
                        } else {
                            // if it's player 2's turn to draw their cards
                            if self.cardsInDeck.count == 98 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [unowned self] in
                                    self.drawCards(forPlayer: 2)
                                    self.cardsLeftLabel.text = "\(self.cardsInDeck.count + 5)"
                                }
                            }
                            self.swapHands(cardsInHand)
                        }
                    })
                }
            }
            
            cardChosen = false
            chosenCardId = ""
            
            // used for highlighting cards on game board when selected in deck
            for i in 0..<cardsInHand.count {
                
                cardsInHand[i].isSelected = false
                
                if (waitForAnimations == false && cardsInHand[i].frame.contains(touchLocation)) {
                    cardsInHand[i].isSelected = true
                    
                    if cardsInHand[i].id != lastSelectedCardId {
                        lastSelectedCardId = cardsInHand[i].id
                        AudioServicesPlaySystemSound(1519)
                    }
                    
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
    
    func changeTurns() {
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
            // fade out player indicator
            self.playerIndicator.alpha = 0
            self.playerTurnLabel.alpha = 0
        }, completion: { _ in
            
            if self.currentPlayer == 1 {
                self.currentPlayer = 2
            } else {
                self.currentPlayer = 1
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                // fade in player indicator
                self.playerIndicator.alpha = 1
                self.playerTurnLabel.alpha = 1
            }, completion: { _ in

                for i in 0..<5 {
                    self.cardsInHand1[i].frame = CGRect(x: ((i+1) * 35) + 13, y: 520, width: 35, height: 43)
                    self.view.addSubview(self.cardsInHand1[i])
                }
            })
        })
    }
    
    func isJack() -> Bool {
        return (chosenCardId == "C11-" || chosenCardId == "D11-" || chosenCardId == "H11-" || chosenCardId == "S11-")
    }
    
    func getCurrentHand() -> [Card] {
        if isMPCGame == true {
            return cardsInHand1
        } else {
            return currentPlayer == 1 ? cardsInHand1 : cardsInHand2
        }
    }
    
    func getNextCardFromDeck() -> Card? {
        if let nextCard = self.cardsInDeck.popLast() {
            nextCard.frame = CGRect(x: ((self.chosenCardIndex+1) * 35) + 13, y: 520, width: 35, height: 43)
            self.view.addSubview(nextCard)
            return nextCard
        } else {
            // return blank for now
            if isHost && appDelegate.mpcHandler.session.connectedPeers.count > 0 {
                generateDeckWithSeedAndSend()
            }
            return getNextCardFromDeck()
        }
    }
    
    func swapHands(_ hand: [Card]) {
        
        var cardsInHand = getCurrentHand()
        
        UIView.animate(withDuration: 0.5, delay: 1.5, options: [], animations: {
            
            // fade out cards and player indicator label
            self.playerIndicator.alpha = 0
            self.playerTurnLabel.alpha = 0
            self.cardsLeftLabel.alpha = self.cardsInDeck.count >= 93 ? 0 : self.cardsLeftLabel.alpha
            
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
}

