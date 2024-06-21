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
import StoreKit

// MARK: - Game

/// The game itself, aka main portion of the application.
class GameViewController: UIViewController {
    
    // MARK: - Instance Variables
    
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
    
    // clubs, diamonds, hearts, spades
    let suits = ["C", "D", "H", "S"]
    
    // taptic engine shortcuts
    enum Taptics: SystemSoundID {
        case peek = 1519, pop = 1520, nope = 1521
    }
    
    let l = Layout.shared
    var views: GameVCViews!
    let detector = ChainDetector()
    var confettiView = SAConfettiView()
    
    // random seed for shuffle
    var seed: Int? = nil
    var originalSeed: Int? = nil
    
    // main UI views
    var cardsOnBoard = [Card]()    // 10x10 grid -- 100 cards total
    var bottomBorder = UIView()
    var gameTitle = UIImageView()
    var deck = UIImageView()
    var jackOutline = UIView()
    var deckOutline = UIView()
    var gameOver = UIView()
    
    // game status elements
    var playerIndicator = UIImageView()
    var playerTurnLabel = UILabel()
    var cardsLeftLabel = UILabel()
    
    // tapable icons
    var menuIcon = DOFavoriteButton()
    var helpIcon = DOFavoriteButton()
    var messageIcon = DOFavoriteButton()
    
    // related to deck
    let totalCards = 104
    var timesShuffled = 0
    var cardsInDeck = [Card]() {
        didSet {
            if cardsInDeck.count == 0 {
                cardsLeftLabel.text = "\(totalCards)"
            } else {
                cardsLeftLabel.text = "\(cardsInDeck.count)"
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
            } else {
                if currentPlayer == 1 {
                    playerTurnLabel.text = "Orange's turn"
                    playerIndicator.image = UIImage(named: "orange")
                } else {
                    playerTurnLabel.text = "Blue's turn"
                    playerIndicator.image = UIImage(named: "blue")
                }
            }
            
            // allow a dead card to be swapped again (once per turn)
            alreadySwapped = false
        }
    }
    
    // dead cards
    var deadCard = false
    var alreadySwapped = false
    
    // timing related
    var waitForTurn = false
    var waitForAnimations = false
    
    // set by Main VC
    var isMultiplayer = false
    
    // determined by highest seed
    var isHost = false
    
    // rematch prompt related
    var rematchSent = false
    var rematchDenied = false
    
    // other multiplayer stuff
    var opponentName = String()
    
    // all alert views used
    var chainAlertView = SCLAlertView()
    var rematchAlertView = SCLAlertView()
    var messageAlertView = SCLAlertView()
    var messagePopupView = SCLAlertView()
    var menuAlertView = SCLAlertView()
    var helpAlertView = SCLAlertView()
    var denyAlertView = SCLAlertView()
    var connectionAlertView = SCLAlertView()
    
    // MARK: - Setup
    
