//
//  GameViewController.swift
//  Chain Five
//
//  Created by Kyle Johnson on 11/23/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit
import AudioToolbox
import GameplayKit
import GameKit

// MARK: - Game

/// The game itself, aka main portion of the application.
class GameViewController: UIViewController {
    
    // MARK: - Instance Variables
    
    // clubs, diamonds, hearts, spades
    let suits = ["C", "D", "H", "S"]

    // board layout
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

    // taptic engine shortcuts
    enum Taptics: SystemSoundID {
        case peek = 1519, pop = 1520, nope = 1521
    }
    
    let l = Layout()
    let detector = ChainDetector()
    var confettiView = SAConfettiView()
    var views: GameVCViews!
    var helpView: HelpView!
    var progressHUD: ProgressHUD!
    
    // random seed for shuffle
    var seed = Int()
    
    // main UI views
    var cardsOnBoard = [Card]()    // 10x10 grid -- 100 cards total
    var bottomBorder = UIView()
    var gameTitle = UIImageView()
    var deck = UIImageView()
    var jackOutline = UIView()
    var deckOutline = UIView()
    var gameOver = UIView()
    
    // status elements
    var playerIndicator = UIImageView()
    var playerTurnLabel = UILabel()
    var cardsLeftLabel = UILabel()
    
    // tapable icons
    var menuIcon = UIImageView()
    var helpIcon = UIImageView()
    var messageIcon = UIImageView()
    
    // related to deck
    let totalCards = 104
    var cardsInDeck = [Card]() {
        didSet {
            if cardsInDeck.count == 0 {
                self.cardsLeftLabel.text = "\(totalCards)"
            } else {
                self.cardsLeftLabel.text = "\(self.cardsInDeck.count)"
            }
        }
    }
    
    // related to hand
    var cardsInHand1 = [Card]()
    var cardsInHand2 = [Card]()
    var beforeP1Deal = Int()
    var beforeP2Deal = Int()
    var afterP2Deal = Int()
    
    // related to currently chosen card
    var chosenCardId = ""
    var chosenCardIndex = -1
    var lastSelectedCardIndex = -1
    var mostRecentIndex = -1
    var cardChosen: Bool = false {
        didSet {
            if cardChosen == false {
                for c in cardsOnBoard {
                    c.isSelected = false
                }
                jackOutline.removeOutline()
                deckOutline.removeOutline()
            }
        }
    }
    
    // for keeping track of whose turn it is
    var playerID = 0
    var currentPlayer = 0 {
        didSet {
            if isMultiplayer {
                if playerID == currentPlayer {
                    playerTurnLabel.text = "Your turn"
                    if playerID == 1 {
                        playerIndicator.image = UIImage(named: "orange")
                    } else {
                        playerIndicator.image = UIImage(named: "blue")
                    }
                } else {
                    playerTurnLabel.text = "\(opponentName)'s turn"
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
            deadSwapped = false
        }
    }
    
    // other checks
    var waitForReady = false
    var waitForAnimations = false
    var helpPresented = false
    var deadCard = false
    var deadSwapped = false
    
    // set by Main VC, host determined by seed
    var isMultiplayer = false
    var isHost = false
    var approvesRematch = false
    var opponentName = String()
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set these only once per session
        beforeP1Deal = totalCards
        beforeP2Deal = totalCards - 6
        afterP2Deal = totalCards - 11

        print("isMultiplayer: \(isMultiplayer)")
        if isMultiplayer {
            getOpponentName()
        }
        
        views = GameVCViews(view: self.view)
        
        generateTitleAndViews()
        generateBoard()
        generateRandomSeed()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        beginGame()
    }
    
    func beginGame() {
        
        if isMultiplayer {
            sendRandomSeed()
        } else {
            playerTurnLabel.text = "Orange, tap when ready"
            cardsInDeck = createDeck()
            cardsInDeck = shuffleDeck()
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: {
                self.animateItemsIntoView()
            }, completion: { _ in
                self.waitForReady = true
            })
        }
    }
    
