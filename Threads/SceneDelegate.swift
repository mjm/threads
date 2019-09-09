//
//  SceneDelegate.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let activity = connectionOptions.userActivities.first ?? scene.session.stateRestorationActivity {
            restoreActivity(activity)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        restoreActivity(userActivity)
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        guard let window = window else { return nil }
        
        let tabController = window.rootViewController as! UITabBarController
        let navController = tabController.selectedViewController as! UINavigationController
        let displayedController = navController.topViewController
        return displayedController?.userActivity
    }
    
    private func restoreActivity(_ activity: NSUserActivity) {
        NSLog("restoring activity \(activity.activityType) \(activity)")
        
        switch activity.activityType {
        case "com.mattmoriarity.Threads.ShowMyThreads":
            selectTab(type: MyThreadsViewController.self)
        case "com.mattmoriarity.Threads.ShowShoppingList":
            selectTab(type: ShoppingListViewController.self)
        case "com.mattmoriarity.Threads.ShowProjects":
            selectTab(type: ProjectListViewController.self)
        default:
            fatalError("Trying to restore unknown activity type: \(activity.activityType)")
        }
    }
    
    private func selectTab(type controllerType: UIViewController.Type) {
        let tabController = window?.rootViewController as! UITabBarController
        tabController.selectedViewController = tabController.viewControllers?.first { vc in
            let navController = vc as! UINavigationController
            return type(of: navController.viewControllers.first!) == controllerType
        }
    }
}

