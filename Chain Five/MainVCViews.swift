//
//  MainVCViews.swift
//  Chain Five
//
//  Created by Kyle Johnson on 1/9/18.
//  Copyright © 2018 Kyle Johnson. All rights reserved.
//

import UIKit

/// This class holds all the views needed for the Main Menu.
class MainVCViews {

    let l = Layout.shared
    var view: UIView
    
    // main views
    var gameTitle: UIImageView
    var container: UIView
    
    // container subviews
    var leftImage: UIImageView
    var leftText: UILabel
    var rightImage: UIImageView
    var rightText: UILabel
    var divider: UIView
    var kjAppsText: UILabel
    
    // board related
    var bottomBorder: UIView
    
    init(view: UIView) {
        self.view = view
        
        // game title
        gameTitle = UIImageView(image: UIImage(named: "title"))
        gameTitle.frame = CGRect(x: view.frame.midX - l.titleWidth / 2, y: l.topMargin - l.distance - l.titleHeight, width: l.titleWidth, height: l.titleHeight)
        gameTitle.contentMode = .scaleAspectFit
        view.addSubview(gameTitle)
        
        // container for all items below
        container = UIView()
        container.frame = CGRect(x: view.frame.midX - l.cardSize * 5, y: l.btmMargin + l.distance, width: l.cardSize * 10, height: l.imgSize * 0.6 + l.cardSize * 0.6)
        view.addSubview(container)
        
        leftImage = UIImageView(image: UIImage(named: "main_left"))
        leftImage.frame = CGRect(x: container.bounds.midX - l.offset - l.itemWidth, y: 0, width: l.itemWidth, height: l.imgSize * 0.6)
        leftImage.contentMode = .scaleAspectFit
        container.addSubview(leftImage)
        
        leftText = UILabel()
        leftText.text = "Same Device"
        leftText.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        leftText.frame = CGRect(x: container.bounds.midX - l.offset - l.itemWidth, y: leftImage.frame.height + l.textPadding, width: l.itemWidth, height: l.cardSize * 0.6)
        leftText.textAlignment = .center
        container.addSubview(leftText)
        
        rightImage = UIImageView(image: UIImage(named: "main_right"))
        rightImage.frame = CGRect(x: container.bounds.midX + l.offset, y: 0, width: l.itemWidth, height: l.imgSize * 0.6)
        rightImage.contentMode = .scaleAspectFit
        container.addSubview(rightImage)
        
        rightText = UILabel()
        rightText.text = "Online Match"
        rightText.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        rightText.frame = CGRect(x: container.bounds.midX + l.offset, y: leftImage.frame.height + l.textPadding, width: l.itemWidth, height: l.cardSize * 0.6)
        rightText.textAlignment = .center
        container.addSubview(rightText)
        
        divider = UIView()
        divider.frame = CGRect(x: container.bounds.midX - l.stroke, y: -l.cardSize * 0.1, width: l.stroke * 2, height: l.imgSize * 0.6 + l.textPadding + l.cardSize * 0.7)
        divider.backgroundColor = .black
        container.addSubview(divider)
        
        kjAppsText = UILabel()
        kjAppsText.text = "© Kyle Johnson Apps"
        kjAppsText.font = UIFont(name: "GillSans", size: l.cardSize / 3)
        kjAppsText.frame = CGRect(x: container.bounds.midX - l.itemWidth / 2, y: l.imgSize * 0.6 + l.textPadding + l.cardSize * 0.7 + l.distance * 0.7, width: l.itemWidth, height: l.cardSize * 0.4)
        kjAppsText.textAlignment = .center
        container.addSubview(kjAppsText)
        
        // adds black line below bottom row of cards
        bottomBorder = UIView()
        bottomBorder.frame = CGRect(x: l.leftMargin, y: l.btmMargin, width: l.cardSize * 10, height: l.stroke)
        bottomBorder.backgroundColor = .black
        view.addSubview(bottomBorder)
        bottomBorder.alpha = 0
    }
    
    func getGameTitle() -> UIImageView {
        return gameTitle
    }
    
    func getContainer() -> UIView {
        return container
    }
    
    // tuples FTW!
    func getContainerSubviews() -> (UIImageView, UILabel, UIImageView, UILabel, UIView, UILabel) {
        return (leftImage, leftText, rightImage, rightText, divider, kjAppsText)
    }
    
    func getBottomBorder() -> UIView {
        return bottomBorder
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

