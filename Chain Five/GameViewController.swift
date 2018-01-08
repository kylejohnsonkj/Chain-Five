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

extension UIView {
    // Used to bring attention to player indicator and turn label when user tries to go off-turn
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        layer.add(animation, forKey: "shake")
    }
}

// MARK: - Main Class
class GameViewController: UIViewController {
    
    let suits = ["C", "D", "H", "S"]

    let cardsLayout = ["-free", "C10", "C9", "C8", "C7", "H7", "H8", "H9", "H10", "-free",
                       "D10", "D13", "C6", "C5", "C4", "H4", "H5", "H6", "S13", "S10",
                       "D9", "D6", "D12", "C3", "C2", "H2", "H3", "S12", "S6", "S9",
                       "D8", "D5", "D3", "C12", "C1", "H1", "H12", "S3", "S5", "S8",
                       "D7", "D4", "D2", "D1", "C13", "H13", "S1", "S2", "S4", "S7",
                       "S7", "S4", "S2", "S1", "H13", "C13", "D1", "D2", "D4", "D7",
                       "S8", "S5", "S3", "H12", "H1", "C1", "C12", "D3", "D5", "D8",
                       "S9", "S6", "S12", "H3", "H2", "C2", "C3", "D12", "D6", "D9",
                       "S10", "S13", "H6", "H5", "H4", "C4", "C5", "C6", "D13", "D10",
                       "-free", "H10", "H9", "H8", "H7", "C7", "C8", "C9", "C10", "-free"]

    enum Taptics: SystemSoundID {
        case peek = 1519, pop = 1520, nope = 1521
    }
    
    // 10x10 grid -- 100 cards total (ignoring jacks)
    var cardsOnBoard = [Card]()
    
    // for MultipeerConnectivity purposes
    var appDelegate: AppDelegate!
    var isMPCGame = false
    var isHost = false
    var seed: Int!
    
    var detector: ChainDetector!

    // 2 decks -- 104 cards total (ignoring backs)
    var cardsInDeck = [Card]() {
        didSet {
            if cardsInDeck.count == 0 {
                self.cardsLeftLabel.text = "\(totalCards)"
            } else {
                self.cardsLeftLabel.text = "\(self.cardsInDeck.count)"
            }
        }
    }
    
    var cardsInHand1 = [Card]()
    var cardsInHand2 = [Card]()
    var totalCards = 104
    
    var beforeP1Deal: Int!
    var beforeP2Deal: Int!
    var afterP2Deal: Int!
    
    var cardChosen: Bool = false {
        didSet {
            if cardChosen == false {
                for c in cardsOnBoard {
                    c.isSelected = false
                }
                jackOutline.layer.borderWidth = 0
                deckOutline.layer.borderWidth = 0
            }
        }
    }
    