    func getOpponentName() {
        if var displayName = GCHelper.sharedInstance.match.players.first?.displayName {
            displayName.removeFirst()
            displayName.removeFirst()
            displayName.removeLast()
            opponentName = displayName
        }
    }
    
    func generateRandomSeed() {
        seed = Int(arc4random_uniform(1000000))  // 1 million possibilities
    }
    
    func sendRandomSeed() {
        
        // convert data to json
        let seedDict = ["seed": seed] as [String: Int]
        let seedData = try! JSONSerialization.data(withJSONObject: seedDict, options: .prettyPrinted)
        
        // try to send the data
        do {
            try GCHelper.sharedInstance.match.sendData(toAllPlayers: seedData, with: .reliable)
        } catch {
            print("An unknown error occured while sending data")
        }
    }
    
    func generateTitleAndViews() {
        
        gameTitle = views.getGameTitle()
        
        (playerIndicator, playerTurnLabel) = views.getPlayerDetails()
        (deck, deckOutline, cardsLeftLabel) = views.getDeckAndRelated()
        
        (menuIcon, helpIcon) = views.getMenuAndHelpIcons()
        
        if isMultiplayer {
            messageIcon = views.getMessageIcon()
        }
    }
    
    func animateItemsIntoView() {
        menuIcon.frame.origin.x = l.leftMargin
        helpIcon.frame.origin.x = l.leftMargin + 9 * l.cardSize
        deck.frame.origin.x = l.leftMargin + l.cardSize * 8
        playerIndicator.frame.origin.x = l.leftMargin + l.cardSize * 0.05
        playerTurnLabel.frame.origin.x = l.leftMargin + l.cardSize * 1.1
        
        if isMultiplayer {
            messageIcon.frame.origin.x = self.l.leftMargin + self.l.cardSize * 6.85
        }
    }
    
    func generateBoard() {
        
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
        
        bottomBorder = views.getBottomBorder()
        jackOutline = views.getJackOutline()
    }
    
    func createDeck() -> [Card] {
        
        var deck: [Card] = []
        
        // generate two decks
        var j = 0
        while (j < 2) {
            for suit in 0..<suits.count {
                for rank in 1...13 {
                    let card = Card(named: "\(suits[suit])\(rank)+")
                    deck.append(card)
                    
                    /*
                    if rank % 2 == 0 {
                        let card = Card(named: "D11+")
                        deck.append(card)
                    } else {
                        let card = Card(named: "D4+")
                        deck.append(card)
                    }
                    */
                }
            }
            j += 1
        }
        
        return deck
    }
    
    func shuffleDeck() -> [Card] {
        
        var deck = cardsInDeck
        
        let lcg = GKLinearCongruentialRandomSource(seed: UInt64(seed))
        deck = lcg.arrayByShufflingObjects(in: cardsInDeck) as! [Card]
        
        for i in 0..<deck.count {
            deck[i].index = i
        }
        
        // reversed so that indices are in a logical order (1st card, 2nd card, etc.)
        return deck.reversed()
    }
    
    func drawCards(forPlayer player: Int = 1) {
        
        waitForAnimations = true
        
        // discard player 1's draw if player 2
        if isMultiplayer && playerID == 2 {
            for _ in 1...5 {
                _ = self.cardsInDeck.popLast()
            }
        }
        
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
        
        // discard player 2's draw if player 1
        if isMultiplayer && playerID == 1 {
            for _ in 1...5 {
                _ = cardsInDeck.popLast()
            }
        }
    }
    
    // MARK: - Touch Events
    
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
    
    func triggerFullscreenEvents(_ touchLocation: CGPoint) -> Bool {
        
        var touch = false
        
        // dismiss help view
        if helpPresented {
            helpView.removeFromSuperview()
            helpPresented = false
            touch = true
        }
        
        guard touch == false else { return touch }
        
        // for pass-n-play
        if waitForReady {
            if currentPlayer == 0 {
                currentPlayer = 1
                playerID = 1
            }
            waitForAnimations = true
            swapToNextPlayer(getCurrentHand())
            waitForReady = false
            touch = true
        }
        
        return touch
    }
    