    deinit {
        print("GameViewController: deinit called")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("GameViewController: viewDidLoad() called")
        
        // set once per matchup, for dealing purposes
        beforeP1Deal = totalCards
        beforeP2Deal = totalCards - 6
        afterP2Deal = totalCards - 11

        GCHelper.shared.delegate = self
        
        // determine if multiplayer
        if GCHelper.shared.match != nil {
            isMultiplayer = true
            getOpponentName()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        print("isMultiplayer: \(isMultiplayer)")
        
        views = GameVCViews(view: self.view)
        generateTitleAndViews()
        generateBoard()
        generateRandomSeed()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("GameViewController: viewDidAppear() called")
        
        beginGame()
    }
    
    func beginGame() {
        
        if isMultiplayer {
            playerTurnLabel.text = "Choosing host…"
            
            if let opponentSeed = GCHelper.shared.opponentSeed {
                determineHost(opponentSeed)
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: {
                self.animateItemsIntoView()
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.sendRandomSeed()
            }
        } else {
            playerTurnLabel.text = "Orange, tap when ready"
            cardsInDeck = createDeck()
            cardsInDeck = shuffleDeck()
            timesShuffled += 1
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: {
                self.animateItemsIntoView()
            }, completion: { _ in
                self.waitForTurn = true
            })
        }
    }
    
    func getOpponentName() {
        if var displayName = GCHelper.shared.match.players.first?.displayName {
            // remove leading and ending "smart quotes" from name
            displayName = displayName.replacingOccurrences(of: "\u{201c}", with: "")
            displayName = displayName.replacingOccurrences(of: "\u{201d}", with: "")
            opponentName = displayName
        }
    }
    
    func generateRandomSeed() {
        originalSeed = Int(arc4random_uniform(1000000))  // 1 million possibilities
        if isMultiplayer == false {
            seed = originalSeed
        }
    }
    
    func sendRandomSeed() {
        
        // convert seed to json data
        var seedDataWrapped: Data?
        if let seed = originalSeed {
            let seedDict = ["seed": seed] as [String: Int]
            seedDataWrapped = try! JSONSerialization.data(withJSONObject: seedDict, options: .prettyPrinted)
        }

        guard GCHelper.shared.match != nil else { return }
        
        // try to send the data
        do {
            if let seedData = seedDataWrapped {
                try GCHelper.shared.match.sendData(toAllPlayers: seedData, with: .reliable)
                if let seed = originalSeed {
                    print("SENT SEED TO OPPONENT \(seed)")
                }
            }
        } catch {
            print("An unknown error occured while sending data")
        }
    }
    
    func generateTitleAndViews() {
        
        gameTitle = views.getGameTitle()
        
        (playerIndicator, playerTurnLabel) = views.getPlayerDetails()
        (deck, deckOutline, cardsLeftLabel) = views.getDeckAndRelated()
        
        (menuIcon, helpIcon) = views.getMenuAndHelpIcons()
        menuIcon.addTarget(self, action: #selector(iconTapped), for: .touchUpInside)
        helpIcon.addTarget(self, action: #selector(iconTapped), for: .touchUpInside)
        
        if isMultiplayer {
            messageIcon = views.getMessageIcon()
            messageIcon.addTarget(self, action: #selector(iconTapped), for: .touchUpInside)
        }
    }
    
    @objc func iconTapped(sender: DOFavoriteButton) {
        
        if sender.accessibilityIdentifier == "menu" {
            presentAlert(sender) {
                self.presentMenuAlert()
            }
        }
        
        if sender.accessibilityIdentifier == "help" {
            presentAlert(sender) {
                self.presentHelpAlert()
            }
        }
        
        if sender.accessibilityIdentifier == "message" {
            presentAlert(sender) {
                self.presentMessageAlert()
            }
        }
    }
    
    func presentAlert(_ sender: DOFavoriteButton, presentAlert: @escaping ()->()) {
        sender.select()
        AudioServicesPlaySystemSound(Taptics.pop.rawValue)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            presentAlert()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            sender.deselect()
        }
    }
    
    func animateItemsIntoView() {
        
        // move player info and deck in from left and right
        playerIndicator.frame.origin.x = l.leftMargin + l.cardSize * 0.05
        playerTurnLabel.frame.origin.x = l.leftMargin + l.cardSize * 1.1
        deck.frame.origin.x = l.leftMargin + l.cardSize * 8
        
        // move buttons in from left and right
        menuIcon.frame.origin.x = l.leftMargin - l.cardSize / 2
        helpIcon.frame.origin.x = l.leftMargin + l.cardSize * 9 - l.cardSize / 2
    }
    
    func generateBoard() {
        
        // load the 100 cards in correct layout
        var i = 0
        for row in 0...9 {
            for col in 0...9 {
                let card = Card(named: cardsLayout[i])
                card.frame = CGRect(x: l.leftMargin + (CGFloat(col) * l.cardSize), y: l.topMargin + (CGFloat(row) * l.cardSize), width: l.cardSize, height: l.cardSize)
                view.addSubview(card)
                cardsOnBoard.append(card)
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
                }
            }
            j += 1
        }
        
        return deck
    }
    
    func shuffleDeck() -> [Card] {
        
        var deck = cardsInDeck
        var lcg: GKLinearCongruentialRandomSource!
        
        if let seed = self.seed {
            lcg = GKLinearCongruentialRandomSource(seed: UInt64(seed))
            deck = lcg.arrayByShufflingObjects(in: cardsInDeck) as! [Card]
        }
        
        for i in 0..<deck.count {
            deck[i].index = i
        }
        
        // reversed so that indices are in a logical order (0 = 1st card, 1 = 2nd card, etc.)
        return deck.reversed()
    }
    
    func drawCards(forPlayer player: Int = 1) {
        
        // don't allow player to tap cards while being drawn
        waitForAnimations = true
        
        // discard player 1's draw if player 2
        if isMultiplayer && playerID == 2 {
            for _ in 1...5 {
                popLastCard()
            }
        }
        
        // choose five cards from the deck
        for col in 1...5 {
            
            // need container view for flipping animation
            let container = UIView()
            container.frame = CGRect(x: l.leftMargin + l.cardSize * 8, y: l.btmMargin + l.distance + l.cardSize * 1.23, width: l.cardSize, height: l.cardSize * 1.23)
            container.layer.zPosition = 5 - CGFloat(col)
            view.addSubview(container)
            
            // the card itself
            let back = Card(named: "-back")
            back.frame = CGRect(x: 0, y: 0, width: l.cardSize, height: l.cardSize * 1.23)
            container.addSubview(back)
            
            if let card = cardsInDeck.popLast() {
                
                // animate card from deck to hand
                UIView.animate(withDuration: 1, delay: TimeInterval(0.3 * Double(col)) + 0.3, options: [.curveEaseOut], animations: {
                    container.frame = CGRect(x: self.l.leftMargin + (CGFloat(col) * self.l.cardSize), y: self.l.btmMargin + self.l.distance, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                    
                }, completion: { _ in
                    
                    container.frame = CGRect(x: self.l.leftMargin + (CGFloat(col) * self.l.cardSize), y: self.l.btmMargin + self.l.distance, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                    card.frame = CGRect(x: 0, y: 0, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                    
                    if player == 1 {
                        self.cardsInHand1.append(card)
                    } else {
                        self.cardsInHand2.append(card)
                    }
                    
                    // once in correct position, flip over to reveal new card
                    UIView.transition(from: back, to: card, duration: 1, options: [.transitionFlipFromRight], completion: { _ in
                        card.frame = CGRect(x: self.l.leftMargin + (CGFloat(col) * self.l.cardSize), y: self.l.btmMargin + self.l.distance, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                        self.view.addSubview(card)
                    })
                    
                    // last card
                    if col == 5 {
                        self.cardsLeftLabel.text = "\(self.cardsInDeck.count)"
                        
                        UIView.animate(withDuration: 1) {
                            self.playerIndicator.alpha = 1
                            self.playerTurnLabel.alpha = 1
                            self.cardsLeftLabel.alpha = 1
                            
                            if self.isMultiplayer {
                                self.messageIcon.alpha = 1
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            self.waitForAnimations = false
                        }
                    }
                })
            }
        }
        
        // discard player 2's draw if player 1
        if isMultiplayer && playerID == 1 {
            for _ in 1...5 {
                popLastCard()
            }
        }
    }
    
    // MARK: - Touch Events
    
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
    
    func triggerDeadCardSwap() {
        
        if cardsInDeck.count == 1 {
            cardsLeftLabel.text = "\(totalCards)"
        } else if cardsInDeck.count == 0 {
            cardsLeftLabel.text = "\(totalCards - 1)"
        } else {
            cardsLeftLabel.text = "\(cardsInDeck.count - 1)"
        }
        
        AudioServicesPlaySystemSound(Taptics.peek.rawValue)
        animateNextCardToHand(false)
        alreadySwapped = true
        
        if isMultiplayer && GCHelper.shared.match != nil {
            // convert card info to json data
            let cardIndexDict = ["cardIndex": -1, "owner": currentPlayer] as [String: Int]
            let cardIndexData = try! JSONSerialization.data(withJSONObject: cardIndexDict, options: .prettyPrinted)
            
            // try to send the data
            do {
                try GCHelper.shared.match.sendData(toAllPlayers: cardIndexData, with: .reliable)
            } catch {
                print("An unknown error occured while sending data")
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self.view)
            
            // "Same Device" mode only
            if waitForTurn {
                if currentPlayer == 0 {
                    currentPlayer = 1
                    playerID = 1
                }
                waitForAnimations = true
                swapToNextPlayer(getCurrentHand())
                waitForTurn = false
                return
            }
            
            // ensure we have the current hand for the current player
            let cardsInHand = getCurrentHand()
            
            // check if we are trading out a dead card (doesn't count as a turn)
            if deckOutline.isOutlined() && deck.frame.contains(touchLocation) {
                if currentPlayer != playerID || alreadySwapped {
                    wrongTurn()
                    deckOutline.removeOutline()
                    cardsInHand[chosenCardIndex].isSelected = false
                } else {
                    triggerDeadCardSwap()
                }
            }
            
            // ensures haptic feedback is always registered once per card
            var cardTouched = false
            for i in 0..<cardsInHand.count {
                if cardTouched == false {
                    if cardsInHand[i].frame.contains(touchLocation) {
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
                if ((c.isSelected || (isBlackJack() && c.isMarked == false)) && (c.owner != playerID || deckOutline.isOutlined() == false) && c.isFreeSpace == false && c.frame.contains(touchLocation)) {
                    
                    // disallow play off turn
                    if isMultiplayer && currentPlayer != playerID {
                        wrongTurn()
                        
                    } else {
                        // after move has been made, don't allow any more moves for turn
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
                                    // leave visible so opponent can see what move was
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

                        // convert card info to json data
                        let cardIndexDict = ["cardIndex": c.index, "owner": c.owner] as [String: Int]
                        let cardIndexData = try! JSONSerialization.data(withJSONObject: cardIndexDict, options: .prettyPrinted)
                        
                        if isMultiplayer && GCHelper.shared.match != nil {
                            // update other player with our move
                            do {
                                try GCHelper.shared.match.sendData(toAllPlayers: cardIndexData, with: .reliable)
                            } catch {
                                print("An unknown error occured while sending data")
                            }
                        }
                        
                        // check if we have a chain
                        let (isValidChain, winningIndices) = detector.isValidChain(cardsOnBoard, currentPlayer)
                        
                        if cardsInDeck.count == 1 {
                            cardsLeftLabel.text = "\(totalCards)"
                        } else if cardsInDeck.count == 0 {
                            cardsLeftLabel.text = "\(totalCards - 1)"
                        } else {
                            cardsLeftLabel.text = "\(cardsInDeck.count - 1)"
                        }
                        
                        animateNextCardToHand(isValidChain)
                        
                        if isValidChain {
                            cardsInHand[chosenCardIndex].removeFromSuperview()
                            playChainAnimation(winningIndices)
                        } else {
                            // not a chain, so continue as normal
                            AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                            c.pulseMarker()
                            mostRecentIndex = c.index
                            
                            if isMultiplayer {
                                changeTurns()
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
                    
                    // plays haptic feedback when touching each card in hand
                    if cardsInHand[i].index != lastSelectedCardIndex {
                        lastSelectedCardIndex = cardsInHand[i].index
                        AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                    }
                    
                    cardChosen = true
                    chosenCardIndex = i
                    chosenCardId = cardsInHand[i].id
                    
                    for c in cardsOnBoard {
                        c.isSelected = false
                        c.isMostRecent = false
                        
                        if c.marker.alpha == 0.5 {
                            c.subviews.forEach { $0.removeFromSuperview() }
                        }
                        
                        // highlight matching cards on board
                        if c.isMarked == false && chosenCardId == "\(c.id)+" {
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
                    
                    // update selections if card is now dead
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
    
    func animateNextCardToHand(_ isValidChain: Bool) {
        
        let container = UIView()
        container.frame = CGRect(x: l.leftMargin + l.cardSize * 8, y: l.btmMargin + l.distance + l.cardSize * 1.23, width: l.cardSize, height: l.cardSize * 1.23)
        view.addSubview(container)
        
        let back = Card(named: "-back")
        back.frame = CGRect(x: 0, y: 0, width: l.cardSize, height: l.cardSize * 1.23)
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
                    
                    // activates the latest drawn card for selection (only really needed in multiplayer since hands are swapped in single player, but I'll leave it for the future)
                    if self.currentPlayer == 1 || self.isMultiplayer {
                        self.cardsInHand1[self.chosenCardIndex].frame = CGRect(x: self.l.leftMargin + (CGFloat(self.chosenCardIndex+1) * self.l.cardSize), y: self.l.btmMargin + self.l.distance, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                        self.view.addSubview(self.cardsInHand1[self.chosenCardIndex])
                    } else {
                        self.cardsInHand2[self.chosenCardIndex].frame = CGRect(x: self.l.leftMargin + (CGFloat(self.chosenCardIndex+1) * self.l.cardSize), y: self.l.btmMargin + self.l.distance, width: self.l.cardSize, height: self.l.cardSize * 1.23)
                        self.view.addSubview(self.cardsInHand2[self.chosenCardIndex])
                    }
                    
                    if self.isMultiplayer {
                        self.waitForAnimations = false
                    }
                }
            }

            if self.isMultiplayer == false && isValidChain == false && self.deadCard == false {
                self.swapHands(cardsInHand)
            }
        })
    }
    
    // for the rare, but possible case that we run out of all 104 cards
    func generateNewDeck() {
        
        // ensure dealing does not occur again
        beforeP1Deal = totalCards + 1
        beforeP2Deal = totalCards + 1
        afterP2Deal = totalCards + 1
        
        // generate and shuffle again in the same order
        cardsInDeck = createDeck()
        cardsInDeck = shuffleDeck()
        
        // reshuffle designated number of times (to keep decks in sync)
        for _ in 0..<timesShuffled {
            cardsInDeck = shuffleDeck()
        }
        timesShuffled += 1
    }
    
    func showOutOfCardsPopup() {
        
        DispatchQueue.main.async {
            let appearance = SCLAlertView.SCLAppearance(
                kDefaultShadowOpacity: 0,
                kTitleTop: 12,
                kWindowWidth: self.l.iPad ? self.l.titleWidth : 240,
                kTitleFont: UIFont.boldSystemFont(ofSize: 14),
                showCloseButton: false,
                showCircularIcon: false
            )
            self.messagePopupView = SCLAlertView(appearance: appearance)
            self.messagePopupView.showCustom("Out of Cards!", subTitle: "A new deck has been generated. This must be a good game!", color: UIColor.white, icon: UIImage(named: "alert_message")!, closeButtonTitle: "", timeout: SCLAlertView.SCLTimeoutConfiguration(timeoutValue: 5, timeoutAction: {}), colorStyle: 0x808080, colorTextButton: 0xFFFFFF, circleIconImage: UIImage(named: "alert_message")!, animationStyle: SCLAnimationStyle.topToBottom)
        }
    }
    
    // called for player on turn
    func getNextCardFromDeck() -> Card? {
        
        if let nextCard = cardsInDeck.popLast() {
            // grabs next card from deck
            if cardsInDeck.count == 0 {
                showOutOfCardsPopup()
            }
            nextCard.frame = CGRect(x: l.leftMargin + (CGFloat(chosenCardIndex + 1) * l.cardSize), y: l.btmMargin + l.distance, width: l.cardSize, height: l.cardSize * 1.23)
            view.addSubview(nextCard)
            return nextCard
        } else {
            // our deck is out of cards, so get a fresh deck
            generateNewDeck()
            return getNextCardFromDeck()
        }
    }
    
    // called for opponent off turn
    func popLastCard() {
        
        if let _ = cardsInDeck.popLast() {
            // removes card from our own deck when other player draws
            if cardsInDeck.count == 0 {
                showOutOfCardsPopup()
            }
        } else {
            // our deck is out of cards, so get a fresh deck
            generateNewDeck()
            popLastCard()
        }
    }
    
    // clears green highlighting everywhere
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
            if c.isMarked == false && chosenCardId == "\(c.id)+" {
                deadCard = false
            }
        }
        
        // can only swap one dead card per turn
        if deadCard && alreadySwapped == false {
            deckOutline.addOutline()
        } else {
            deckOutline.removeOutline()
        }
    }
    
    func isJack() -> Bool {
        return (chosenCardId == "C11+" || chosenCardId == "S11+" || chosenCardId == "D11+" || chosenCardId == "H11+")
    }
    
    // places anywhere open
    func isBlackJack() -> Bool {
        return (chosenCardId == "C11+" || chosenCardId == "S11+")
    }
    
    // removes an opponent's marker
    func isRedJack() -> Bool {
        return (chosenCardId == "D11+" || chosenCardId == "H11+")
    }
    
    // MARK: - Button Alert Views
    
    // confirm exit to menu
    func presentMenuAlert() {
        
        let appearance = SCLAlertView.SCLAppearance(
            kCircleIconHeight: 64,
            showCloseButton: false
        )
        menuAlertView = SCLAlertView(appearance: appearance)
        menuAlertView.addButton("Confirm", backgroundColor: UIColor.cfRed, textColor: UIColor.white) {
            if self.isMultiplayer && GCHelper.shared.match != nil {
                GCHelper.shared.match.disconnect()
            }
            self.dismiss(animated: true)
            GCHelper.shared.delegate = nil
            GCHelper.shared.opponentSeed = nil
        }
        menuAlertView.addButton("Cancel", backgroundColor: UIColor.gray, textColor: UIColor.white) {
        }
        menuAlertView.showCustom("Exit to Menu?", subTitle: "This will end the current game in progress.", color: UIColor.white, icon: UIImage(named: "alert_menu")!)
    }
    
    // show game tutorial
    func presentHelpAlert() {
        
        let appearance = SCLAlertView.SCLAppearance(
            kCircleIconHeight: 64,
            showCloseButton: false
        )
        helpAlertView = SCLAlertView(appearance: appearance)
        helpAlertView.addButton("Done", backgroundColor: UIColor.cfBlue, textColor: UIColor.white) {
        }
        helpAlertView.showCustom("How to Play", subTitle: "Tap your cards to view possible placements. Tap any highlighted location to make your move.\n\nCorners count as FREE spaces.\n\nBlack jacks can be placed anywhere open. Red jacks can remove an opponent's marker.\n\nA dead card may be replaced from the deck once per turn.\n\nThe first player to get 5 markers in a row wins the game!", color: UIColor.white, icon: UIImage(named: "alert_help")!)
    }

    // compose message view
    func presentMessageAlert() {
        
        let appearance = SCLAlertView.SCLAppearance(
            kCircleIconHeight: 64,
            showCloseButton: false
        )
        messageAlertView = SCLAlertView(appearance: appearance)
        let messageTextField = messageAlertView.addTextField("Hurry up, slowpoke!")
        if gameOver.superview != nil {
            messageTextField.placeholder = "Well played."
        }
        messageAlertView.addButton("Send", backgroundColor: UIColor.cfGreen, textColor: UIColor.white) {
            var message = messageTextField.text!.trimmingCharacters(in: CharacterSet.whitespaces)
            if message == "" {
                if self.gameOver.superview == nil {
                    message = "Hurry up, slowpoke!"
                } else {
                    message = "Well played."
                }
            }
            // send message to other player
            let messageDict = ["message": message] as [String: String]
            let messageData = try! JSONSerialization.data(withJSONObject: messageDict, options: .prettyPrinted)
            if self.isMultiplayer && GCHelper.shared.match != nil {
                do {
                    try GCHelper.shared.match.sendData(toAllPlayers: messageData, with: .reliable)
                } catch {
                    print("An unknown error occured while sending data")
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if self.gameOver.superview != nil {
                    self.presentChainAlert(self.rematchSent)
                }
            }
        }
        messageAlertView.addButton("Cancel", backgroundColor: UIColor.gray, textColor: UIColor.white) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if self.gameOver.superview != nil {
                    self.presentChainAlert(self.rematchSent)
                }
            }
        }
        messageAlertView.showCustom("To \"\(opponentName)\"", subTitle: "Your message to \(opponentName).", color: UIColor.gray, icon: UIImage(named: "alert_message")!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            messageTextField.becomeFirstResponder()
        }
    }
    
    // MARK: - Turn Related
    
    // "Same Device" mode
    func swapHands(_ hand: [Card]) {
        
        let cardsInHand = getCurrentHand()
        
        UIView.animate(withDuration: 0.5, delay: 1.5, options: [], animations: {
            // fade out cards and player indicator label
            self.playerIndicator.alpha = 0
            self.playerTurnLabel.alpha = 0
            
            // hide card amount when dealing
            if self.cardsInDeck.count == self.beforeP2Deal {
                self.cardsLeftLabel.alpha = 0
            }
            
            for card in cardsInHand {
                card.alpha = 0
            }
            
        }, completion: { _ in
            // wait for next player to ready up
            self.waitForTurn = true
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
    
    func swapToNextPlayer(_ hand: [Card]) {
        
        var cardsInHand = getCurrentHand()
        
        if cardsInDeck.count == beforeP1Deal {
            drawCards(forPlayer: 1)
            return
        }
        
        if cardsInDeck.count == beforeP2Deal {
            drawCards(forPlayer: 2)
        }
        
        for card in cardsInHand {
            card.removeFromSuperview()
        }
        
        // shows cards on turns after dealing has taken place
        if currentPlayer == 1 {
            cardsInHand1 = hand
            currentPlayer = 2
            playerID = 2
            
            if cardsInDeck.count < afterP2Deal {
                for i in 0..<cardsInHand2.count {
                    cardsInHand2[i].frame = CGRect(x: l.leftMargin + (CGFloat(i + 1) * l.cardSize), y: l.btmMargin + l.distance, width: l.cardSize, height: l.cardSize * 1.23)
                    view.addSubview(cardsInHand2[i])
                }
            }
            
        } else {
            cardsInHand2 = hand
            currentPlayer = 1
            playerID = 1
            
            for i in 0..<cardsInHand1.count {
                cardsInHand1[i].frame = CGRect(x: l.leftMargin + (CGFloat(i + 1) * l.cardSize), y: l.btmMargin + l.distance, width: l.cardSize, height: l.cardSize * 1.23)
                view.addSubview(cardsInHand1[i])
            }
        }
        
        waitForAnimations = true
        cardsInHand = getCurrentHand()
        
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
    
    // "Online Match" mode
    func changeTurns() {
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
            // fade out player indicator
            self.playerIndicator.alpha = 0
            self.playerTurnLabel.alpha = 0
            
        }, completion: { _ in
            self.currentPlayer = self.currentPlayer == 1 ? 2 : 1
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                // fade in player indicator
                self.playerIndicator.alpha = 1
                self.playerTurnLabel.alpha = 1
            })
        })
    }
    
    // MARK: - End Game
    
    func playChainAnimation(_ winningIndices: [Int]) {
        
        // game is over, so don't allow any more action
        waitForAnimations = true
        
        // hide button alert views if being shown
        messageAlertView.hideView()
        menuAlertView.hideView()
        helpAlertView.hideView()

        // celebration vibration! (hey that rhymed)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // clear highlighting in hand and on board
        clearAllHighlighting()
        
        // add marker to any free spaces before animation
        for i in 0..<winningIndices.count {
            if cardsOnBoard[winningIndices[i]].isFreeSpace {
                cardsOnBoard[winningIndices[i]].isMarked = true
            }
        }
        
        // play chain animation
        for i in 0..<winningIndices.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                self.cardsOnBoard[winningIndices[i]].subviews.forEach { $0.removeFromSuperview() }
                self.cardsOnBoard[winningIndices[i]].isChecked = true
            }
        }
        
        // present win alert afterwards
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            self.presentWinScreen()
        }
    }
    
    func presentWinScreen() {
        incrementGamesFinished()
        showWinningColor()
        showConfetti()
        presentChainAlert()
        
        if #available(iOS 10.3, *) {
            requestReview()
        }
        
        if isMultiplayer {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    @available(iOS 10.3, *)
    func requestReview() {
        // only allow review request after three finished games
        if currentPlayer == playerID && UserDefaults.standard.integer(forKey: "gamesFinished") >= 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                SKStoreReviewController.requestReview()
            }
        }
    }
    
    // for review request purposes
    func incrementGamesFinished() {
        let gamesFinished = UserDefaults.standard.integer(forKey: "gamesFinished")
        UserDefaults.standard.set(gamesFinished + 1, forKey: "gamesFinished")
    }
    
    func showWinningColor() {
        
        // orange for player 1, blue for player 2
        let orange = UIColor(red: 255/255, green: 180/255, blue: 1/255, alpha: 1).cgColor
        let blue = UIColor(red: 94/255, green: 208/255, blue: 255/255, alpha: 1).cgColor
        let gameOverColor = currentPlayer == 1 ? orange : blue
  
        gameOver.frame = view.frame
        gameOver.layer.backgroundColor = gameOverColor
        gameOver.layer.zPosition = 1
        view.addSubview(gameOver)
        
        gameOver.alpha = 0
        // fade in color
        UIView.animate(withDuration: 1.0, animations: {
            self.gameOver.alpha = 0.25
        })
    }
    
    // why not?
    func showConfetti() {
        confettiView = SAConfettiView(frame: view.frame)
        view.addSubview(confettiView)
        confettiView.startConfetti()
    }
    
    func presentChainAlert(_ rematchSent: Bool = false) {
        
        let appearance = SCLAlertView.SCLAppearance(
            kDefaultShadowOpacity: 0,
            kCircleIconHeight: 64,
            showCloseButton: false,
            shouldAutoDismiss: false
        )
        chainAlertView = SCLAlertView(appearance: appearance)
        if isMultiplayer {
            chainAlertView.addButton("Send a Message", backgroundColor: UIColor.cfGreen, textColor: UIColor.white) {
                self.chainAlertView.hideView()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.presentMessageAlert()
                }
            }
            let rematchText = rematchSent ? "Waiting for opponent…" : "Rematch!"
            chainAlertView.addButton(rematchText, backgroundColor: UIColor.cfBlue, textColor: UIColor.white) {
                if self.rematchSent == false {
                    self.rematchSent = true
                    self.chainAlertView.buttons[1].setTitle("Waiting for opponent…", for: UIControlState())
                    self.sendRematchStatus(status: 1)
                }
            }
        } else {
            chainAlertView.addButton("Play Again!", backgroundColor: UIColor.cfGreen, textColor: UIColor.white) {
                self.chainAlertView.hideView()
                self.reloadGame()
            }
        }
        chainAlertView.addButton("Exit to Menu", backgroundColor: UIColor.gray, textColor: UIColor.white) {
            self.chainAlertView.hideView()
            if self.isMultiplayer && GCHelper.shared.match != nil {
                GCHelper.shared.match.disconnect()
            }
            self.dismiss(animated: true)
            GCHelper.shared.delegate = nil
            GCHelper.shared.opponentSeed = nil
        }
        let alertIcon = currentPlayer == 1 ? "orange_chain" : "blue_chain"
        if self.currentPlayer == 1 {
            chainAlertView.showCustom("It's a Chain!", subTitle: "Orange has won the game.", color: UIColor.gray, icon: UIImage(named: alertIcon)!)
        } else {
            chainAlertView.showCustom("It's a Chain!", subTitle: "Blue has won the game.", color: UIColor.gray, icon: UIImage(named: alertIcon)!)
        }
    }
    
    func presentRematchAlert() {
        
        let appearance = SCLAlertView.SCLAppearance(
            kCircleIconHeight: 64,
            showCloseButton: false,
            buttonsLayout: SCLAlertButtonLayout.horizontal
        )
        rematchAlertView = SCLAlertView(appearance: appearance)
        rematchAlertView.addButton("Deny", backgroundColor: UIColor.cfRed, textColor: UIColor.white) {
            if self.isMultiplayer && GCHelper.shared.match != nil {
                self.sendRematchStatus(status: 0)
                GCHelper.shared.match.disconnect()
            }
            self.dismiss(animated: true)
            GCHelper.shared.delegate = nil
            GCHelper.shared.opponentSeed = nil
        }
        rematchAlertView.addButton("Accept", backgroundColor: UIColor.cfGreen, textColor: UIColor.white) {
            self.sendRematchStatus(status: 1)
            self.reloadGame()
        }
        rematchAlertView.showCustom("Rematch?", subTitle: "Opponent requests to play again.", color: UIColor.white, icon: UIImage(named: "alert_rematch")!)
    }
    
    func sendRematchStatus(status: Int) {
        
        // convert rematch status to json data
        let rematchDict = ["rematch": status] as [String: Int]
        let rematchData = try! JSONSerialization.data(withJSONObject: rematchDict, options: .prettyPrinted)
        
        guard GCHelper.shared.match != nil else { return }
        
        // try to send the data
        do {
            try GCHelper.shared.match.sendData(toAllPlayers: rematchData, with: .reliable)
        } catch {
            print("An unknown error occured while sending data")
        }
    }
    
    func denyRematch() {
        
        DispatchQueue.main.async {
            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton: false
            )
            self.denyAlertView = SCLAlertView(appearance: appearance)
            self.denyAlertView.addButton("Exit to Menu", backgroundColor: UIColor.gray, textColor: UIColor.white) {
                if self.isMultiplayer && GCHelper.shared.match != nil {
                    self.sendRematchStatus(status: 0)
                    GCHelper.shared.match.disconnect()
                }
                self.dismiss(animated: true)
                GCHelper.shared.delegate = nil
                GCHelper.shared.opponentSeed = nil
            }
            self.denyAlertView.showError("Rematch Denied", subTitle: "Opponent has left the game!")
        }
    }
    
    func reloadGame() {
        
        // remove all current views
        view.subviews.forEach({ $0.removeFromSuperview() })
        
        seed = nil
        originalSeed = nil
        GCHelper.shared.opponentSeed = nil
        timesShuffled = 0
        
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
        
        deadCard = false
        alreadySwapped = false
        
        waitForTurn = false
        waitForAnimations = false
        
        isHost = false
        rematchSent = false
        rematchDenied = false
        
        messagePopupView.hideView()
        
        print("isMultiplayer: \(isMultiplayer)")
        if isMultiplayer {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        views = GameVCViews(view: self.view)
        generateTitleAndViews()
        generateBoard()
        generateRandomSeed()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.beginGame()
        }
    }
    
    func determineHost(_ opponentSeed: Int) {

        if let seed = originalSeed {
            if seed > opponentSeed {
                self.isHost = true
                self.seed = seed
                self.playerID = 1
            } else {
                self.isHost = false
                self.seed = opponentSeed
                self.playerID = 2
            }
        }
        
        print("isHost? \(self.isHost)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.cardsInDeck = self.createDeck()
            self.cardsInDeck = self.shuffleDeck()
            self.timesShuffled += 1
            
            self.currentPlayer = 1
            
            print("DRAWING CARDS")
            self.drawCards()
        }
    }
}

// MARK: - Extensions

extension UIView {
    // used to bring attention to player indicator and turn label when player tries to go off-turn
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        layer.add(animation, forKey: "shake")
    }
    
    // for adding green highlight
    func addOutline() {
        let l = Layout.shared
        layer.borderWidth = l.highlight
    }
    
    // removes the green highlight
    func removeOutline() {
        layer.borderWidth = 0
    }
    
    // determines if a view is outlined or not
    func isOutlined() -> Bool {
        let l = Layout.shared
        return layer.borderWidth == l.highlight
    }
}

extension UIColor {
    // saved colors for reuse
    static var cfRed: UIColor { return UIColor(red: 193/255, green: 39/255, blue: 45/255, alpha: 1.0) }
    static var cfGreen: UIColor { return UIColor(red: 39/255, green: 188/255, blue: 86/255, alpha: 1.0) }
    static var cfBlue: UIColor { return UIColor(red: 39/255, green: 116/255, blue: 188/255, alpha: 1.0) }
}

// MARK: - Game Center Triggers

extension GameViewController: GCHelperDelegate {
    
    func matchStarted() {
        print("matchStarted")
        
        // called when game invite is accepted in-game
        if GCHelper.shared.match != nil {
            isMultiplayer = true
            getOpponentName()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        reloadGame()
    }
    
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        
        do {
            let data = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
            
            // determine who goes first based off highest seed and generate same decks
            if let opponentSeed = data["seed"] as? Int, GCHelper.shared.opponentSeed == nil {
                print("GAME RECEIVED SEED \(opponentSeed)")
                determineHost(opponentSeed)
            }
            
            // opponent has made their move or replaced a dead card
            if let cardIndex = data["cardIndex"] as? Int, let owner = data["owner"] as? Int {
                
                popLastCard()  // discard other player's drawn card
                
                // opponent drew for a dead card, update our own deck appropriately
                if cardIndex == -1 {
                    return
                }
                
                // if the spot isn't already marked, place our marker
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
                            
                            // can only swap one dead card per turn (I wonder how many times I've said this)
                            if deadCard && alreadySwapped == false {
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
                        AudioServicesPlaySystemSound(Taptics.peek.rawValue)
                        cardsOnBoard[cardIndex].pulseMarker()
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
                
                DispatchQueue.main.async {
                    self.rematchAlertView.hideView()
                    self.messageAlertView.hideView()
                    self.chainAlertView.hideView()
                    
                    if rematch == 1 {
                        // rematch approved
                        if self.rematchSent == false {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                self.presentRematchAlert()
                            }
                        } else {
                            self.reloadGame()
                        }
                    } else {
                        // rematch denied
                        self.rematchDenied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.denyRematch()
                        }
                    }
                }
            }
            
            // text message is received from opponent
            if let message = data["message"] as? String {
                print("message: \(message)")
                
                DispatchQueue.main.async {
                    let appearance = SCLAlertView.SCLAppearance(
                        kDefaultShadowOpacity: 0,
                        kTitleTop: 12,
                        kWindowWidth: self.l.iPad ? self.l.titleWidth : 240,
                        kTitleFont: UIFont.boldSystemFont(ofSize: 14),
                        showCloseButton: false,
                        showCircularIcon: false
                    )
                    self.messagePopupView = SCLAlertView(appearance: appearance)
                    self.messagePopupView.showCustom("From \"\(self.opponentName)\"", subTitle: message, color: UIColor.white, icon: UIImage(named: "alert_message")!, closeButtonTitle: "", timeout: SCLAlertView.SCLTimeoutConfiguration(timeoutValue: 5, timeoutAction: {}), colorStyle: 0x808080, colorTextButton: 0xFFFFFF, circleIconImage: UIImage(named: "alert_message")!, animationStyle: SCLAnimationStyle.topToBottom)
                }
            }
            
        } catch {
            print("An unknown error occured while receiving data")
        }
    }
    
    func matchEnded() {
        print("matchEnded")
        guard rematchDenied == false else { return }
        
        DispatchQueue.main.async {
            self.chainAlertView.hideView()
            self.rematchAlertView.hideView()
            self.messageAlertView.hideView()
            self.messagePopupView.hideView()
            self.menuAlertView.hideView()
            self.helpAlertView.hideView()
            self.denyAlertView.hideView()

            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton: false
            )
            self.connectionAlertView = SCLAlertView(appearance: appearance)
            self.connectionAlertView.addButton("Exit to Menu", backgroundColor: UIColor.gray, textColor: UIColor.white) {
                if self.isMultiplayer && GCHelper.shared.match != nil {
                    GCHelper.shared.match.disconnect()
                }
                self.dismiss(animated: true)
                GCHelper.shared.delegate = nil
                GCHelper.shared.opponentSeed = nil
            }
            self.connectionAlertView.showError("Connection Lost", subTitle: "Opponent has left the game!")
        }
    }
}

