//
//  Card.swift
//  Chain Five
//
//  Created by Kyle Johnson on 12/1/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit

/// Just a fancy UIImageView. Stores details like card ID, whether it's selected, marked, and by which player.
class Card: UIImageView {
    
    let l = Layout()
    
    var id: String
    var index: Int
    var isSelected: Bool {
        didSet {
            if isSelected {
                self.layer.borderWidth = l.highlight
            } else {
                self.layer.borderWidth = 0
            }
        }
    }
    
    var prevOwner: Int
    var owner: Int {
        didSet {
            prevOwner = oldValue
        }
    }
    
    var marker: UIImageView
    var isMarked: Bool {
        didSet {
            if isMarked {
                self.subviews.forEach { $0.removeFromSuperview() }
                
                let color = owner == 1 ? "orange" : "blue"
                let markerImage = UIImage(named: color)
                marker = UIImageView(image: markerImage)
                marker.frame = CGRect(x: 0, y: 0, width: l.cardSize, height: l.cardSize)
                self.addSubview(marker)
                
                // pulse marker when placed
                pulseMarker()
            }
        }
    }
    
    var isMostRecent: Bool {
        didSet {
            var color: String
            if owner == 1 {
                color = "orange"
            } else if owner == 2 {
                color = "blue"
            } else {
                // recently removed and owner == 0
                color = prevOwner == 1 ? "blue" : "orange"
            }
            
            if isMostRecent == true {
                marker.image = UIImage(named: "\(color)_recent")
            } else {
                marker.image = UIImage(named: color)
            }
        }
    }
    
    // checked to show winning sequence
    var isChecked: Bool {
        didSet {
            if isChecked {
                let color = owner == 1 ? "orange" : "blue"
                let markerImage = UIImage(named: "\(color)_chain")
                marker = UIImageView(image: markerImage)
                marker.frame = CGRect(x: 0, y: 0, width: l.cardSize, height: l.cardSize)
                self.addSubview(marker)
                
                // pulse marker when checked
                pulseMarker()
            }
        }
    }
    
    var isFreeSpace: Bool
    
    init(named id: String) {
        self.id = id
        self.index = -1
        self.isSelected = false
        self.prevOwner = 0
        self.owner = 0
        self.isMarked = false
        self.isMostRecent = false
        self.isChecked = false
        
        // mark the free spaces
        if id == "-free" {
            self.isFreeSpace = true
        } else {
            self.isFreeSpace = false
        }
        
        let markerImage = UIImage(named: "orange_chain")
        marker = UIImageView(image: markerImage)
        
        let image = UIImage(named: id)
        super.init(image: image)
        
        self.layer.borderColor = UIColor.green.cgColor
    }
    
    func pulseMarker() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.marker.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: { _ in
            UIView.animate(withDuration: 0.4, animations: {
                self.marker.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        })
    }
    
    func fadeMarker() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.marker.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.marker.alpha = 0.5
        }, completion: { _ in
            UIView.animate(withDuration: 0.4, animations: {
                self.marker.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        })
    }
    
    func removeMarker() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.marker.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.marker.alpha = 0.5
        }, completion: { _ in
            UIView.animate(withDuration: 0.4, animations: {
                self.marker.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.marker.alpha = 0
            }, completion: { _ in
                self.subviews.forEach { $0.removeFromSuperview() }
            })
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