    func triggerIconEvents(_ touchLocation: CGPoint) {
        
        // disable buttons if game is over
        guard confettiView.isActive() == false else { return }
        
        // go back to main menu
        if menuIcon.frame.contains(touchLocation) {
            AudioServicesPlaySystemSound(Taptics.pop.rawValue)
            presentMenuAlert()
        }
        
        // show tutorial
        if helpIcon.frame.contains(touchLocation) {
            AudioServicesPlaySystemSound(Taptics.pop.rawValue)
            presentHelpView()
            helpPresented = true
        }
        
        // compose message to other player
        if messageIcon.frame.contains(touchLocation) {
            AudioServicesPlaySystemSound(Taptics.pop.rawValue)
            presentMessageView()
        }
    }
    
    func triggerDeadCardSwap() {
        
        AudioServicesPlaySystemSound(Taptics.peek.rawValue)
        
        if cardsInDeck.count == 1 {
            self.cardsLeftLabel.text = "\(totalCards)"
        } else if cardsInDeck.count == 0 {
            self.cardsLeftLabel.text = "\(totalCards - 1)"
        } else {
            self.cardsLeftLabel.text = "\(self.cardsInDeck.count - 1)"
        }
        
        animateNextCardToHand()
        deadSwapped = true
        
        if isMultiplayer {
            // convert data to json
            let cardIndexDict = ["cardIndex": -1, "owner": self.currentPlayer] as [String: Int]
            let cardIndexData = try! JSONSerialization.data(withJSONObject: cardIndexDict, options: .prettyPrinted)
            
            // try to send the data
            do {
                try GCHelper.sharedInstance.match.sendData(toAllPlayers: cardIndexData, with: .reliable)
            } catch {
                print("An unknown error occured while sending data")
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self.view)
            
            guard triggerFullscreenEvents(touchLocation) == false else { return }
            triggerIconEvents(touchLocation)
            
            var cardsInHand = getCurrentHand()
            
            // check if we are trading out a dead card (doesn't count as a turn so exit early)
            if deckOutline.isOutlined() && deck.frame.contains(touchLocation) {
                // don't allow replacing a dead card if off turn or already swapped
                if currentPlayer != playerID || deadSwapped {
                    wrongTurn()
                    deckOutline.removeOutline()
                    cardsInHand[chosenCardIndex].isSelected = false
                } else {
                    triggerDeadCardSwap()
                }
            }
            
            // reset taptic feedback if no card in hand is touched
            // this ensures feedback is always registered once per card
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
            
            // BEGIN CARDS ON BOARD LOOP
            
            for c in cardsOnBoard {
                if ((c.isSelected || (isBlackJack() && c.isMarked == false)) && !c.isFreeSpace && (c.owner != playerID || deckOutline.isOutlined() == false) && c.frame.contains(touchLocation)) {
                    
                    // disallow play off turn
                    if isMultiplayer && currentPlayer != playerID {
                        wrongTurn()
                        
                    } else {
                        waitForAnimations = true
                        
                        if isMultiplayer {
                            c.owner = playerID
                        } else {
                            c.owner = currentPlayer
                        }
                        
                        if c.isMarked == false {
                            c.isMarked = true
                            for c in cardsOnBoard {
                                c.isMostRecent = false
                            }
                            
                            if isMultiplayer {
                                print("marker at index \(c.index) placed by self")
                            } else {
                                let team = playerID == 1 ? "Orange" : "Blue"
                                print("marker at index \(c.index) placed by \(team)")
                            }
                        } else {
                            
                            if (isRedJack()) {
                                c.owner = 0
                                c.isMarked = false
                                c.isMostRecent = true
                                if isMultiplayer {
                                    c.removeMarker()
                                } else {
                                    c.fadeMarker()
                                }
                                
                                if isMultiplayer {
                                    print("marker at index \(c.index) removed by self")
                                } else {
                                    let team = playerID == 1 ? "Orange" : "Blue"
                                    print("marker at index \(c.index) removed by \(team)")
                                }
                            }
                        }

                        // convert data to json
                        let cardIndexDict = ["cardIndex": c.index, "owner": c.owner] as [String: Int]
                        let cardIndexData = try! JSONSerialization.data(withJSONObject: cardIndexDict, options: .prettyPrinted)
                        
                        // send move to other player
                        if isMultiplayer {
                            // try to send the data
                            do {
                                try GCHelper.sharedInstance.match.sendData(toAllPlayers: cardIndexData, with: .reliable)
                            } catch {
                                print("An unknown error occured while sending data")
                            }
                        }
                        
                        // check if we have a chain
                        let (isValidChain, winningIndices) = detector.isValidChain(cardsOnBoard, currentPlayer)
                        
                        if isValidChain {
                            playChainAnimation(winningIndices)
                        } else {
                            // not a chain, place and draw like normal
                            AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                            mostRecentIndex = c.index
                            
                            if cardsInDeck.count == 1 {
                                self.cardsLeftLabel.text = "\(totalCards)"
                            } else if cardsInDeck.count == 0 {
                                self.cardsLeftLabel.text = "\(totalCards - 1)"
                            } else {
                                self.cardsLeftLabel.text = "\(self.cardsInDeck.count - 1)"
                            }
                            
                            animateNextCardToHand()
                            
                            if isMultiplayer {
                                self.changeTurns()
                            }
                        }
                    }
                }
            }
            
            // END CARDS ON BOARD LOOP
            
            cardChosen = false
            chosenCardId = ""
            
            // BEGIN CARDS IN HAND LOOP
            
            // used for highlighting cards on game board when selected in deck
            for i in 0..<cardsInHand.count {
                
                cardsInHand[i].isSelected = false
                
                if waitForAnimations == false && cardsInHand[i].frame.contains(touchLocation) {
                    cardsInHand[i].isSelected = true
                    
                    // plays taptic feedback when touching each card in hand
                    if cardsInHand[i].index != lastSelectedCardIndex {
                        lastSelectedCardIndex = cardsInHand[i].index
                        AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                    }
                    
                    cardChosen = true
                    chosenCardIndex = i
                    chosenCardId = cardsInHand[i].id
                    
                    // select matching cards on board
                    for c in cardsOnBoard {
                        c.isSelected = false
                        c.isMostRecent = false
                        if c.marker.alpha == 0.5 {
                            c.subviews.forEach { $0.removeFromSuperview() }
                        }
                        if !c.isMarked && chosenCardId == "\(c.id)+" {
                            c.isSelected = true
                        }
                    }
                    
                    // special case for black jack
                    if isBlackJack() {
                        jackOutline.addOutline()
                    } else {
                        jackOutline.removeOutline()
                    }
                    
                    // special case for red jack
                    if isRedJack() {
                        for c in cardsOnBoard {
                            if c.isMarked && c.owner != playerID {
                                c.isSelected = true
                            }
                        }
                    }
                    
                    checkForDeadCard()
                }
            }
            
            // END CARDS IN HAND LOOP
        }
    }
    
