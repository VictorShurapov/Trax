//
//  AppDelegate.swift
//  Trax
//
//  Created by Victor Shurapov on 3/2/18.
//  Copyright © 2018 Victor Shurapov. All rights reserved.
//

import UIKit

struct GPXURL {
    static let Notification = "GPXURL Radio Station"
    static let Key = "GPXURL URL Key"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let center = NotificationCenter.default
        let notification = Notification(name: Notification.Name(rawValue: GPXURL.Notification), object: self, userInfo: [GPXURL.Key: url])
        center.post(notification)
       
        return true
    }
}

