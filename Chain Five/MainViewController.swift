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
    var cardSize: CGFloat!
    var iPad = false
    
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
    var kjappsLabel: UILabel!
    
    // for MultipeerConnectivity purposes
    var appDelegate: AppDelegate!
    var prepareMPCGame = false
    var isHost = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetMPC()
        prepareMPCGame = false
        isHost = false
        calculateScale()
        
        generateBoard()
        generateTitleAndButtons()
        animateViews()
    }
    
    func resetMPC() {
        
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
    
    func calculateScale() {
        if view.bounds.width > 414 {
            // it's an iPad, adapt for different aspect ratio
            cardSize = view.bounds.width / 14
            iPad = true
        } else {
            cardSize = view.bounds.width / 10.7
            iPad = false
        }
    }
    
    func generateBoard() {
        
        let leftMargin = view.frame.midX - (self.cardSize * 5)
        let topMargin = view.frame.midY - (self.cardSize * 5) - cardSize / 2
        
        // adds black line below bottom row of cards
        bottomBorder = UIView()
        bottomBorder.frame = CGRect(x: leftMargin, y: topMargin + (cardSize * 10), width: cardSize * 10, height: 1)
        bottomBorder.layer.backgroundColor = UIColor.black.cgColor
        view.addSubview(bottomBorder)
        bottomBorder.alpha = 0

        // load the 100 cards
        var i = 0
        while i < 100 {
            let card = Card(named: self.cardsLayout[i])
            card.frame = CGRect(x: view.frame.midX - (cardSize / 2), y: view.frame.midY - cardSize, width: cardSize, height: cardSize)
            self.view.addSubview(card)
            self.cardsOnBoard.append(card)
            i += 1
        }

        // animate cards into center of screen
        i = 0
        UIView.animate(withDuration: 1, animations: {
            for row in 0...9 {
                for col in 0...9 {
                    self.cardsOnBoard[i].frame = CGRect(x: leftMargin + (CGFloat(col) * self.cardSize), y: topMargin + (CGFloat(row) * self.cardSize), width: self.cardSize, height: self.cardSize)
                    i += 1
                }
            }
            
        }, completion: { _ in
            self.bottomBorder.alpha = 1
        })
        
    }
    
    func generateTitleAndButtons() {
        
        // margins
        let topMargin = view.frame.midY - (self.cardSize * 5) - cardSize / 2
        let btmMargin = view.frame.midY + (self.cardSize * 5) - cardSize / 2
        
        // sizing variables
        let scale: CGFloat = iPad ? 3 : 2
        var spacing: CGFloat = iPad ? 5 : 4
        if view.frame.maxX < 375 {
            // iPhone 5/5s only
            spacing = 3.5
        }
        let titleWidth = view.bounds.width / scale
        let titleHeight = titleWidth / 3
        let padding: CGFloat = iPad ? 5 : 0
        let imgSize: CGFloat = cardSize * 1.75
        
        // --------------------------------------------------------------------- //
        
        // Game Title
        gameTitle = UIImageView(image: UIImage(named: "title"))
        gameTitle.frame = CGRect(x: view.bounds.midX - (titleWidth / 2), y: topMargin - titleHeight - cardSize / 1.25, width: titleWidth, height: titleHeight)
        gameTitle.contentMode = .scaleAspectFit
        view.addSubview(gameTitle)
        
        container = UIView()
        container.frame = CGRect(x: view.bounds.midX - (view.bounds.width * 0.4), y: btmMargin + cardSize * 1.25, width: view.bounds.width * 0.8, height: imgSize)
        view.addSubview(container)
        
        // container dependent variables
        let spaceBetween = container.bounds.width / spacing
        let textWidth = container.bounds.width / (spacing / 2)
        
        // Pass 'N Play (LEFT BUTTON)
        leftImage = UIImageView(image: UIImage(named: "cards"))
        leftImage.frame = CGRect(x: container.bounds.midX + 2 - spaceBetween - imgSize / 2, y: container.bounds.minY, width: imgSize, height: imgSize * 0.6)
        leftImage.contentMode = .scaleAspectFit
        container.addSubview(leftImage)
        
        leftText = UILabel()
        leftText.text = "Pass 'N Play"
        leftText.font = UIFont(name: "Optima-Regular", size: cardSize / 2)
        leftText.frame = CGRect(x: container.bounds.midX + 2 - textWidth, y: container.bounds.minY + leftImage.frame.height + padding, width: textWidth, height: 30)
        leftText.textAlignment = .center
        container.addSubview(leftText)
        
        // Divider between buttons
        divider = UIView()
        divider.frame = CGRect(x: container.bounds.midX - (1 * ceil(scale / 2)), y: -cardSize / 4 - 3, width: 1 * ceil(scale / 2), height: container.frame.height + cardSize / 2)
        divider.layer.backgroundColor = UIColor.black.cgColor
        container.addSubview(divider)
        
        // Local Match (RIGHT BUTTON)
        rightImage = UIImageView(image: UIImage(named: "globe"))
        rightImage.frame = CGRect(x: container.bounds.midX + 2 + spaceBetween - imgSize / 2, y: container.bounds.minY, width: imgSize, height: imgSize * 0.6)
        rightImage.contentMode = .scaleAspectFit
        container.addSubview(rightImage)
        
        rightText = UILabel()
        rightText.text = "Local Match"
        rightText.font = UIFont(name: "Optima-Regular", size: cardSize / 2)
        rightText.frame = CGRect(x: container.bounds.midX + 2, y: container.bounds.minY + leftImage.frame.height + padding, width: textWidth, height: 30)
        rightText.textAlignment = .center
        container.addSubview(rightText)
        
        // Self-promotion
        kjappsLabel = UILabel()
        kjappsLabel.text = "Kyle Johnson Apps"
        kjappsLabel.font = UIFont(name: "Optima-Regular", size: cardSize / 3)
        kjappsLabel.frame = CGRect(x: container.bounds.midX - textWidth / 2, y: container.bounds.maxY + padding + cardSize / 1.5, width: textWidth, height: 30)
        kjappsLabel.textAlignment = .center
        container.addSubview(kjappsLabel)
    }
    
    func animateViews() {
        gameTitle.frame.origin.y -= 200
        gameTitle.alpha = 0
        container.frame.origin.y += 200
        container.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
            self.gameTitle.frame.origin.y += 200
            self.gameTitle.alpha = 1
            self.container.frame.origin.y -= 200
            self.container.alpha = 1
        })
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
    
    override func viewWillAppear(_ animated: Bool) {
        container.frame.origin.y += 200
        container.alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
            self.container.frame.origin.y -= 200
            self.container.alpha = 1
        })
        
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
                
                UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                    self.container.frame.origin.y += 200
                    self.container.alpha = 0
                    
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

