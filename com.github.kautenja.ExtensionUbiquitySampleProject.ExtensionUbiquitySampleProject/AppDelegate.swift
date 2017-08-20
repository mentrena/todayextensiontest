//
//  AppDelegate.swift
//  com.github.kautenja.ExtensionUbiquitySampleProject.ExtensionUbiquitySampleProject
//
//  Created by James Kauten on 8/19/17.
//  Copyright © 2017 Christian Kauten. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        CoreDataStack.shared.setup(context: .extensions)
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        CoreDataStack.shared.saveContext()
    }

}

