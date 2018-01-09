//
//  MainViewController.swift
//  Chain Five
//
//  Created by Kyle Johnson on 11/29/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit
import AudioToolbox
import StoreKit
import GameKit
import UserNotifications

extension MainViewController: GCHelperDelegate {
    func matchStarted() {
        print("matchStarted (MVC)")
        prepareMPCGame = true
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
            self.container.frame.origin.y += 200
            self.container.alpha = 0
            
        }, completion: { _ in
            self.performSegue(withIdentifier: "toGame", sender: self)
        })
    }
    
    func match(_ theMatch: GKMatch, didReceiveData data: Data, fromPlayer playerID: String) {
        print("match:\(theMatch) didReceiveData: fromPlayer:\(playerID) (MVC) -- should never occur")
    }
    
    func matchEnded() {
        print("matchEnded (MVC) -- should never occur")
    }
}

class MainViewController: UIViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toGame" && prepareMPCGame == true {
            let gameViewController = (segue.destination as! GameViewController)
            GCHelper.sharedInstance.delegate = gameViewController
            gameViewController.isMPCGame = true
        }
    }
    
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
    
    // main elements
    var gameTitle: UIImageView!
    var bottomBorder: UIView!
    var container: UIView!
    
    // everything within bottom container
    var leftImage: UIImageView!
    var leftText: UILabel!
    var rightImage: UIImageView!
    var rightText: UILabel!
    var divider: UIView!
    var kjAppsText: UILabel!
    
    // for MultipeerConnectivity purposes
    var appDelegate: AppDelegate!
    var prepareMPCGame = false
    var l: Layout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        l = Layout()
        
        // reset MPC related stuff
//        resetMPC()
        prepareMPCGame = false
        
        // check if we should request a review
