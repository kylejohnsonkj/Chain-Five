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

class MainViewController: UIViewController {
    
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
    
    var l = Layout()
    var views: MainVCViews!

    // main UI views
    var cardsOnBoard = [Card]()    // 10x10 grid -- 100 cards total
    var bottomBorder = UIView()
    var gameTitle = UIImageView()
    var container = UIView()
    
    // everything within bottom container
    var leftImage = UIImageView()
    var leftText = UILabel()
    var rightImage = UIImageView()
    var rightText = UILabel()
    var divider = UIView()
    var kjAppsText = UILabel()
    
    // tell Game VC if multiplayer or not
    var prepareMultiplayer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        views = MainVCViews(view: self.view)
        
        generateTitleAndViews()
        generateBoard()
        
        // check if we should request a review
//        if UserDefaults.standard.integer(forKey: "gamesFinished") % 10 == 0 {
//            SKStoreReviewController.requestReview()
//            incrementGamesFinished()
//        }
    }

    override func viewWillAppear(_ animated: Bool) {
        animateViews()
    }
    
    func generateTitleAndViews() {

        gameTitle = views.getGameTitle()
        container = views.getContainer()
        
        (leftImage, leftText, rightImage, rightText, divider, kjAppsText) = views.getContainerSubviews()

        // prepare title and container animations
        self.gameTitle.frame.origin.y -= 200
        self.gameTitle.alpha = 0
        self.container.frame.origin.y += 200
        self.container.alpha = 0
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
            // reveal bottom border when finished
            self.bottomBorder.alpha = 1
        })
        
        // animate title down
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
            self.gameTitle.frame.origin.y += 200
            self.gameTitle.alpha = 1
        })
        
        // animate container up
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
            self.container.frame.origin.y -= 200
            self.container.alpha = 1
        })
    }
    
    func generateBoard() {
        
        bottomBorder = views.getBottomBorder()
        
        // load the 100 cards initially into the center
        var i = 0
        while i < 100 {
            let card = Card(named: self.cardsLayout[i])
            card.frame = CGRect(x: view.frame.midX - l.cardSize / 2, y: l.centerY - l.cardSize / 2, width: l.cardSize, height: l.cardSize)
            self.view.addSubview(card)
            self.cardsOnBoard.append(card)
            i += 1
        }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toGame" && prepareMultiplayer == true {
            let gameVC = (segue.destination as! GameViewController)
            GCHelper.sharedInstance.delegate = gameVC
            gameVC.isMultiplayer = true
        }
    }
    
    //    func incrementGamesFinished() {
    //        let currentCount = UserDefaults.standard.integer(forKey: "gamesFinished")
    //        UserDefaults.standard.set(currentCount + 1, forKey:"gamesFinished")
    //        UserDefaults.standard.synchronize()
    //    }
}

extension MainViewController: GCHelperDelegate {
    
    func matchStarted() {
        print("matchStarted (MAIN)")
        prepareMultiplayer = true
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
            self.container.frame.origin.y += 200
            self.container.alpha = 0
        }, completion: { _ in
            self.performSegue(withIdentifier: "toGame", sender: self)
        })
    }
    
    func match(_ theMatch: GKMatch, didReceiveData data: Data, fromPlayer playerID: String) {
        print("match:\(theMatch) didReceiveData: fromPlayer:\(playerID) (MAIN -- should never occur)")
    }
    
    func matchEnded() {
        print("matchEnded (MAIN -- should never occur)")
    }
}

