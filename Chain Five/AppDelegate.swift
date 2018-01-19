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
        printAppVersion()
        GCHelper.shared.authenticateLocalUser()
        return true
    }
    
    func printAppVersion() {
        if let info = Bundle.main.infoDictionary {
            if let version = info["CFBundleShortVersionString"] as? String {
                print("Chain Five v\(version)")
            }
        }
    }
}

extension UIApplication {
    class func getCurrentViewController() -> UIViewController? {
        var currentVC = UIApplication.shared.keyWindow?.rootViewController
        while let presentedVC = currentVC?.presentedViewController {
            currentVC = presentedVC
        }
        return currentVC
    }
}

