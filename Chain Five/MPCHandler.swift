//
//  MPCHandler.swift
//  Chain Five
//
//  Created by Kyle Johnson on 12/11/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit
import MultipeerConnectivity

extension Notification.Name {
    static let didChangeState = Notification.Name("MPC_DidChangeStateNotification")
    static let didReceiveData = Notification.Name("MPC_DidReceiveDataNotification")
}

class MPCHandler: NSObject, MCSessionDelegate {

    var peerID: MCPeerID!
    var session: MCSession!
    var browser: MCBrowserViewController!
    var advertiser: MCAdvertiserAssistant? = nil
    
    var state: Int! = 0 {
        didSet {
            if state == 0 {
                print("NOT CONNECTED.")
            }
            if state == 1 {
                print("CONNECTING...")
            }
            if state == 2 {
                print("CONNECTED!")
            }
        }
    }
    
    override init() {
        super.init()
        NSLog("MPCHandler instance created")
    }
    
    func setupPeerWithDisplayName(displayName: String) {
        peerID = MCPeerID(displayName: displayName)
    }
    
    func setupSession() {
        session = MCSession(peer: peerID,
                            securityIdentity: nil,
                            encryptionPreference: .optional)
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
            NotificationCenter.default.post(name: .didChangeState, object: nil, userInfo: userInfo)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let userInfo = ["data": data, "peerID": peerID] as [String : Any]
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didReceiveData, object: nil, userInfo: userInfo)
        }
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
}
