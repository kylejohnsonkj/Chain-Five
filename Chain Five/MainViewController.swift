//
//  MainViewController.swift
//  Chain Five
//
//  Created by Kyle Johnson on 11/29/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit
import AudioToolbox
import MultipeerConnectivity
import StoreKit

class MainViewController: UIViewController, MCBrowserViewControllerDelegate {
    
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
    
    enum Taptics: SystemSoundID {
        case peek = 1519, pop = 1520, nope = 1521
    }
    
    // 10x10 grid -- 100 cards total (ignoring jacks)
    var cardsOnBoard = [Card]()
    var cardSize: CGFloat!
    var scale: CGFloat!
    var iPad = false
    
    var gameTitle: UIImageView!
    var bottomBorder: UIView!
    var leftImage: UIImageView!
    var leftText: UILabel!
    var rightImage: UIImageView!
    var rightText: UILabel!
    var divider: UIView!
    var kjappsLabel: UILabel!
    var container: UIView!
    
    // for MultipeerConnectivity purposes
    var appDelegate: AppDelegate!
    var prepareMPCGame = false
    var isHost = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if view.bounds.width > 414 {
            // iPad, adapt for different aspect ratio
            cardSize = view.bounds.width / 14
            scale = 3
            iPad = true
        } else {
            cardSize = view.bounds.width / 11
            scale = 2
            iPad = false
        }
        generateBoard()
        
        prepareMPCGame = false
        isHost = false
        
        // reset all session junk
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mpcHandler.peerID = nil
        appDelegate.mpcHandler.session = nil
        appDelegate.mpcHandler.browser = nil
        appDelegate.mpcHandler.advertiser = nil
        
        // show device to others looking for local opponents
        appDelegate.mpcHandler.setupPeerWithDisplayName(displayName: UIDevice.current.name)
        appDelegate.mpcHandler.setupSession()
        appDelegate.mpcHandler.advertiseSelf(advertise: true)
        
        // monitor for state changes (.notConnected -> .connecting -> .connected)
        NotificationCenter.default.addObserver(self, selector: #selector(peerChangedStateWithNotification(notification:)), name: .didChangeState, object: nil)
    }
    
