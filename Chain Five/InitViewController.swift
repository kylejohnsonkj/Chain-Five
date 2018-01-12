//
//  InitViewController.swift
//  Chain Five
//
//  Created by Kyle Johnson on 1/1/18.
//  Copyright © 2018 Kyle Johnson. All rights reserved.
//

import UIKit

/// Ensures main menu is presented modally on launch.
class InitViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // this is to fix issues with large status bars screwing up non-modal views
    override func viewDidAppear(_ animated: Bool) {
        self.performSegue(withIdentifier: "init", sender: self)
    }
}

