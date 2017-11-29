//
//  MainViewController.swift
//  Sequence
//
//  Created by Kyle Johnson on 11/29/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        generateBoard()
        showButtons()
    }
    
    func generateBoard() {

        // aesthetics
        let bottomBorder = UIView()
        bottomBorder.frame = CGRect(x: 13, y: 485, width: 350, height: 1)
        bottomBorder.layer.borderColor = UIColor.black.cgColor
        bottomBorder.layer.borderWidth = 1
        view.addSubview(bottomBorder)
        bottomBorder.alpha = 0
        
        // load the 100 cards
        var i = 0
        while i < 100 {
            let card = Card(named: self.cardsLayout[i])
            card.frame = CGRect(x: 30, y: 50, width: 35, height: 35)
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
    }

    func showButtons() {
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
