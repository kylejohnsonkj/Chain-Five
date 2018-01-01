//
//  InitViewController.swift
//  Chain Five
//
//  Created by Kyle Johnson on 1/1/18.
//  Copyright © 2018 Kyle Johnson. All rights reserved.
//

import UIKit

class InitViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // ensures all views are presented modally
    // this is to fix issues with non-standard status bars screwing up views
    override func viewDidAppear(_ animated: Bool) {
        self.performSegue(withIdentifier: "init", sender: self)
    }
}
