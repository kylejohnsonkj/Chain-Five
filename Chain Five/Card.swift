//
//  Card.swift
//  Chain Five
//
//  Created by Kyle Johnson on 12/1/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

// Just a fancy UIImageView. Stores details with card such as ID, and whether it is selected, marked and by which player.

import UIKit

class Card: UIImageView {
    
    var l: Layout
    var id: String
    var isSelected: Bool {
        didSet {
            if isSelected == true {
                self.layer.borderWidth = l.highlight
            } else {
                self.layer.borderWidth = 0
            }
        }
    }
    
    var index: Int
    var owner: Int {
        didSet {
            prevOwner = oldValue
        }
    }
    var prevOwner: Int
    var isFreeSpace: Bool
    var marker: UIImageView
    
    var isMarked: Bool {
        didSet {
            guard owner != 0 else {
                return
            }
            let color = owner == 1 ? "orange" : "blue"
            let markerImage = UIImage(named: color)
            marker = UIImageView(image: markerImage)
            marker.frame = CGRect(x: 0, y: 0, width: l.cardSize, height: l.cardSize)
            self.addSubview(marker)
            
            // pulse marker when placed
            pulseMarker()
        }
    }
    
    var isMostRecent: Bool {
        didSet {
            var color = owner == 1 ? "orange" : "blue"
            if owner == 2 {
                color = "blue"
            } else if owner == 1 {
                color = "orange"
            } else {
                color = prevOwner == 1 ? "orange" : "blue"
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
            if isChecked == true {
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
    
    init(named id: String) {
        self.id = id
        self.isSelected = false
        self.owner = 0
        self.prevOwner = 0
        self.isMarked = false
        self.isFreeSpace = false
        self.index = -1
        self.isChecked = false
        self.isMostRecent = false
        
        let markerImage = UIImage(named: "orange_chain")
        marker = UIImageView(image: markerImage)
        
        let image = UIImage(named: id)
        l = Layout()
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
            self.marker.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: { _ in
            UIView.animate(withDuration: 0.4, animations: {
                self.marker.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.marker.alpha = 0.5
            })
        })
    }
    
    func removeMarker() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.marker.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
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
