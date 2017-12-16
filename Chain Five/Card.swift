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
    var id: String
    var isSelected: Bool {
        didSet {
            if isSelected == true {
                self.layer.borderWidth = 3
            } else {
                self.layer.borderWidth = 0
            }
        }
    }
    
    var index: Int
    var owner: Int
    
    var isMarked: Bool {
        didSet {
            guard owner != 0 else { return }
            let color = owner == 1 ? "orange" : "blue"
            let image = UIImage(named: color)
            let marker = UIImageView(image: image)
            marker.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
            self.addSubview(marker)
            
            // pulse marker when placed
            pulseMarker(marker)
        }
    }
    var isFreeSpace: Bool
    
    // checked to show winning sequence
    var isChecked: Bool {
        didSet {
            if isChecked == true {
                let color = owner == 1 ? "orange" : "blue"
                let image = UIImage(named: "\(color)_chain")
                let marker = UIImageView(image: image)
                marker.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
                self.addSubview(marker)
                
                // pulse marker when checked
                pulseMarker(marker)
            }
        }
    }
    
    init(named id: String) {
        self.id = id
        self.isSelected = false
        self.owner = 0
        self.isMarked = false
        self.isFreeSpace = false
        self.index = -1
        self.isChecked = false
        
        let image = UIImage(named: id)
        super.init(image: image)
        
        self.layer.borderColor = UIColor.green.cgColor
    }
    
    func pulseMarker(_ marker: UIImageView) {
        UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: {
            marker.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: { _ in
            UIView.animate(withDuration: 0.25, animations: {
                marker.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
