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
    
    let l = Layout.shared
    
    var id: String
    var index: Int
    var isSelected: Bool {
        didSet {
            if isSelected {
                layer.borderWidth = l.highlight
            } else {
                layer.borderWidth = 0
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
                subviews.forEach { $0.removeFromSuperview() }
                
                let color = owner == 1 ? "orange" : "blue"
                let markerImage = UIImage(named: color)
                marker = UIImageView(image: markerImage)
                marker.frame = CGRect(x: 0, y: 0, width: l.cardSize, height: l.cardSize)
                addSubview(marker)
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
                addSubview(marker)
                
                // pulse marker when checked
                pulseMarker()
            }
        }
    }
    
    var isFreeSpace: Bool
    
    init(named name: String) {
        id = name
        index = -1
        isSelected = false
        prevOwner = 0
        owner = 0
        isMarked = false
        isMostRecent = false
        isChecked = false
        
        // mark the free spaces
        if id == "-free" {
            isFreeSpace = true
        } else {
            isFreeSpace = false
        }
        
        let markerImage = UIImage(named: "orange_chain")
        marker = UIImageView(image: markerImage)
        
        let image = UIImage(named: id)
        super.init(image: image)
        
        layer.borderColor = UIColor.green.cgColor
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