//        if UserDefaults.standard.integer(forKey: "gamesFinished") % 10 == 0 {
//            SKStoreReviewController.requestReview()
//            incrementGamesFinished()
//        }
        
        // setup views
        generateBoard()
        generateTitleAndButtons()
        
        // animate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [unowned self] in
            self.animateViews()
        }
    }
    
    func incrementGamesFinished() {
        let currentCount = UserDefaults.standard.integer(forKey: "gamesFinished")
        UserDefaults.standard.set(currentCount + 1, forKey:"gamesFinished")
        UserDefaults.standard.synchronize()
    }
    
    func generateBoard() {
        
        // adds black line below bottom row of cards
        bottomBorder = UIView()
        bottomBorder.frame = CGRect(x: l.leftMargin, y: l.btmMargin, width: l.cardSize * 10, height: l.stroke)
        bottomBorder.layer.backgroundColor = UIColor.black.cgColor
        view.addSubview(bottomBorder)
        bottomBorder.alpha = 0

        // load the 100 cards
        var i = 0
        while i < 100 {
            let card = Card(named: self.cardsLayout[i])
            card.frame = CGRect(x: view.frame.midX - l.cardSize / 2, y: l.centerY - l.cardSize / 2, width: l.cardSize, height: l.cardSize)
            self.view.addSubview(card)
            self.cardsOnBoard.append(card)
            i += 1
        }
    }
    
    func generateTitleAndButtons() {
        
        // Game Title
        gameTitle = UIImageView(image: UIImage(named: "title"))
        gameTitle.frame = CGRect(x: view.bounds.midX - (l.titleWidth / 2), y: l.topMargin - l.cardSize - l.titleHeight, width: l.titleWidth, height: l.titleHeight)
        gameTitle.contentMode = .scaleAspectFit
//        gameTitle.layer.borderWidth = 1
        view.addSubview(gameTitle)
        
        // Container for buttons and text
        container = UIView()
        container.frame = CGRect(x: view.bounds.midX - (l.cardSize * 5), y: l.btmMargin + l.cardSize, width: l.cardSize * 10, height: l.imgSize + l.textPadding - 9)
//        container.layer.borderWidth = 1
        view.addSubview(container)
        
        // prepare title and container animations
        self.gameTitle.frame.origin.y -= 200
        self.gameTitle.alpha = 0
        self.container.frame.origin.y += 200
        self.container.alpha = 0
        
        // Left Image (Pass N' Play)
        leftImage = UIImageView(image: UIImage(named: "left"))
        leftImage.frame = CGRect(x: container.bounds.midX - l.offset - l.itemWidth, y: container.bounds.minY, width: l.itemWidth, height: l.imgSize * 0.6)
        leftImage.contentMode = .scaleAspectFit
//        leftImage.layer.borderWidth = 1
        container.addSubview(leftImage)
        
        // Pass N' Play text
        leftText = UILabel()
        leftText.text = "Same Device"
        leftText.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        leftText.frame = CGRect(x: container.bounds.midX - l.offset - l.itemWidth, y: container.bounds.minY + l.textPadding + leftImage.frame.height, width: l.itemWidth, height: 30)
        leftText.textAlignment = .center
//        leftText.layer.borderWidth = 1
        container.addSubview(leftText)
        
        // Right Image (Local Match)
        rightImage = UIImageView(image: UIImage(named: "right"))
        rightImage.frame = CGRect(x: container.bounds.midX + l.offset, y: container.bounds.minY, width: l.itemWidth, height: l.imgSize * 0.6)
        rightImage.contentMode = .scaleAspectFit
//        rightImage.layer.borderWidth = 1
        container.addSubview(rightImage)

        // Local Match text
        rightText = UILabel()
        rightText.text = "Online Match"
        rightText.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        rightText.frame = CGRect(x: container.bounds.midX + l.offset, y: container.bounds.minY + l.textPadding + leftImage.frame.height, width: l.itemWidth, height: 30)
        rightText.textAlignment = .center
//        rightText.layer.borderWidth = 1
        container.addSubview(rightText)
        
        divider = UIView()
        divider.frame = CGRect(x: container.bounds.midX - l.stroke, y: container.bounds.minY - l.cardSize / 10, width: 2 * l.stroke, height: leftText.frame.maxY - container.bounds.minY + l.textPadding)
        divider.backgroundColor = .black
        container.addSubview(divider)
        
        
        kjAppsText = UILabel()
        kjAppsText.text = "© Kyle Johnson Apps"
        kjAppsText.font = UIFont(name: "GillSans", size: l.cardSize / 3)
        kjAppsText.frame = CGRect(x: container.bounds.midX - l.itemWidth / 2, y: leftText.frame.maxY - container.bounds.minY + l.textPadding + l.cardSize / 2, width: l.itemWidth, height: 30)
        kjAppsText.textAlignment = .center
        container.addSubview(kjAppsText)
    }
    
    func animateViews() {
        
        // animate cards into center of screen
        var i = 0
        UIView.animate(withDuration: 1, animations: {
            for row in 0...9 {
                for col in 0...9 {
                    self.cardsOnBoard[i].frame = CGRect(x: self.l.leftMargin + (CGFloat(col) * (self.l.cardSize)), y: self.l.topMargin + (CGFloat(row) * self.l.cardSize), width: self.l.cardSize, height: self.l.cardSize)
                    i += 1
                }
            }
            
        }, completion: { _ in
            // show bottom border when finished
            self.bottomBorder.alpha = 1
        })
        
        // animate title down
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
            self.gameTitle.frame.origin.y += 200
            self.gameTitle.alpha = 1
        })
        
        // animate buttons up
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
            self.container.frame.origin.y -= 200
            self.container.alpha = 1
        })
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self.container)
            
            if leftImage.frame.contains(touchLocation) || leftText.frame.contains(touchLocation) {
                AudioServicesPlaySystemSound(Taptics.pop.rawValue)
                
                leftImage.alpha = 0.5
                leftText.alpha = 0.5
                
                UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                    self.container.frame.origin.y += 200
                    self.container.alpha = 0
                    
                }, completion: { _ in
                    self.performSegue(withIdentifier: "toGame", sender: self)
                })
            }
            
            if rightImage.frame.contains(touchLocation) || rightText.frame.contains(touchLocation) {
                AudioServicesPlaySystemSound(Taptics.pop.rawValue)
                
                rightImage.alpha = 0.5
                rightText.alpha = 0.5
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [unowned self] in
                    self.rightImage.alpha = 1
                    self.rightText.alpha = 1
                }
                
                GCHelper.sharedInstance.findMatchWithMinPlayers(2, maxPlayers: 2, viewController: self, delegate: self)
            }
            
            // link copyright text to homepage
            if kjAppsText.frame.contains(touchLocation) {
                let url = URL(string: "http://kylejohnsonapps.com")
                UIApplication.shared.open(url!, options: [:])
            }
        }
    }
}

