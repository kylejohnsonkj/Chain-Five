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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "init" {
            let mainViewController = (segue.destination as! MainViewController)
            mainViewController.firstLoad = true
        }
    }
    
    // ensures main menu view is presented modally on launch
    // this is to fix issues with non-standard status bars screwing up views
    override func viewDidAppear(_ animated: Bool) {
        self.performSegue(withIdentifier: "init", sender: self)
    }
}
