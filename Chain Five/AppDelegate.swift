//
//  AppDelegate.swift
//  Chain Five
//
//  Created by Kyle Johnson on 11/23/17.
//  Copyright © 2017 Kyle Johnson. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        GCHelper.sharedInstance.authenticateLocalUser()
        suppressGCBanner(0, originalWindowCount: UIApplication.shared.windows.count)
        return true
    }
    
    func suppressGCBanner(_ iteration: Int, originalWindowCount: Int) {
        
        let windows = UIApplication.shared.windows
        
        if windows.count > originalWindowCount {
            let window = windows[1]
            if window.responds(to: Selector(("currentBannerViewController"))) || window.responds(to: Selector(("bannerSemaphore"))) {
                print("Found banner, killing it \(iteration)")
                window.isHidden = true
                return
            }
        }
        
        if iteration > 200 {
            print("suppressGCBanner: timeout, bailing")
            return
        }
        
        runThisAfterDelay(seconds: 0.02, after: {
            self.suppressGCBanner(iteration + 1, originalWindowCount: originalWindowCount)
        })
    }
    
    func runThisAfterDelay(seconds: Double, after: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            after()
        }
    }

}