    // MARK: - Helper Methods
    
    func wrongTurn() {
        playerIndicator.shake()
        playerTurnLabel.shake()
        AudioServicesPlaySystemSound(Taptics.nope.rawValue)
    }
    
    func getCurrentHand() -> [Card] {
        if isMultiplayer {
            return cardsInHand1
        } else {
            return currentPlayer == 1 ? cardsInHand1 : cardsInHand2
        }
    }
    
    func animateNextCardToHand() {
        
        let container = UIView()
        container.frame = CGRect(x: l.leftMargin + l.cardSize * 8, y: l.btmMargin + l.cardSize * 2 + l.cardSize * 0.23, width: l.cardSize, height: l.cardSize * 1.23)
        container.layer.zPosition = 1
        
        let back = Card(named: "-back")
        back.frame = CGRect(x: 0, y: 0, width: l.cardSize, height: l.cardSize * 1.23)
        
        view.addSubview(container)
        container.addSubview(back)
        
        deckOutline.removeOutline()
        
        // grab the current hand
        var cardsInHand = getCurrentHand()
        
        UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseOut], animations: {
            container.frame.origin = cardsInHand[self.chosenCardIndex].frame.origin
            cardsInHand[self.chosenCardIndex].removeFromSuperview()
            
        }, completion: { _ in
            
            if let nextCard = self.getNextCardFromDeck() {
                cardsInHand[self.chosenCardIndex].removeFromSuperview()
                cardsInHand[self.chosenCardIndex] = nextCard
                
                if self.currentPlayer == 1 || self.isMultiplayer {
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

            if self.isMultiplayer == false && self.deadCard == false {
                self.swapHands(cardsInHand)
            }
        })
    }
    
