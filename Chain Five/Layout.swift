//
//  Layout.swift
//  Chain Five
//
//  Created by Kyle Johnson on 1/2/18.
//  Copyright © 2018 Kyle Johnson. All rights reserved.
//

import UIKit

/// Everything needed for my custom AutoLayout.
class Layout {
    
    // primary scale indicators
    var iPad = false
    var cardSize: CGFloat
    var push: CGFloat
    
    // margins (based off primary)
    var leftMargin: CGFloat
    var topMargin: CGFloat
    var btmMargin: CGFloat
    var centerY: CGFloat
    
    // secondary scale indicators
    var scale: CGFloat
    var offset: CGFloat
    var textPadding: CGFloat
    var imgSize: CGFloat
    var stroke: CGFloat
    
    // widths (based off secondary)
    var titleWidth: CGFloat
    var titleHeight: CGFloat
    var itemWidth: CGFloat
    var highlight: CGFloat
    
    init() {
        let view = UIApplication.shared.keyWindow!
        
        // determine if iPad or not
        if (UIApplication.shared.keyWindow?.bounds.width)! > CGFloat(414) {
            // it's an iPad, adapt for different aspect ratio
            iPad = true
            cardSize = view.bounds.width / 14
            push = cardSize * 0.75
        } else {
            iPad = false
            cardSize = view.bounds.width / 10.7
            push = cardSize * 0.6
        }
        
        leftMargin = view.frame.midX - (self.cardSize * 5)
        topMargin = view.frame.midY - (self.cardSize * 5) - push
        btmMargin = view.frame.midY + (self.cardSize * 5) - push
        centerY = view.frame.midY - push
        
        if iPad {
            scale = 3
            offset = cardSize / 2
            textPadding = 10
            imgSize = cardSize * 2
            stroke = 2
        } else {
            scale = 2
            offset = cardSize / 4
            textPadding = 0
            imgSize = cardSize * 2.25
            stroke = 1
        }
        
        titleWidth = view.bounds.width / scale
        titleHeight = titleWidth * 0.2
        itemWidth = titleWidth / 1.5
        highlight = cardSize / 12
    }
}