    var chosenCardIndex = -1
    var chosenCardId = ""
    var lastSelectedCardIndex = -1

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
                waitForAnimations = false
            } else {
                if currentPlayer == 1 {
                    playerTurnLabel.text = "Orange's turn"
                    playerIndicator.image = UIImage(named: "orange")
                } else {
                    playerTurnLabel.text = "Blue's turn"
                    playerIndicator.image = UIImage(named: "blue")
                }
            }
        }
    }
    
    var l: Layout!
    var menuIcon: UIImageView!
    var helpIcon: UIImageView!
    var playerIndicator: UIImageView!
    var playerTurnLabel: UILabel!
    var cardsLeftLabel: UILabel!
    var helpView: UIView!
    var helpPresented = false
    var mostRecentIndex = -1
    var deck: UIImageView!
    var waitForReady = false
    var deckOutline = UIView()
    var deadCard = false
    
    // MARK: - Setup
        
    override func viewDidLoad() {
        super.viewDidLoad()
        l = Layout()
        
        // for changing deck size in testing
        beforeP1Deal = totalCards
        beforeP2Deal = totalCards - 6
        afterP2Deal = totalCards - 11
        
        // Game Title
        let gameTitle = UIImageView(image: UIImage(named: "title"))
        gameTitle.frame = CGRect(x: view.bounds.midX - (l.titleWidth / 2), y: l.topMargin - l.cardSize - l.titleHeight, width: l.titleWidth, height: l.titleHeight)
        gameTitle.contentMode = .scaleAspectFit
        //        gameTitle.layer.borderWidth = 1
        view.addSubview(gameTitle)
        
        playerIndicator = UIImageView(image: UIImage(named: "orange"))
        playerIndicator.frame = CGRect(x: -l.cardSize - l.itemWidth * 2, y: l.btmMargin + (2 * l.cardSize * 1.21) + l.cardSize * 0.05, width: l.cardSize * 0.9, height: l.cardSize * 0.9)
        view.addSubview(playerIndicator)
        
        playerTurnLabel = UILabel()
        playerTurnLabel.text = "Kyle's turn"  // placeholder
        playerTurnLabel.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        playerTurnLabel.frame = CGRect(x: -l.itemWidth * 2, y: l.btmMargin + (2 * l.cardSize * 1.21) - l.cardSize * 0.01, width: l.itemWidth * 2, height: l.cardSize)
        playerTurnLabel.textAlignment = .left
        view.addSubview(playerTurnLabel)
        
        cardsLeftLabel = UILabel()
        cardsLeftLabel.text = "99"  // placeholder
        cardsLeftLabel.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        cardsLeftLabel.frame = CGRect(x: l.leftMargin + l.cardSize * 9.20, y: l.btmMargin + (2 * l.cardSize * 1.21) - l.cardSize * 0.01, width: l.itemWidth, height: l.cardSize)
        cardsLeftLabel.textAlignment = .left
        view.addSubview(cardsLeftLabel)
        
        menuIcon = UIImageView(image: UIImage(named: "menu"))
        menuIcon.frame = CGRect(x: view.frame.minX - l.cardSize, y: l.topMargin - l.cardSize * 1.25, width: l.cardSize, height: l.cardSize)
        view.addSubview(menuIcon)
        
        helpIcon = UIImageView(image: UIImage(named: "help"))
        helpIcon.frame = CGRect(x: view.frame.maxX + l.cardSize, y: l.topMargin - l.cardSize * 1.25, width: l.cardSize, height: l.cardSize)
        view.addSubview(helpIcon)
        
        generateBoard()
        
        // load the deck image
        deck = Card(named: "-deck")
        deck.frame = CGRect(x: view.frame.maxX, y: l.btmMargin + l.cardSize * 2 + l.cardSize * 0.23, width: l.cardSize, height: l.cardSize * 1.4)
        view.addSubview(deck)
        
        deckOutline.frame = CGRect(x: l.leftMargin + l.cardSize * 8 - l.highlight, y: l.btmMargin + l.cardSize * 2 + l.cardSize * 0.23 - l.highlight, width: l.cardSize + (2 * l.highlight), height: l.cardSize * 1.4 + (l.highlight * 2))
        deckOutline.layer.borderColor = UIColor.green.cgColor
        deckOutline.layer.borderWidth = 0
        view.addSubview(deckOutline)
        
        detector = ChainDetector()
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        NotificationCenter.default.addObserver(self, selector: #selector(peerChangedStateWithNotification(notification:)), name: .didChangeState, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleReceivedDataWithNotification(notification:)), name: .didReceiveData, object: nil)
        
        print("isMPCGame: \(isMPCGame)")
        print("isHost? \(isHost)")
        
        appDelegate.mpcHandler.advertiser!.stop()

        
        if isMPCGame {
            // Multiplayer game
            if isHost {
                playerID = 1
                seed = generateDeckWithSeedAndSend()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [unowned self] in
                    UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: {
                        self.menuIcon.frame.origin.x = self.l.leftMargin
                        self.helpIcon.frame.origin.x = self.l.leftMargin + 9 * self.l.cardSize
                        self.deck.frame.origin.x = self.l.leftMargin + self.l.cardSize * 8
                        self.playerIndicator.frame.origin.x = self.l.leftMargin + self.l.cardSize * 0.18
                        self.playerTurnLabel.frame.origin.x = self.l.leftMargin + self.l.cardSize * 1.18
                    }, completion: { _ in
                        self.drawCards()
                    })
                }
            } else {
                playerID = 2
            }
        } else {
            // Pass 'N Play game
            cardsInDeck = createAndShuffleDeck(seed: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [unowned self] in
                self.playerTurnLabel.text = "Orange, tap for control"
                UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: {
                    self.menuIcon.frame.origin.x = self.l.leftMargin
                    self.helpIcon.frame.origin.x = self.l.leftMargin + 9 * self.l.cardSize
                    self.deck.frame.origin.x = self.l.leftMargin + self.l.cardSize * 8
                    self.playerIndicator.frame.origin.x = self.l.leftMargin + self.l.cardSize * 0.18
                    self.playerTurnLabel.frame.origin.x = self.l.leftMargin + self.l.cardSize * 1.18
                }, completion: { _ in
                    self.waitForReady = true
                })
            }
        }
        currentPlayer = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // should use for UI stuff, but has delay
    }
    
    func generateDeckWithSeedAndSend() -> Int {
        
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
        
        return seed
    }
    
    // only called in multiplayer
    @objc func peerChangedStateWithNotification(notification: Notification) {
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        appDelegate.mpcHandler.state = userInfo.object(forKey: "state") as? Int
        
        if appDelegate.mpcHandler.state != 2 {
            let ac = UIAlertController(title: "Connection Lost", message: "Opponent has left the game!", preferredStyle: .alert)
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

            // receiving seed for randomizer
            if data.count == 1 {
                seed = (data.object(forKey: "seed") as AnyObject).integerValue
                cardsInDeck = createAndShuffleDeck(seed: seed!)
                
                // discard player 1's draw
                for _ in 1...5 {
                    _ = cardsInDeck.popLast()
                }
                
                UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: {
                    self.menuIcon.frame.origin.x = self.l.leftMargin
                    self.helpIcon.frame.origin.x = self.l.leftMargin + 9 * self.l.cardSize
                    self.deck.alpha = 1
                }, completion: { _ in
                    self.drawCards()
                })
            }
            
            // receiving placed card info
            if data.count == 2 {
                let cardIndex = (data.object(forKey: "cardIndex") as AnyObject).integerValue!
                let owner = (data.object(forKey: "owner") as AnyObject).integerValue!
                
                // opponent drew for dead card, update our own deck
                if cardIndex == -1 {
                    popLastCard()
                    return
                }
                
                // avoid repeat calls
                if cardsOnBoard[cardIndex].isMarked == false {
                    print("cardIndex \(cardIndex) placed by player \(senderDisplayName)")
                    cardsOnBoard[cardIndex].owner = owner
                    cardsOnBoard[cardIndex].isMarked = true
                    
                    for c in cardsOnBoard {
                        c.isMostRecent = false
                    }

                    popLastCard()  // discard other player's drawn card
                    
                    // test for chain
                    var (isValidChain, winningIndices) = self.detector.isValidChain(self.cardsOnBoard, self.currentPlayer)
                    
                    // temporary bug fix for recognizing chains
                    if isValidChain == false {
                        if self.currentPlayer == 1 {
                            (isValidChain, winningIndices) = self.detector.isValidChain(self.cardsOnBoard, 2)
                            if isValidChain { print("Odd case, player went quickly!") }
                        } else {
                            (isValidChain, winningIndices) = self.detector.isValidChain(self.cardsOnBoard, 1)
                            if isValidChain { print("Odd case, player went quickly!") }
                        }
                    }
                    
                    if isValidChain {
                        
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                        for i in 0..<winningIndices.count {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) { [unowned self] in
                                self.cardsOnBoard[winningIndices[i]].isChecked = true
                            }
                        }
                        
                        let cardsInHand = self.getCurrentHand()
                        for card in cardsInHand {
                            card.isSelected = false
                        }
                        for c in self.cardsOnBoard {
                            c.isSelected = false
                        }
                        self.jackOutline.layer.borderWidth = 0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [unowned self] in
                            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                            self.presentWinScreen()
                        }
                    } else {
                        AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                        cardsOnBoard[cardIndex].isMostRecent = true
                        self.changeTurns()
                    }
                } else {
                    // other player removed marker using jack
                    print("cardIndex \(cardIndex) removed by player \(senderDisplayName)")
                    cardsOnBoard[cardIndex].owner = owner
                    cardsOnBoard[cardIndex].isMarked = false
                    cardsOnBoard[cardIndex].isMostRecent = true
                    cardsOnBoard[cardIndex].fadeMarker()
                    popLastCard()   // discard other player's drawn card
                    AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                    self.changeTurns()
                }
            }

        } catch let error as NSError {
            print("RECEIVING ERROR: \(error.localizedDescription)")
        }
    }
    
    func popLastCard() {
        if let _ = self.cardsInDeck.popLast() {
            // removes card from our deck
        } else {
            
            beforeP1Deal = totalCards + 1
            beforeP2Deal = totalCards + 1
            afterP2Deal = totalCards + 1
            
            cardsInDeck = createAndShuffleDeck(seed: seed)
            
            // shuffle again
            if seed == nil {
                cardsInDeck = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: cardsInDeck) as! [Card]
            } else {
                let lcg = GKLinearCongruentialRandomSource(seed: UInt64(seed!))
                cardsInDeck = lcg.arrayByShufflingObjects(in: cardsInDeck) as! [Card]
            }
            
            for i in 0..<cardsInDeck.count {
                cardsInDeck[i].index = i
            }
            cardsInDeck = cardsInDeck.reversed()
            
            popLastCard()
        }
    }
    
    func generateBoard() {

        // adds black line below bottom row of cards
        let bottomBorder = UIView()
        bottomBorder.frame = CGRect(x: l.leftMargin, y: l.btmMargin, width: l.cardSize * 10, height: l.stroke)
        bottomBorder.layer.backgroundColor = UIColor.black.cgColor
        view.addSubview(bottomBorder)

        // used for jack highlighting
        jackOutline.frame = CGRect(x: l.leftMargin - l.highlight, y: l.topMargin - l.highlight, width: (l.cardSize * 10) + (2 * l.highlight), height: (l.cardSize * 10) + (l.highlight * 2) + l.stroke)
        jackOutline.layer.borderColor = UIColor.green.cgColor
        jackOutline.layer.borderWidth = 0
        view.addSubview(jackOutline)
        
//        handOutline.frame = CGRect(x: l.leftMargin + l.cardSize - l.highlight, y: l.btmMargin + l.cardSize - l.highlight, width: (l.cardSize * 5) + (2 * l.highlight), height: (l.cardSize * 1.23) + (l.highlight * 2))
//        handOutline.layer.borderColor = UIColor.green.cgColor
//        handOutline.layer.borderWidth = 0
//        view.addSubview(handOutline)
        
        cardsLeftLabel.alpha = 0

        // load the 100 cards
        var i = 0
        for row in 0...9 {
            for col in 0...9 {
                let card = Card(named: self.cardsLayout[i])
                card.frame = CGRect(x: self.l.leftMargin + (CGFloat(col) * (self.l.cardSize)), y: self.l.topMargin + (CGFloat(row) * self.l.cardSize), width: self.l.cardSize, height: self.l.cardSize)
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
                    let card = Card(named: "\(suits[suit])\(rank)+")
//                    let card = Card(named: "C4+")    // testing
                    cardsInDeck.append(card)
                }
            }
            j += 1
        }

        var array: [Card] = []
        if seed == nil {
            array = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: cardsInDeck) as! [Card]
        } else {
            let lcg = GKLinearCongruentialRandomSource(seed: UInt64(seed!))
            array = lcg.arrayByShufflingObjects(in: cardsInDeck) as! [Card]
        }
        
        for i in 0..<array.count {
            array[i].index = i
        }
        
        return array.reversed()
    }
    
    func drawCards(forPlayer player: Int = 1) {
        
        waitForAnimations = true
        
        // choose five cards from the deck
        for col in 1...5 {
            
            // need image container for flipping animation
            let container = UIView()
            container.frame = CGRect(x: l.leftMargin + l.cardSize * 8, y: l.btmMargin + l.cardSize * 2 + l.cardSize * 0.23, width: l.cardSize, height: l.cardSize * 1.23)
            container.layer.zPosition = 6 - CGFloat(col)
            view.addSubview(container)
            
            let back = Card(named: "-back")
            back.frame = CGRect(x: 0, y: 0, width: l.cardSize, height: l.cardSize * 1.23)
            back.layer.zPosition = 6 - CGFloat(col)
            container.addSubview(back)
            
            if let card = self.cardsInDeck.popLast() {
                
                UIView.animate(withDuration: 1, delay: TimeInterval(0.3 * Double(col)) + 0.3, options: [.curveEaseOut], animations: {
                    container.frame = CGRect(x: self.l.leftMargin + (CGFloat(col) * self.l.cardSize), y: self.l.btmMargin + self.l.cardSize, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                    
                }, completion: { _ in
                    
                    container.frame = CGRect(x: self.l.leftMargin + (CGFloat(col) * self.l.cardSize), y: self.l.btmMargin + self.l.cardSize, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                    card.frame = CGRect(x: 0, y: 0, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                    
                    if player == 1 {
                        self.cardsInHand1.append(card)
                    } else {
                        self.cardsInHand2.append(card)
                    }
                    
                    if col == 5 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { [unowned self] in
                            self.waitForAnimations = false
//                            self.handOutline.layer.borderWidth = self.l.highlight
                        }
                    }
                    
                    UIView.transition(from: back, to: card, duration: 1, options: [.transitionFlipFromRight], completion: { _ in
                        card.frame = CGRect(x: self.l.leftMargin + (CGFloat(col) * self.l.cardSize), y: self.l.btmMargin + self.l.cardSize, width: self.l.cardSize, height: self.l.cardSize * 1.23)
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
        
        // discard player 2's draw
        if isMPCGame && isHost {
            for _ in 1...5 {
                _ = cardsInDeck.popLast()
            }
        }
    }
    
    // MARK: - Gameplay
    
    // forward move events to touches began
    // allows smooth scrolling through cards
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self.view)
            
            // only forward movements through hand
            let currentHand = getCurrentHand()
            for card in currentHand {
                if card.frame.contains(touchLocation) && waitForAnimations == false {
                    touchesBegan(touches, with: event)
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self.view)
            
            var cardsInHand = getCurrentHand()
            
            // dismiss help view
            if helpPresented == true {
                helpView.removeFromSuperview()
                helpPresented = false
                return
            }
            
            // go back to main menu
            if menuIcon.frame.contains(touchLocation) {
//                handOutline.layer.borderWidth = 0
                AudioServicesPlaySystemSound(Taptics.pop.rawValue)
                presentMenuAlert()
                return
            }
            
            // show tutorial
            if helpIcon.frame.contains(touchLocation) {
//                handOutline.layer.borderWidth = 0
                AudioServicesPlaySystemSound(Taptics.pop.rawValue)
                presentHelpView()
                helpPresented = true
                return
            }
            
            // for pass-n-play
            if waitForReady == true {
                waitForAnimations = true
                AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                swapToNextPlayer(cardsInHand)
                waitForReady = false
                return
            }
            
//            handOutline.layer.borderWidth = 0
            
            // reset taptic feedback if no cards in hand are selected
            var cardTouched = false
            for i in 0..<cardsInHand.count {
                if cardTouched == false {
                    if (cardsInHand[i].frame.contains(touchLocation)) {
                        cardTouched = true
                    } else {
                        if i == cardsInHand.count - 1 {
                            lastSelectedCardIndex = -1
                        }
                    }
                }
            }
            
            if deadCard == true && deck.frame.contains(touchLocation) {
                
                let container = UIView()
                container.frame = CGRect(x: l.leftMargin + l.cardSize * 8, y: l.btmMargin + l.cardSize * 2 + l.cardSize * 0.23, width: l.cardSize, height: l.cardSize * 1.23)
                container.layer.zPosition = 1
                
                let back = Card(named: "-back")
                back.frame = CGRect(x: 0, y: 0, width: l.cardSize, height: l.cardSize * 1.23)
                
                view.addSubview(container)
                container.addSubview(back)
                
                cardsInHand = animateNextCardToHand(cardsInHand, container, back)
                return
            }
            
            deadCard = false
            
            for c in cardsOnBoard {
                if ((c.isSelected || isJack()) && !c.isFreeSpace && c.owner != currentPlayer && c.frame.contains(touchLocation)) {
                    
                    if isMPCGame && currentPlayer != playerID {
                        playerIndicator.shake()
                        playerTurnLabel.shake()
                        AudioServicesPlaySystemSound(Taptics.nope.rawValue)
                    }
                    
                    if !(isMPCGame && currentPlayer != playerID) {
                        
                        waitForAnimations = true
                        
                        if isMPCGame {
                            c.owner = playerID
                        } else {
                            c.owner = currentPlayer
                        }
                        
                        if c.isMarked == false {
                            c.isMarked = true
                            for c in cardsOnBoard {
                                c.isMostRecent = false
                            }
                        } else {
                            if (isJack()) {
                                c.owner = 0
                                c.isMarked = false
                                c.removeMarker()
                            }
                        }

                        if isMPCGame && appDelegate.mpcHandler.session.connectedPeers.count > 0 {
                            
                            // convert data to json
                            let cardIndexDict = ["cardIndex": c.index, "owner": c.owner] as [String : Int]
                            let cardIndexData = try! JSONSerialization.data(withJSONObject: cardIndexDict, options: .prettyPrinted)
                            
                            // try to send the data
                            do {
                                try appDelegate.mpcHandler.session.send(cardIndexData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: .reliable)
                            } catch let error as NSError {
                                print("SENDING ERROR: \(error.localizedDescription)")
                            }
                            
                        }

                        let container = UIView()
                        container.frame = CGRect(x: l.leftMargin + l.cardSize * 8, y: l.btmMargin + l.cardSize * 2 + l.cardSize * 0.23, width: l.cardSize, height: l.cardSize * 1.23)
                        container.layer.zPosition = 1
                        
                        let back = Card(named: "-back")
                        back.frame = CGRect(x: 0, y: 0, width: l.cardSize, height: l.cardSize * 1.23)
                        
                        view.addSubview(container)
                        container.addSubview(back)
                        
                        let (isValidChain, winningIndices) = detector.isValidChain(cardsOnBoard, currentPlayer)
                        if isValidChain == true {
                            
                            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                            for i in 0..<winningIndices.count {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) { [unowned self] in
                                    self.cardsOnBoard[winningIndices[i]].isChecked = true
                                }
                            }
                            
                            for card in cardsInHand {
                                card.isSelected = false
                            }
                            for c in cardsOnBoard {
                                c.isSelected = false
                            }
                            jackOutline.layer.borderWidth = 0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [unowned self] in
                                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                                self.presentWinScreen()
                            }
                        }
                        
                        // only continue from here if no valid chain was found
                        guard isValidChain == false else { return }
                        
                        AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                        mostRecentIndex = c.index
                        
                        if cardsInDeck.count == 1 {
                            self.cardsLeftLabel.text = "\(totalCards)"
                        } else if cardsInDeck.count == 0 {
                            self.cardsLeftLabel.text = "\(totalCards - 1)"
                        } else {
                            self.cardsLeftLabel.text = "\(self.cardsInDeck.count - 1)"
                        }
                        
                        if isMPCGame {
                            self.changeTurns()
                        }
                        
                        cardsInHand = animateNextCardToHand(cardsInHand, container, back)
                    }
                }
            }
            
            cardChosen = false
            chosenCardId = ""
            
            // used for highlighting cards on game board when selected in deck
            for i in 0..<cardsInHand.count {
                
                cardsInHand[i].isSelected = false
                
                if waitForAnimations == false && cardsInHand[i].frame.contains(touchLocation) {
                    cardsInHand[i].isSelected = true
                    
                    if cardsInHand[i].index != lastSelectedCardIndex {
                        lastSelectedCardIndex = cardsInHand[i].index
                        AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                    }
                    
                    cardChosen = true
                    chosenCardIndex = i
                    chosenCardId = cardsInHand[i].id
                    
                    deadCard = true
                    for c in cardsOnBoard {
                        c.isSelected = false
                        c.isMostRecent = false
                        if c.marker.alpha == 0.5 {
                            c.subviews.forEach { $0.removeFromSuperview() }
                        }
                        if !c.isMarked && chosenCardId == "\(c.id)+" {
                            c.isSelected = true
                            deadCard = false
                        }
                    }
                    
                    // special case for jacks
                    if isJack() {
                        jackOutline.layer.borderWidth = l.highlight
                        deadCard = false
                    } else {
                        jackOutline.layer.borderWidth = 0
                    }
                    
                    if deadCard {
                        deckOutline.layer.borderWidth = l.highlight
                    } else {
                        deckOutline.layer.borderWidth = 0
                    }
                }
            }
        }
    }
    
    func presentMenuAlert() {
        let ac = UIAlertController(title: "Are you sure?", message: "This will end the game in progress.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            self.gameOver.removeFromSuperview()
            self.performSegue(withIdentifier: "toMain", sender: self)
        })
        ac.addAction(UIAlertAction(title: "No", style: .cancel))
        self.present(ac, animated: true)
    }
    
    func presentHelpView() {
//        let ac = UIAlertController(title: "OH hey there.", message: "There's no help yet. You're on your own, slugger.", preferredStyle: .alert)
//        ac.addAction(UIAlertAction(title: "OK", style: .cancel))
//        self.present(ac, animated: true)
        
        helpView = UIView()
        helpView.frame = view.frame
        helpView.backgroundColor = .white
        helpView.layer.zPosition = 10
        view.addSubview(helpView)
        helpView.alpha = 0.5
        
        // maybe use arrows instead to point out each part (step by step?)
    }
    
    // MARK: - Win Screen and Helper Methods
    
    func presentWinScreen() {
        
        if currentPlayer == 1 {
            presentAlert(title: "It's a Chain!", message: "Orange has won the game.")
        } else {
            presentAlert(title: "It's a Chain!", message: "Blue has won the game.")
        }
        
        showWinningColor()
//        incrementGamesFinished()
    }
    
    func presentAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.performSegue(withIdentifier: "toMain", sender: self)
        })
        self.present(ac, animated: true)
    }
    
    func showWinningColor() {
        // orange for player 1, blue for player 2
        let gameOverColor = currentPlayer == 1 ? UIColor(red: 255/255, green: 180/255, blue: 1/255, alpha: 1).cgColor : UIColor(red: 94/255, green: 208/255, blue: 255/255, alpha: 1).cgColor
        
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
    
    func incrementGamesFinished() {
        let currentCount = UserDefaults.standard.integer(forKey: "gamesFinished")
        UserDefaults.standard.set(currentCount + 1, forKey:"gamesFinished")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Other Helper Methods
    
    func isJack() -> Bool {
        return (chosenCardId == "C11+" || chosenCardId == "D11+" || chosenCardId == "H11+" || chosenCardId == "S11+")
    }
    
    func getCurrentHand() -> [Card] {
        if isMPCGame == true {
            return cardsInHand1
        } else {
            return currentPlayer == 1 ? cardsInHand1 : cardsInHand2
        }
    }
    
    func animateNextCardToHand(_ hand: [Card], _ container: UIView, _ back: Card) -> [Card] {
        
        var cardsInHand = hand
        deckOutline.layer.borderWidth = 0
        
        UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseOut], animations: {
            container.frame.origin = cardsInHand[self.chosenCardIndex].frame.origin
            cardsInHand[self.chosenCardIndex].removeFromSuperview()
            
        }, completion: { _ in
            
            if let nextCard = self.getNextCardFromDeck() {
                cardsInHand[self.chosenCardIndex].removeFromSuperview()
                cardsInHand[self.chosenCardIndex] = nextCard
                
                if self.currentPlayer == 1 || self.isMPCGame {
                    self.cardsInHand1[self.chosenCardIndex].removeFromSuperview()
                    self.cardsInHand1[self.chosenCardIndex] = nextCard
                } else {
                    self.cardsInHand2[self.chosenCardIndex].removeFromSuperview()
                    self.cardsInHand2[self.chosenCardIndex] = nextCard
                }
                
                nextCard.frame = CGRect(x: 0, y: 0, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                
                UIView.transition(from: back, to: nextCard, duration: 1.0, options: [.transitionFlipFromRight]) { (completed: Bool) in
                    for i in 0..<5 {
                        self.cardsInHand1[i].frame = CGRect(x: self.l.leftMargin + (CGFloat(i+1) * self.l.cardSize), y: self.l.btmMargin + self.l.cardSize, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                        self.view.addSubview(self.cardsInHand1[i])
                    }
                }
            }
            
            if self.deadCard == false && self.isMPCGame == false {
                self.swapHands(cardsInHand)
            } else {
                
                if self.deadCard && self.isMPCGame && self.appDelegate.mpcHandler.session.connectedPeers.count > 0 {
                    // convert data to json
                    let cardIndexDict = ["cardIndex": -1, "owner": self.currentPlayer] as [String : Int]
                    let cardIndexData = try! JSONSerialization.data(withJSONObject: cardIndexDict, options: .prettyPrinted)
                    
                    // try to send the data
                    do {
                        try self.appDelegate.mpcHandler.session.send(cardIndexData, toPeers: self.appDelegate.mpcHandler.session.connectedPeers, with: .reliable)
                    } catch let error as NSError {
                        print("SENDING ERROR: \(error.localizedDescription)")
                    }
                }
                self.deadCard = false
            }
        })
        
        return cardsInHand
    }
    
    func getNextCardFromDeck() -> Card? {
        if let nextCard = self.cardsInDeck.popLast() {
            nextCard.frame = CGRect(x: l.leftMargin + (CGFloat(chosenCardIndex + 1) * l.cardSize), y: l.btmMargin + l.cardSize, width: l.cardSize, height: l.cardSize * 1.23)
            self.view.addSubview(nextCard)
            return nextCard
        } else {
            
            beforeP1Deal = totalCards + 1
            beforeP2Deal = totalCards + 1
            afterP2Deal = totalCards + 1
            
            cardsInDeck = createAndShuffleDeck(seed: seed)
            
            // shuffle again
            if seed == nil {
                cardsInDeck = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: cardsInDeck) as! [Card]
            } else {
                let lcg = GKLinearCongruentialRandomSource(seed: UInt64(seed!))
                cardsInDeck = lcg.arrayByShufflingObjects(in: cardsInDeck) as! [Card]
            }
            
            for i in 0..<cardsInDeck.count {
                cardsInDeck[i].index = i
            }
            cardsInDeck = cardsInDeck.reversed()
            
            return getNextCardFromDeck()
        }
    }
    
    // MARK: - Turn-Based Methods
    
    // pass-n-play
    func swapHands(_ hand: [Card]) {
        let cardsInHand = getCurrentHand()
        
        UIView.animate(withDuration: 0.5, delay: 1.5, options: [], animations: {
            // fade out cards and player indicator label
            self.playerIndicator.alpha = 0
            self.playerTurnLabel.alpha = 0
            
            // if dealing, hide card amount, else always show
            if self.cardsInDeck.count == self.beforeP2Deal {
                self.cardsLeftLabel.alpha = 0
            }
            
            for card in cardsInHand {
                card.alpha = 0
            }
            
        }, completion: { _ in
            self.waitForReady = true
            self.cardsOnBoard[self.mostRecentIndex].isMostRecent = true
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                if self.currentPlayer != 1 {
                    self.playerIndicator.image = UIImage(named: "orange")
                    self.playerTurnLabel.text = "Orange, tap for control"
                } else {
                    self.playerIndicator.image = UIImage(named: "blue")
                    self.playerTurnLabel.text = "Blue, tap for control"
                }
                self.playerIndicator.alpha = 1
                self.playerTurnLabel.alpha = 1
            })
        })
    }
    
    func swapToNextPlayer(_ hand: [Card]) {
        
        var cardsInHand = getCurrentHand()
        
        if self.cardsInDeck.count == self.beforeP1Deal {
            self.playerTurnLabel.text = "Orange's turn"
            self.drawCards(forPlayer: 1)
            return
        }
        
        if self.cardsInDeck.count == self.beforeP2Deal {
            self.drawCards(forPlayer: 2)
        }
        
        for card in cardsInHand {
            card.removeFromSuperview()
        }
        
        // shows cards on turns after dealing has taken place
        if self.currentPlayer == 1 {
            self.cardsInHand1 = hand
            self.currentPlayer = 2
            
            if self.cardsInDeck.count < self.afterP2Deal {
                for i in 0..<5 {
                    self.cardsInHand2[i].frame = CGRect(x: self.l.leftMargin + (CGFloat(i + 1) * self.l.cardSize), y: self.l.btmMargin + self.l.cardSize, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                    self.view.addSubview(self.cardsInHand2[i])
                }
            }
        } else {
            self.cardsInHand2 = hand
            self.currentPlayer = 1
            
            for i in 0..<5 {
                self.cardsInHand1[i].frame = CGRect(x: self.l.leftMargin + (CGFloat(i + 1) * self.l.cardSize), y: self.l.btmMargin + self.l.cardSize, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                self.view.addSubview(self.cardsInHand1[i])
            }
        }
        
        waitForAnimations = true
        cardsInHand = self.getCurrentHand()
        
        for card in cardsInHand {
            card.alpha = 0
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
            for card in cardsInHand {
                card.alpha = 1
            }
            if self.cardsInDeck.count < self.afterP2Deal {
                self.playerIndicator.alpha = 1
                self.playerTurnLabel.alpha = 1
            }
        }, completion: { _ in
            self.waitForAnimations = false
        })
    }
    
    // multiplayer
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
            })
        })
    }
}