    func generateNewDeck() {
        
        // ensure dealing does not happen again
        beforeP1Deal = totalCards + 1
        beforeP2Deal = totalCards + 1
        afterP2Deal = totalCards + 1
        
        // generate and shuffle a new deck
        cardsInDeck = createDeck()
        cardsInDeck = shuffleDeck()
        
        // shuffle it again
        cardsInDeck = shuffleDeck()
    }
    
    // called for player on turn
    func getNextCardFromDeck() -> Card? {
        
        if let nextCard = self.cardsInDeck.popLast() {
            nextCard.frame = CGRect(x: l.leftMargin + (CGFloat(chosenCardIndex + 1) * l.cardSize), y: l.btmMargin + l.cardSize, width: l.cardSize, height: l.cardSize * 1.23)
            self.view.addSubview(nextCard)
            return nextCard
        } else {
            // our deck is out of cards, so get a fresh deck
            generateNewDeck()
            return getNextCardFromDeck()
        }
    }
    
    // called for opponent off turn
    func popLastCard() {
        
        if let _ = self.cardsInDeck.popLast() {
            // removes card from our deck
        } else {
            // our deck is out of cards, so get a fresh deck
            generateNewDeck()
            popLastCard()
        }
    }
    
    func clearAllHighlighting() {
        
        let cardsInHand = getCurrentHand()
        
        for card in cardsInHand {
            card.isSelected = false
        }
        
        for c in cardsOnBoard {
            c.isSelected = false
        }
        
        jackOutline.removeOutline()
        deckOutline.removeOutline()
    }
    
    func checkForDeadCard() {
        
        deadCard = true
        
        if isJack() {
            deadCard = false
        }
        
        // check for dead cards
        for c in cardsOnBoard {
            if !c.isMarked && chosenCardId == "\(c.id)+" {
                deadCard = false
            }
        }
        
        // can only swap one dead card per turn
        if deadCard && deadSwapped == false {
            deckOutline.addOutline()
        } else {
            deckOutline.removeOutline()
        }
    }
    
    func isJack() -> Bool {
        return (chosenCardId == "C11+" || chosenCardId == "S11+" || chosenCardId == "D11+" || chosenCardId == "H11+")
    }
    
    // goes anywhere
    func isBlackJack() -> Bool {
        return (chosenCardId == "C11+" || chosenCardId == "S11+")
    }
    
    // removes an opponent
    func isRedJack() -> Bool {
        return (chosenCardId == "D11+" || chosenCardId == "H11+")
    }
    
