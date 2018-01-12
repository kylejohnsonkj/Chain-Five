//
//  self.swift
//  Chain Five
//
//  Created by Kyle Johnson on 1/12/18.
//  Copyright © 2018 Kyle Johnson. All rights reserved.
//

import UIKit

/// Displays the in-game tutorial.
class HelpView: UIView {
    
    let l = Layout()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.frame = CGRect(x: l.leftMargin, y: l.topMargin, width: l.cardSize * 10, height: (l.cardSize * 10) + l.stroke)
        self.backgroundColor = .white
        self.layer.zPosition = 10
        
        addContent()
    }
    
    func addContent() {
        
        let temp1 = UILabel()
        temp1.text = "temporary help page"
        temp1.font = UIFont(name: "GillSans", size: l.cardSize / 1.5)
        temp1.frame = CGRect(x: 0, y: 30, width: self.frame.width, height: 60)
        temp1.textAlignment = .center
        self.addSubview(temp1)
        
        let temp2 = UILabel()
        temp2.text = "first to 5 in a row wins"
        temp2.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        temp2.frame = CGRect(x: 0, y: 90, width: self.frame.width, height: 30)
        temp2.textAlignment = .center
        self.addSubview(temp2)
        
        let temp3 = UILabel()
        temp3.text = "black jacks can be placed anywhere open"
        temp3.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        temp3.frame = CGRect(x: 0, y: 120, width: self.frame.width, height: 30)
        temp3.textAlignment = .center
        self.addSubview(temp3)
        
        let temp4 = UILabel()
        temp4.text = "red jacks can remove an opponent's piece"
        temp4.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        temp4.frame = CGRect(x: 0, y: 150, width: self.frame.width, height: 30)
        temp4.textAlignment = .center
        self.addSubview(temp4)
        
        let temp5 = UILabel()
        temp5.text = "the white dot marks opponent's last move"
        temp5.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        temp5.frame = CGRect(x: 0, y: 180, width: self.frame.width, height: 30)
        temp5.textAlignment = .center
        self.addSubview(temp5)
        
        let temp6 = UILabel()
        temp6.text = "one dead card can be swapped per turn"
        temp6.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        temp6.frame = CGRect(x: 0, y: 210, width: self.frame.width, height: 30)
        temp6.textAlignment = .center
        self.addSubview(temp6)
        
        let temp7 = UILabel()
        temp7.text = "enjoy the game!"
        temp7.font = UIFont(name: "GillSans", size: l.cardSize / 2)
        temp7.frame = CGRect(x: 0, y: 240, width: self.frame.width, height: 30)
        temp7.textAlignment = .center
        self.addSubview(temp7)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

