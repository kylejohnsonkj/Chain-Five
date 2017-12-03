//
//  Card.swift
//  Sequence
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
    
    var owner: Int
    var isMarked: Bool {
        didSet {
            guard owner != 0 else { return }
            var color = ""
            if owner == 1 {
                color = "orange"
            } else {
                color = "blue"
            }
            let image = UIImage(named: color)
            let marker = UIImageView(image: image)
            marker.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
            self.addSubview(marker)
        }
    }
    var isFreeSpace: Bool
    
    init(named id: String) {
        self.id = id
        self.isSelected = false
        self.owner = 0
        self.isMarked = false
        self.isFreeSpace = false
        
        let image = UIImage(named: id)
        super.init(image: image)
        
        self.layer.borderColor = UIColor.green.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
