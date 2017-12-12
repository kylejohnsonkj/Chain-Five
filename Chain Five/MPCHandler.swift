//
//  MPCHandler.swift
//  Chain Five
//
//  Created by Kyle Johnson on 12/11/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit
import MultipeerConnectivity

// tutorial: https://www.youtube.com/watch?v=JwqsbsyN3LA
// this MPC example uses states for tic tac toe
// we will want to update when a player makes a move, thus adding a token to the board at their chosen position
// we also want an update when they draw a new card from the SHARED deck
// should be able to combine these two into one update

extension Notification.Name {
    static let didChange = Notification.Name("MPC_DidChangeStateNotification")
    static let didReceive = Notification.Name("MPC_DidReceiveDataNotification")
}

class MPCHandler: NSObject, MCSessionDelegate {

    var peerID: MCPeerID!
    var session: MCSession!
    var browser: MCBrowserViewController!
    var advertiser: MCAdvertiserAssistant? = nil
    
    override init() {
        super.init()
        NSLog("MPCHandler instance created")
    }
    
    func setupPeerWithDisplayName(displayName: String) {
        peerID = MCPeerID(displayName: displayName)
    }
    
    func setupSession() {
        session = MCSession(peer: peerID)
        session.delegate = self
    }
    
    func setupBrowser() {
        browser = MCBrowserViewController(serviceType: "chain-five", session: session)
    }
    
    func advertiseSelf(advertise: Bool) {
        if advertise == true {
            advertiser = MCAdvertiserAssistant(serviceType: "chain-five", discoveryInfo: nil, session: session)
            advertiser!.start()
        } else {
            advertiser!.stop()
            advertiser = nil
        }
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let userInfo = ["peerID": peerID, "state": state.rawValue] as [String : Any]
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didChange, object: nil, userInfo: userInfo)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let userInfo = ["data": data, "peerID": peerID] as [String : Any]
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didReceive, object: nil, userInfo: userInfo)
        }
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
}