    func presentMenuAlert() {
        let ac = UIAlertController(title: "Are you sure?", message: "This will end the game in progress.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "No", style: .cancel))
        ac.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            if self.isMultiplayer {
                GCHelper.sharedInstance.match.disconnect()
            }
            self.gameOver.removeFromSuperview()
            self.performSegue(withIdentifier: "toMain", sender: self)
        })
        self.present(ac, animated: true)
    }
    
    func presentHelpView() {
        helpView = HelpView(frame: view.frame)
        view.addSubview(helpView)
    }
    
    func presentMessageView() {
        
        let ac = UIAlertController(title: "To \"\(opponentName)\"", message: "", preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Send", style: .default, handler: {
            alert -> Void in
            let message = ac.textFields![0] as UITextField
            
            if message.text != "" {
                // send message to other player
                let messageDict = ["message": message.text!] as [String: String]
                let messageData = try! JSONSerialization.data(withJSONObject: messageDict, options: .prettyPrinted)
                do {
                    try GCHelper.sharedInstance.match.sendData(toAllPlayers: messageData, with: .reliable)
                } catch {
                    print("An unknown error occured while sending data")
                }
            }
        }))
        
        ac.addTextField(configurationHandler: { (textField) -> Void in
            textField.placeholder = "Your message to \(self.opponentName)"
            textField.textAlignment = .left
        })
        
        self.present(ac, animated: true)
    }
    
    // MARK: - Turn-Based
    
    // same device
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
                    self.playerTurnLabel.text = "Orange, tap when ready"
                } else {
                    self.playerIndicator.image = UIImage(named: "blue")
                    self.playerTurnLabel.text = "Blue, tap when ready"
                }
                
                self.playerIndicator.alpha = 1
                self.playerTurnLabel.alpha = 1
            })
        })
    }
    
    // same device
    func swapToNextPlayer(_ hand: [Card]) {
        
        var cardsInHand = getCurrentHand()
        
        if self.cardsInDeck.count == self.beforeP1Deal {
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
            self.playerID = 2
            
            if self.cardsInDeck.count < self.afterP2Deal {
                for i in 0..<5 {
                    self.cardsInHand2[i].frame = CGRect(x: self.l.leftMargin + (CGFloat(i + 1) * self.l.cardSize), y: self.l.btmMargin + self.l.cardSize, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                    self.view.addSubview(self.cardsInHand2[i])
                }
            }
        } else {
            self.cardsInHand2 = hand
            self.currentPlayer = 1
            self.playerID = 1
            
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
        
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            for card in cardsInHand {
                card.alpha = 1
            }
            if self.cardsInDeck.count < self.afterP2Deal {
                self.playerIndicator.alpha = 1
                self.playerTurnLabel.alpha = 1
            }
        }, completion: { _ in
            if self.cardsInDeck.count < self.afterP2Deal {
                self.waitForAnimations = false
            }
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
    
    // MARK: - End Game
    
    func playChainAnimation(_ winningIndices: [Int]) {
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // clear highlighting in hand and on board
        clearAllHighlighting()
        
        // play chain animation
        for i in 0..<winningIndices.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) { [unowned self] in
                self.cardsOnBoard[winningIndices[i]].subviews.forEach { $0.removeFromSuperview() }
                self.cardsOnBoard[winningIndices[i]].isChecked = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [unowned self] in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            self.presentWinScreen()
        }
    }
    
    func presentWinScreen() {
        
        showWinningColor()
        showConfetti()
        
        if currentPlayer == 1 {
            presentChainAlert(title: "It's a Chain!", message: "Orange has won the game.")
        } else {
            presentChainAlert(title: "It's a Chain!", message: "Blue has won the game.")
        }
    }
    
    func showWinningColor() {
        
        // orange for player 1, blue for player 2
        let orange = UIColor(red: 255/255, green: 180/255, blue: 1/255, alpha: 1).cgColor
        let blue = UIColor(red: 94/255, green: 208/255, blue: 255/255, alpha: 1).cgColor
        
        let gameOverColor = currentPlayer == 1 ? orange : blue
  
        gameOver.frame = view.frame
        gameOver.layer.backgroundColor = gameOverColor
        gameOver.layer.zPosition = 2
        view.addSubview(gameOver)
        
        gameOver.alpha = 0
        // fade in color
        UIView.animate(withDuration: 1.0, animations: {
            self.gameOver.alpha = 0.5
        })
    }
    
    func showConfetti() {
        confettiView = SAConfettiView(frame: self.view.frame)
        view.addSubview(confettiView)
        confettiView.startConfetti()
    }
    
    func presentChainAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Main Menu", style: .cancel) { _ in
            if self.isMultiplayer {
                self.sendRematchStatus(status: 0)
            }
            self.performSegue(withIdentifier: "toMain", sender: self)
        })
        if isMultiplayer {
            ac.addAction(UIAlertAction(title: "Rematch!", style: .default) { _ in
                self.progressHUD = ProgressHUD(text: "Waiting...")
                self.progressHUD.layer.zPosition = 3
                self.view.addSubview(self.progressHUD)
                self.sendRematchStatus(status: 1)
                self.waitForRematch(0)
                self.waitForAnimations = true
            })
        } else {
            ac.addAction(UIAlertAction(title: "Play Again!", style: .default) { _ in
                self.reloadGame()
            })
        }
        
        self.present(ac, animated: true)
    }
    
    func sendRematchStatus(status: Int) {
        // convert data to json
        let rematchDict = ["rematch": status] as [String: Int]
        let rematchData = try! JSONSerialization.data(withJSONObject: rematchDict, options: .prettyPrinted)
        
        // try to send the data
        do {
            try GCHelper.sharedInstance.match.sendData(toAllPlayers: rematchData, with: .reliable)
        } catch {
            print("An unknown error occured while sending data")
        }
    }
    
    // polls 10 times per second for 15 seconds
    func waitForRematch(_ iteration: Int) {
        
        if approvesRematch {
            reloadGame()
            
        } else {
            if iteration > 150 {
                print("other player did not accept in time, quitting")
                self.sendRematchStatus(status: 0)
                let ac = UIAlertController(title: "Connection Lost", message: "Opponent did not rematch within reasonable time!", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.performSegue(withIdentifier: "toMain", sender: self)
                })
                self.present(ac, animated: true)
                return
            }
            
            runThisAfterDelay(seconds: 0.1, after: {
                self.waitForRematch(iteration + 1)
            })
        }
    }
    
    func denyRematch() {
        
        let ac = UIAlertController(title: "Rematch Denied", message: "Opponent has left the game!", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.performSegue(withIdentifier: "toMain", sender: self)
        })
        self.present(ac, animated: true)
        
        // ensures popup is shown if alert queue is clogged, but only in game over scenario
        if confettiView.isActive() {
            runThisAfterDelay(seconds: 1, after: {
                self.denyRematch()
            })
        }
    }
    
    func reloadGame() {
        
        // remove all subviews
        view.subviews.forEach({ $0.removeFromSuperview() })
        views = GameVCViews(view: self.view)
        
        seed = Int()
        
        cardsOnBoard = []
        cardsInDeck = []
        cardsInHand1 = []
        cardsInHand2 = []
        
        chosenCardId = ""
        chosenCardIndex = -1
        lastSelectedCardIndex = -1
        mostRecentIndex = -1
        cardChosen = false
        
        playerID = 0
        currentPlayer = 0
        
        waitForReady = false
        waitForAnimations = false
        helpPresented = false
        deadCard = false
        deadSwapped = false
        
        isHost = false
        approvesRematch = false

        generateTitleAndViews()
        generateBoard()
        generateRandomSeed()
        
        runThisAfterDelay(seconds: 0.5, after: {
            self.beginGame()
        })
    }
    
    func runThisAfterDelay(seconds: Double, after: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            after()
        }
    }
}

