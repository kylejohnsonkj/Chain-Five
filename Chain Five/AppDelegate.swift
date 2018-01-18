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
        printVersionInfo()
        GCHelper.shared.authenticateLocalUser()
        return true
    }
    
    func printVersionInfo() {
        if let info = Bundle.main.infoDictionary {
            if let version = info["CFBundleShortVersionString"] as? String {
                print("Chain Five v\(version)")
            }
        }
    }
}

extension UIApplication {
    class func getPresentedViewController() -> UIViewController? {
        var presentedViewController = UIApplication.shared.keyWindow?.rootViewController
        while let presentedVC = presentedViewController?.presentedViewController {
            presentedViewController = presentedVC
        }
        return presentedViewController
    }
}

