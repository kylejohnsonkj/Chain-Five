//
//  GameVCViews.swift
//  Chain Five
//
//  Created by Kyle Johnson on 1/11/18.
//  Copyright © 2018 Kyle Johnson. All rights reserved.
//

import UIKit

/// Since I'm not using storyboards, this class holds all the views needed for the Game VC.
class GameVCViews {
    
    let l = Layout()
    var view: UIView
    
    // title and views
    var gameTitle: UIImageView
    
    var playerIndicator: UIImageView
    var playerTurnLabel: UILabel
    var deck: UIImageView
    var deckOutline: UIView
    var cardsLeftLabel: UILabel
    var menuIcon: UIImageView
    var helpIcon: UIImageView
    var messageIcon: UIImageView
    
    // board
    var bottomBorder: UIView
    var jackOutline: UIView
    
    init(view: UIView) {
        self.view = view
        
        // title
        gameTitle = UIImageView(image: UIImage(named: "title"))
        gameTitle.frame = CGRect(x: view.bounds.midX - (l.titleWidth / 2), y: l.topMargin - l.cardSize - l.titleHeight, width: l.titleWidth, height: l.titleHeight)
        gameTitle.contentMode = .scaleAspectFit
        view.addSubview(gameTitle)
        
        // player details
        playerIndicator = UIImageView(image: UIImage(named: "orange"))
        playerIndicator.frame = CGRect(x: -l.cardSize - l.itemWidth * 2, y: l.btmMargin + (2 * l.cardSize * 1.23) + l.cardSize * 0.05, width: l.cardSize * 0.9, height: l.cardSize * 0.9)
        view.addSubview(playerIndicator)
        
        playerTurnLabel = UILabel()
        playerTurnLabel.text = "Choosing host..."  // placeholder
        playerTurnLabel.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        playerTurnLabel.frame = CGRect(x: -l.itemWidth * 2, y: l.btmMargin + (2 * l.cardSize * 1.23) - l.cardSize * 0.01, width: l.itemWidth * 2, height: l.cardSize)
        playerTurnLabel.textAlignment = .left
        view.addSubview(playerTurnLabel)
        
        // deck and related
        deck = Card(named: "-deck")
        deck.frame = CGRect(x: view.frame.maxX + l.cardSize * 1.25, y: l.btmMargin + l.cardSize * 2 + l.cardSize * 0.23, width: l.cardSize, height: l.cardSize * 1.4)
        view.addSubview(deck)
        
        deckOutline = UIView()
        deckOutline.frame = CGRect(x: l.leftMargin + l.cardSize * 8 - l.highlight, y: l.btmMargin + l.cardSize * 2 + l.cardSize * 0.23 - l.highlight, width: l.cardSize + (2 * l.highlight), height: l.cardSize * 1.4 + (l.highlight * 2))
        deckOutline.layer.borderColor = UIColor.green.cgColor
        deckOutline.layer.borderWidth = 0
        view.addSubview(deckOutline)
        
        cardsLeftLabel = UILabel()
        cardsLeftLabel.text = "99"  // placeholder
        cardsLeftLabel.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        cardsLeftLabel.frame = CGRect(x: l.leftMargin + l.cardSize * 9.25, y: l.btmMargin + (2 * l.cardSize * 1.23) - l.cardSize * 0.01, width: l.itemWidth, height: l.cardSize)
        cardsLeftLabel.textAlignment = .left
        cardsLeftLabel.alpha = 0
        view.addSubview(cardsLeftLabel)
        
        // icons
        menuIcon = UIImageView(image: UIImage(named: "menu"))
        menuIcon.frame = CGRect(x: -l.cardSize, y: l.topMargin - l.cardSize * 1.9, width: l.cardSize, height: l.cardSize)
        view.addSubview(menuIcon)
        
        helpIcon = UIImageView(image: UIImage(named: "help"))
        helpIcon.frame = CGRect(x: view.frame.maxX, y: l.topMargin - l.cardSize * 1.9, width: l.cardSize, height: l.cardSize)
        view.addSubview(helpIcon)
        
        // multiplayer only
        messageIcon = UIImageView(image: UIImage(named: "message"))
        messageIcon.frame = CGRect(x: view.frame.maxX, y: l.btmMargin + (2 * l.cardSize * 1.23) + l.cardSize * 0.05, width: l.cardSize * 0.9, height: l.cardSize * 0.9)
        view.addSubview(messageIcon)
        
        // for board
        // adds black line below bottom row of cards
        bottomBorder = UIView()
        bottomBorder.frame = CGRect(x: l.leftMargin, y: l.btmMargin, width: l.cardSize * 10, height: l.stroke)
        bottomBorder.layer.backgroundColor = UIColor.black.cgColor
        view.addSubview(bottomBorder)
        
        // used for jack highlighting
        jackOutline = UIView()
        jackOutline.frame = CGRect(x: l.leftMargin - l.highlight, y: l.topMargin - l.highlight, width: (l.cardSize * 10) + (2 * l.highlight), height: (l.cardSize * 10) + (l.highlight * 2) + l.stroke)
        jackOutline.layer.borderColor = UIColor.green.cgColor
        jackOutline.layer.borderWidth = 0
        view.addSubview(jackOutline)
    }
    
    func getGameTitle() -> UIImageView {
        return gameTitle
    }
    
    func getPlayerDetails() -> (UIImageView, UILabel) {
        return (playerIndicator, playerTurnLabel)
    }
    
    func getDeckAndRelated() -> (UIImageView, UIView, UILabel) {
        return (deck, deckOutline, cardsLeftLabel)
    }
    
    func getMenuAndHelpIcons() -> (UIImageView, UIImageView) {
        return (menuIcon, helpIcon)
    }
    
    func getMessageIcon() -> UIImageView {
        return messageIcon
    }
    
    func getBottomBorder() -> UIView {
        return bottomBorder
    }
    
    func getJackOutline() -> UIView {
        return jackOutline
    }
}

