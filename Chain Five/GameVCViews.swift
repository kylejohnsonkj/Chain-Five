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
    
    let l = Layout.shared
    var view: UIView
    
    // title
    var gameTitle: UIImageView
    
    // views, labels, buttons
    var playerIndicator: UIImageView
    var playerTurnLabel: UILabel
    var deck: UIImageView
    var deckOutline: UIView
    var cardsLeftLabel: UILabel
    var menuIcon: DOFavoriteButton
    var helpIcon: DOFavoriteButton
    var messageIcon: DOFavoriteButton
    
    // board
    var bottomBorder: UIView
    var jackOutline: UIView
    
    init(view: UIView) {
        self.view = view
        
        // title
        gameTitle = UIImageView(image: UIImage(named: "title"))
        gameTitle.frame = CGRect(x: view.frame.midX - (l.titleWidth / 2), y: l.topMargin - l.distance - l.titleHeight, width: l.titleWidth, height: l.titleHeight)
        gameTitle.contentMode = .scaleAspectFit
        view.addSubview(gameTitle)
        
        // player details
        playerIndicator = UIImageView(image: UIImage(named: "orange"))
        playerIndicator.frame = CGRect(x: -l.cardSize - l.itemWidth * 2, y: l.btmMargin + l.distance + l.cardSize * 1.46 + l.cardSize * 0.05, width: l.cardSize * 0.9, height: l.cardSize * 0.9)
        view.addSubview(playerIndicator)
        
        playerTurnLabel = UILabel()
        playerTurnLabel.text = "Choosing host..."  // placeholder
        playerTurnLabel.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        playerTurnLabel.frame = CGRect(x: -l.itemWidth * 2, y: l.btmMargin + l.distance + l.cardSize * 1.46, width: l.cardSize * 5.6, height: l.cardSize)
        playerTurnLabel.textAlignment = .left
        view.addSubview(playerTurnLabel)
        
        // deck and related
        deck = Card(named: "-deck")
        deck.frame = CGRect(x: view.frame.maxX + l.cardSize * 1.25, y: l.btmMargin + l.distance + l.cardSize * 1.23, width: l.cardSize, height: l.cardSize * 1.4)
        view.addSubview(deck)
        
        deckOutline = UIView()
        deckOutline.frame = CGRect(x: l.leftMargin + l.cardSize * 8 - l.highlight, y: l.btmMargin + l.distance + l.cardSize * 1.23 - l.highlight, width: l.cardSize + (2 * l.highlight), height: l.cardSize * 1.4 + (l.highlight * 2))
        deckOutline.layer.borderColor = UIColor.green.cgColor
        deckOutline.layer.borderWidth = 0
        view.addSubview(deckOutline)
        
        cardsLeftLabel = UILabel()
        cardsLeftLabel.text = "99"  // placeholder
        cardsLeftLabel.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        cardsLeftLabel.frame = CGRect(x: l.leftMargin + l.cardSize * 9.25, y: l.btmMargin + l.distance + l.cardSize * 1.46, width: l.cardSize * 0.75, height: l.cardSize)
        cardsLeftLabel.textAlignment = .left
        cardsLeftLabel.alpha = 0
        view.addSubview(cardsLeftLabel)
        
        // snazzy buttons
        menuIcon = DOFavoriteButton(frame: CGRect(x: -l.cardSize * 2, y: l.topMargin - l.distance - l.titleHeight / 2.4 - l.cardSize, width: l.cardSize * 2, height: l.cardSize * 2), image: UIImage(named: "menu"))
        menuIcon.imageColorOff = UIColor.black
        menuIcon.imageColorOn = UIColor.cfRed
        menuIcon.circleColor = UIColor.white
        menuIcon.lineColor = UIColor.cfRed
        menuIcon.accessibilityIdentifier = "menu"
        view.addSubview(menuIcon)
        
        helpIcon = DOFavoriteButton(frame: CGRect(x: view.frame.maxX, y: l.topMargin - l.distance - l.titleHeight / 2.4 - l.cardSize, width: l.cardSize * 2, height: l.cardSize * 2), image: UIImage(named: "help"))
        helpIcon.imageColorOff = UIColor.black
        helpIcon.imageColorOn = UIColor.cfBlue
        helpIcon.circleColor = UIColor.white
        helpIcon.lineColor = UIColor.cfBlue
        helpIcon.accessibilityIdentifier = "help"
        view.addSubview(helpIcon)
        
        // multiplayer only
        messageIcon = DOFavoriteButton(frame: CGRect(x: l.leftMargin + l.cardSize * 6.9 - l.cardSize * 0.45, y: l.btmMargin + l.distance + l.cardSize * 1.46 + l.cardSize * 0.05 - l.cardSize * 0.45, width: l.cardSize * 1.8, height: l.cardSize * 1.8), image: UIImage(named: "message"))
        messageIcon.imageColorOff = UIColor.black
        messageIcon.imageColorOn = UIColor.cfGreen
        messageIcon.circleColor = UIColor.white
        messageIcon.lineColor = UIColor.cfGreen
        messageIcon.accessibilityIdentifier = "message"
        messageIcon.alpha = 0
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
    
    func getMenuAndHelpIcons() -> (DOFavoriteButton, DOFavoriteButton) {
        return (menuIcon, helpIcon)
    }
    
    func getMessageIcon() -> DOFavoriteButton {
        return messageIcon
    }
    
    func getBottomBorder() -> UIView {
        return bottomBorder
    }
    
    func getJackOutline() -> UIView {
        return jackOutline
    }
}