    @objc func peerChangedStateWithNotification(notification: Notification) {
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        appDelegate.mpcHandler.state = userInfo.object(forKey: "state") as? Int
        
        // if connected to other player, prepare and send into game
        if appDelegate.mpcHandler.state == 2 {
            prepareMPCGame = true
            if appDelegate.mpcHandler.browser != nil {
                isHost = true
                appDelegate.mpcHandler.browser.dismiss(animated: true)
            }
            
            if isHost == false {
                // delay so both devices are on same timing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [unowned self] in
                    self.performSegue(withIdentifier: "toGame", sender: self)
                }
            } else {
                self.performSegue(withIdentifier: "toGame", sender: self)
            }
        }
    }
    
    func generateBoard() {
        
        let topMargin = self.view.bounds.height / 2 - (self.cardSize * 5) - cardSize / 2
        // y = topmargin - view.bounds.width / 12 - cardSize / 4
        // extra = height - cardSize * 10
        gameTitle = UIImageView(image: UIImage(named: "title"))
        gameTitle.frame = CGRect(x: view.bounds.midX - view.bounds.width / (scale * 2), y: topMargin - view.bounds.width / (scale * 3) - view.bounds.height / 20, width: view.bounds.width / scale, height: view.bounds.width / (scale * 3))
        gameTitle.contentMode = .scaleAspectFit
        view.addSubview(gameTitle)

        let leftMargin = self.view.bounds.width / 2 - (self.cardSize * 5)
        // adds black line below bottom row of cards
        bottomBorder = UIView()
        bottomBorder.frame = CGRect(x: leftMargin, y: topMargin + (cardSize * 10), width: cardSize * 10, height: 1)
        bottomBorder.layer.borderColor = UIColor.black.cgColor
        bottomBorder.layer.borderWidth = 1
        view.addSubview(bottomBorder)
        bottomBorder.alpha = 0
        bottomBorder.layer.zPosition = 3
        
        let btmMargin = self.view.bounds.height / 2 + (self.cardSize * 5) - cardSize / 2
        
        container = UIView()
        container.frame = CGRect(x: view.bounds.midX - (view.bounds.width * 0.4), y: btmMargin + view.bounds.width / (scale * 4), width: view.bounds.width * 0.8, height: view.bounds.width / (scale * 2.2))
        view.addSubview(container)
        
        let space: CGFloat = iPad ? 5 : 4
        let padding: CGFloat = iPad ? 5 : 0
        
        let size: CGFloat = 30
        leftImage = UIImageView(image: UIImage(named: "cards"))
        leftImage.frame = CGRect(x: container.bounds.midX - container.bounds.width / space - (size * scale) / 2, y: container.bounds.minY, width: size * scale, height: (size * scale) * 0.6)
        leftImage.contentMode = .scaleAspectFit
        container.addSubview(leftImage)
        
        rightImage = UIImageView(image: UIImage(named: "globe"))
        rightImage.frame = CGRect(x: container.bounds.midX + container.bounds.width / space - (size * scale) / 2, y: container.bounds.minY, width: size * scale, height: (size * scale) * 0.6)
        rightImage.contentMode = .scaleAspectFit
        container.addSubview(rightImage)
        
        leftText = UILabel()
        leftText.text = "Pass 'N Play"
        leftText.font = UIFont(name: "Optima-Regular", size: 17 * (scale / 2))
        leftText.frame = CGRect(x: container.bounds.midX - container.bounds.width / (space / 2), y: container.bounds.minY + leftImage.frame.height + padding, width: container.bounds.width / (space / 2), height: 30)
        leftText.textAlignment = .center
        container.addSubview(leftText)
        
        rightText = UILabel()
        rightText.text = "Local Match"
        rightText.font = UIFont(name: "Optima-Regular", size: 17 * (scale / 2))
        rightText.frame = CGRect(x: container.bounds.midX, y: container.bounds.minY + leftImage.frame.height + padding, width: container.bounds.width / (space / 2), height: 30)
        rightText.textAlignment = .center
        container.addSubview(rightText)
        
        divider = UIView()
        divider.frame = CGRect(x: container.bounds.midX, y: -leftText.bounds.height / 4, width: 1 * ceil(scale / 2), height: leftImage.bounds.height + leftText.bounds.height * 1.25 + padding * 2)
        divider.layer.borderColor = UIColor.black.cgColor
        divider.layer.borderWidth = 1
        container.addSubview(divider)
        
        kjappsLabel = UILabel()
        kjappsLabel.text = "Kyle Johnson Apps"
        kjappsLabel.font = UIFont(name: "Optima-Regular", size: 13 * (scale / 2))
        kjappsLabel.frame = CGRect(x: container.bounds.midX - container.bounds.width / (2 * (space / 2)), y: container.bounds.maxY + padding * 2, width: container.bounds.width / (space / 2), height: 30)
        kjappsLabel.textAlignment = .center
        container.addSubview(kjappsLabel)
        
//        bottomBorder = UIView()
        
//        leftImage.frame.origin.x -= 175
//        leftText.frame.origin.x -= 175
//        rightImage.frame.origin.x += 175
//        rightText.frame.origin.x += 175
//        divider.alpha = 0
//        gameTitle.frame.origin.y -= 200
//        kjappsLabel.frame.origin.y += 20
        
        // load the 100 cards
        var i = 0
        while i < 100 {
            let card = Card(named: self.cardsLayout[i])
            card.frame = CGRect(x: view.frame.midX - (cardSize / 2), y: view.frame.midY - (cardSize / 2), width: cardSize, height: cardSize)
            self.view.addSubview(card)
            self.cardsOnBoard.append(card)
            i += 1
        }

        // animate cards into center of screen
        i = 0
        UIView.animate(withDuration: 1, animations: {
            let leftMargin = self.view.bounds.width / 2 - (self.cardSize * 5) - self.cardSize
            let topMargin = self.view.bounds.height / 2 - (self.cardSize * 5) - self.cardSize * 1.5
            for row in 1...10 {
                for col in 1...10 {
                    self.cardsOnBoard[i].frame = CGRect(x: leftMargin + (CGFloat(col) * self.cardSize), y: topMargin + (CGFloat(row) * self.cardSize), width: self.cardSize, height: self.cardSize)
                    i += 1
                }
            }
            
        }, completion: { _ in
            self.bottomBorder.alpha = 1
        })

        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
//            self.leftImage.frame.origin.x += 175
//            self.leftText.frame.origin.x += 175
//            self.rightImage.frame.origin.x -= 175
//            self.rightText.frame.origin.x -= 175
//            self.kjappsLabel.frame.origin.y -= 20
//            self.gameTitle.frame.origin.y += 200
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, animations: {
//                self.divider.alpha = 1
            })
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        let container = UIView()
//        container.frame = view.frame
//        view.addSubview(container)
//        container.addSubview(leftImage)
//        container.addSubview(leftText)
//        container.addSubview(rightImage)
//        container.addSubview(rightText)
//        container.addSubview(divider)
//        container.addSubview(kjappsLabel)
//        container.frame.origin.y += 200
        
//        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
//            container.frame.origin.y -= 200
//        })
        
        // ios 10.3 and later
        if UserDefaults.standard.integer(forKey: "gamesFinished") == 5 {
            SKStoreReviewController.requestReview()
            // increment immediately so request is not sent again
            let currentCount = UserDefaults.standard.integer(forKey: "gamesFinished")
            UserDefaults.standard.set(currentCount+1, forKey:"gamesFinished")
            UserDefaults.standard.synchronize()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self.container)
            
            if leftImage.frame.contains(touchLocation) || leftText.frame.contains(touchLocation) {
                
                AudioServicesPlaySystemSound(Taptics.pop.rawValue)
                
                let other = UIView()
                other.frame = self.container.frame
                view.addSubview(other)
                
                other.addSubview(rightImage)
                other.addSubview(rightText)
                other.addSubview(divider)
                other.addSubview(kjappsLabel)
                
                UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                    let left = UIView()
                    left.frame = self.container.frame
                    self.view.addSubview(left)
                    left.addSubview(self.leftImage)
                    left.addSubview(self.leftText)
                    left.frame.origin.y += 200
                })
                    
                UIView.animate(withDuration: 0.5, delay: 0.1, options: [], animations: {
                    other.frame.origin.y += 200
                }, completion: { _ in
                    self.performSegue(withIdentifier: "toGame", sender: self)
                })
            }
            
            if rightImage.frame.contains(touchLocation) || rightText.frame.contains(touchLocation) {
                
                AudioServicesPlaySystemSound(Taptics.pop.rawValue)
                
                if appDelegate.mpcHandler.session != nil {
                    appDelegate.mpcHandler.setupBrowser()
                    appDelegate.mpcHandler.browser.delegate = self
                    present(appDelegate.mpcHandler.browser, animated: true)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toGame" && prepareMPCGame == true {
            let gameViewController = (segue.destination as! GameViewController)
            gameViewController.isMPCGame = true
            if isHost {
                gameViewController.isHost = true
            }
        }
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        appDelegate.mpcHandler.browser.dismiss(animated: true)
        appDelegate.mpcHandler.browser = nil
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
    }
}

