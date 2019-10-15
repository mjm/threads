//
//  AddThreadSceneDelegate.swift
//  Threads
//
//  Created by Matt Moriarity on 10/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class AddThreadSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var addThreadsDelegate: AddThreadViewControllerDelegate?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let scene = scene as? UIWindowScene {
            scene.sizeRestrictions?.minimumSize = CGSize(width: 300, height: 300)
            scene.sizeRestrictions?.maximumSize = CGSize(width: 500, height: 4000)
        }
        
        window!.canResizeToFitContent = true
        
        let navController = window!.rootViewController as! UINavigationController
        let addThreadController = navController.viewControllers[0] as! AddThreadViewController
        
        guard let userActivity = connectionOptions.userActivities.first else {
            NSLog("AddThread scene was created without a user activity")
            return
        }
        
        guard case let .addThreads(mode) = UserActivity(userActivity: userActivity, context: addThreadController.managedObjectContext) else {
            NSLog("AddThread scene was created with the wrong type of user activity")
            return
        }
        
        addThreadsDelegate = mode.makeDelegate(context: addThreadController.managedObjectContext)
        addThreadController.delegate = addThreadsDelegate
        addThreadController.onDismiss = {
            UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
        }
    }
}