// MARK: - Extensions

extension UIView {
    // Used to bring attention to player indicator and turn label when user tries to go off-turn
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        layer.add(animation, forKey: "shake")
    }
    
    // for black jack board outlining and deck outlining
    func addOutline() {
        let l = Layout()
        self.layer.borderWidth = l.highlight
    }
    
    func removeOutline() {
        self.layer.borderWidth = 0
    }
    
    func isOutlined() -> Bool {
        let l = Layout()
        if self.layer.borderWidth == l.highlight {
            return true
        } else {
            return false
        }
    }
}

// MARK: - Game Center Triggers

extension GameViewController: GCHelperDelegate {
    
    func matchStarted() {
        print("matchStarted (GAME -- should never occur)")
    }
    
    func match(_ theMatch: GKMatch, didReceiveData data: Data, fromPlayer playerID: String) {
        
        do {
            let data = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
            
            // determine who goes first, and generate same decks based on theirs
            if let opponentSeed = data["seed"] as? Int, currentPlayer == 0 {
                print("opponent seed: \(opponentSeed)")
                print("my seed: \(self.seed)")
                
                // "I mean, there's a 1 in a million chance..." - literally.
                guard self.seed != opponentSeed else {
                    reloadGame()
                    return
                }
                
                UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: {
                    self.animateItemsIntoView()
                    
                }, completion: { _ in
                    
                    if self.seed > opponentSeed {
                        self.isHost = true
                        self.playerID = 1
                    } else {
                        self.seed = opponentSeed
                        self.playerID = 2
                    }
                    
                    print("isHost? \(self.isHost)")
                    self.cardsInDeck = self.createDeck()
                    self.cardsInDeck = self.shuffleDeck()
                    self.currentPlayer = 1
                    
                    self.drawCards()
                })
            }
            
            // opponenet has made their move or replaced a dead card
            if let cardIndex = data["cardIndex"] as? Int, let owner = data["owner"] as? Int {
                
                // opponent drew for dead card, update our own deck
                if cardIndex == -1 {
                    popLastCard()
                    return
                }
                
                // if the spot isn't already marked
                if cardsOnBoard[cardIndex].isMarked == false {
                    
                    print("marker at index \(cardIndex) placed by \(opponentName)")
                    cardsOnBoard[cardIndex].owner = owner
                    cardsOnBoard[cardIndex].isMarked = true
                    
                    for c in cardsOnBoard {
                        c.isMostRecent = false
                    }
                    
                    if isRedJack() {
                        cardsOnBoard[cardIndex].isSelected = true
                    } else {
                        cardsOnBoard[cardIndex].isSelected = false
                        
                        var noneSelected = true
                        if cardChosen {
                            for c in cardsOnBoard {
                                if c.isSelected {
                                    noneSelected = false
                                }
                            }
                            
                            if noneSelected {
                                deadCard = true
                            } else {
                                deadCard = false
                            }
                            
                            // can only swap one dead card per turn
                            if deadCard && deadSwapped == false {
                                deckOutline.addOutline()
                            } else {
                                deckOutline.removeOutline()
                            }
                        }
                    }
                    
                    // test for chain
                    let (isValidChain, winningIndices) = detector.isValidChain(cardsOnBoard, currentPlayer)
                    
                    if isValidChain {
                        playChainAnimation(winningIndices)
                    } else {
                        popLastCard()  // discard other player's drawn card
                        AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                        cardsOnBoard[cardIndex].isMostRecent = true
                        changeTurns()
                    }
                    
                } else {
                    // if the spot is already marked, other player removed marker using jack
                    print("marker at \(cardIndex) removed by \(opponentName)")
                    AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                    
                    cardsOnBoard[cardIndex].isMarked = false
                    cardsOnBoard[cardIndex].isMostRecent = true
                    cardsOnBoard[cardIndex].owner = 0
                    cardsOnBoard[cardIndex].fadeMarker()
                    popLastCard()
                    
                    // if player is holding a dead card and an opportunity opens, highlight it
                    if cardsOnBoard[cardIndex].isMarked == false && chosenCardId == "\(cardsOnBoard[cardIndex].id)+" {
                        cardsOnBoard[cardIndex].isSelected = true
                        deadCard = false
                        deckOutline.removeOutline()
                    }
                    
                    changeTurns()
                }
            }
            
            // opponent requests to play again
            if let rematch = data["rematch"] as? Int {
                print("rematch?: \(rematch)")
                
                if rematch == 1 {
                    self.approvesRematch = true
                } else {
                    print("opponent quit the game")
                    self.approvesRematch = false
                    self.denyRematch()
                }
            }
            
            // text message is received from opponent
            if let message = data["message"] as? String {
                print("message: \(message)")
                
                let ac = UIAlertController(title: "From \"\(opponentName)\"", message: message, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
                self.present(ac, animated: true, completion: nil)
            }
            
        } catch {
            print("An unknown error occured while receiving data")
        }
    }
    
    func matchEnded() {
        print("matchEnded (GVC)")
        
        let ac = UIAlertController(title: "Connection Lost", message: "Opponent has left the game!", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.performSegue(withIdentifier: "toMain", sender: self)
        })
        self.present(ac, animated: true)
    }
}

