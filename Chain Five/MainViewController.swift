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

class MainViewController: UIViewController, MCBrowserViewControllerDelegate {

    @IBOutlet weak var leftImage: UIImageView!
    @IBOutlet weak var leftText: UILabel!
    @IBOutlet weak var rightImage: UIImageView!
    @IBOutlet weak var rightText: UILabel!
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var gameTitle: UILabel!
    @IBOutlet weak var kjappsLabel: UILabel!
    
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
    
    // 10x10 grid -- 100 cards total (ignoring jacks)
    var cardsOnBoard = [Card]()
    
    // for MultipeerConnectivity purposes
    var appDelegate: AppDelegate!
    var prepareMPCGame = false
    var isHost = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        generateBoard()
        
        prepareMPCGame = false
        isHost = false
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.mpcHandler.peerID = nil
        appDelegate.mpcHandler.session = nil
        appDelegate.mpcHandler.browser = nil
        appDelegate.mpcHandler.advertiser = nil
        
        // for Multiplayer, show device to others
        appDelegate.mpcHandler.setupPeerWithDisplayName(displayName: UIDevice.current.name)
        appDelegate.mpcHandler.setupSession()
        appDelegate.mpcHandler.advertiseSelf(advertise: true)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(peerChangedStateWithNotification(notification:)), name: .didChangeState, object: nil)
    }
    
    @objc func peerChangedStateWithNotification(notification: Notification) {
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        appDelegate.mpcHandler.state = userInfo.object(forKey: "state") as? Int
        
        if appDelegate.mpcHandler.state == 2 {
            prepareMPCGame = true
            if appDelegate.mpcHandler.browser != nil {
                isHost = true
                appDelegate.mpcHandler.browser.dismiss(animated: true)
            }
            
            if isHost == false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [unowned self] in
                    self.performSegue(withIdentifier: "toGame", sender: self)
                }
            } else {
                self.performSegue(withIdentifier: "toGame", sender: self)
            }
        }
    }
    
    @objc func handleReceivedDataWithNotification(notification: Notification) {

    }
    
    func generateBoard() {

        // adds black line below bottom row of cards
        let bottomBorder = UIView()
        bottomBorder.frame = CGRect(x: 13, y: 485, width: 350, height: 1)
        bottomBorder.layer.borderColor = UIColor.black.cgColor
        bottomBorder.layer.borderWidth = 1
        view.addSubview(bottomBorder)
        bottomBorder.alpha = 0
        
        leftImage.frame.origin.x -= 175
        leftText.frame.origin.x -= 175
        rightImage.frame.origin.x += 175
        rightText.frame.origin.x += 175
        divider.alpha = 0
        gameTitle.frame.origin.y -= 200
        kjappsLabel.frame.origin.y += 20
        
        // load the 100 cards
        var i = 0
        while i < 100 {
            let card = Card(named: self.cardsLayout[i])
            card.frame = CGRect(x: view.frame.midX - (35 / 2), y: view.frame.midY - (35 / 2), width: 35, height: 35)
            self.view.addSubview(card)
            self.cardsOnBoard.append(card)
            i += 1
        }

        // animate cards into center of screen
        i = 0
        UIView.animate(withDuration: 1, animations: {
            for row in 1...10 {
                for col in 1...10 {
                    self.cardsOnBoard[i].frame = CGRect(x: (col * 35) - 22, y: (row * 35) + 100, width: 35, height: 35)
                    i += 1
                }
            }
            
        }, completion: { _ in
            bottomBorder.alpha = 1
        })

        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
            self.leftImage.frame.origin.x += 175
            self.leftText.frame.origin.x += 175
            self.rightImage.frame.origin.x -= 175
            self.rightText.frame.origin.x -= 175
            self.kjappsLabel.frame.origin.y -= 20
            self.gameTitle.frame.origin.y += 200
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, animations: {
                self.divider.alpha = 1
            })
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let container = UIView()
        container.frame = view.frame
        view.addSubview(container)
        container.addSubview(leftImage)
        container.addSubview(leftText)
        container.addSubview(rightImage)
        container.addSubview(rightText)
        container.addSubview(divider)
        container.addSubview(kjappsLabel)
        container.frame.origin.y += 200
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
            container.frame.origin.y -= 200
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self.view)
            
            if leftImage.frame.contains(touchLocation) || leftText.frame.contains(touchLocation) {
                
                AudioServicesPlaySystemSound(1520)
                
                let container = UIView()
                container.frame = view.frame
                view.addSubview(container)
                
                container.addSubview(rightImage)
                container.addSubview(rightText)
                container.addSubview(divider)
                container.addSubview(kjappsLabel)
                
                UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                    let left = UIView()
                    left.frame = self.view.frame
                    self.view.addSubview(left)
                    left.addSubview(self.leftImage)
                    left.addSubview(self.leftText)
                    left.frame.origin.y += 200
                })
                    
                UIView.animate(withDuration: 0.5, delay: 0.1, options: [], animations: {
                    container.frame.origin.y += 200
                }, completion: { _ in
                    self.performSegue(withIdentifier: "toGame", sender: self)
                })
            }
            
            if rightImage.frame.contains(touchLocation) || rightText.frame.contains(touchLocation) {
                
                AudioServicesPlaySystemSound(1520)
                
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
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {

    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        appDelegate.mpcHandler.browser.dismiss(animated: true)
        appDelegate.mpcHandler.browser = nil
    }
}

