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
            NSLog("connecting to scene with user activity \(activity.activityType) \(activity)")
            restoreActivity(activity, animated: false)
        }

        window?.tintColor = .systemIndigo
        
        // Force shopping list to load so it can set its badge value
        let shoppingListController = getTab(type: ShoppingListViewController.self)
        shoppingListController.loadViewIfNeeded()
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
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext.commit()
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        NSLog("continuing user activity \(userActivity.activityType) \(userActivity)")
        restoreActivity(userActivity, animated: scene.activationState == .foregroundActive)
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        guard let window = window else { return nil }
        
        let tabController = window.rootViewController as! UITabBarController
        let navController = tabController.selectedViewController as! UINavigationController
        let displayedController = navController.topViewController
        let activity = displayedController?.userActivity
        
        NSLog("storing user activity \(activity?.activityType ?? "") \(String(describing: activity))")
        
        return activity
    }
    
    private func restoreActivity(_ activity: NSUserActivity, animated: Bool) {
        NSLog("restoring user activity \(activity.activityType) \(activity)")
        
        // get the context so we can rehydrate objects from the activity
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        switch UserActivity(userActivity: activity, context: context) {
        case .showMyThreads:
            selectTab(type: MyThreadsViewController.self)
        case .showShoppingList:
            selectTab(type: ShoppingListViewController.self)
        case .showProjects:
            selectTab(type: ProjectListViewController.self)
        case let .showThread(thread):
            let myThreadsController = selectTab(type: MyThreadsViewController.self)
            if let threadDetailController = topViewController as? ThreadDetailViewController,
                threadDetailController.thread == thread {
                NSLog("already viewing the right thread, doing nothing")
            } else {
                navigationController.popToRootViewController(animated: animated)
                let detailViewController = myThreadsController.storyboard!.instantiateViewController(identifier: "ThreadDetail") { coder in
                    myThreadsController.makeDetailController(coder: coder, sender: thread)
                }
                navigationController.pushViewController(detailViewController, animated: animated)
            }
        case let .showProject(project):
            let projectListController = selectTab(type: ProjectListViewController.self)
            if let projectDetailController = topViewController as? ProjectDetailViewController,
                projectDetailController.project == project {
                NSLog("already viewing the right project, doing nothing")
            } else {
                navigationController.popToRootViewController(animated: animated)
                let detailViewController = projectListController.storyboard!.instantiateViewController(identifier: "ProjectDetail") { coder in
                    projectListController.makeDetailController(coder: coder, sender: ProjectDetail(project: project))
                }
                navigationController.pushViewController(detailViewController, animated: animated)
            }
        case .none:
            NSLog("Was not able to load the activity. It may have referenced an object that no longer exists, or it may be a new activity type handed off to us from a newer version of the app (though I'm not sure the system will let that last one happen).")
        }
    }
    
    @discardableResult private func selectTab<T: UIViewController>(type controllerType: T.Type) -> T {
        let rootViewController = getTab(type: controllerType)
        tabBarController.selectedViewController = rootViewController.navigationController
        return rootViewController
    }
    
    private func getTab<T: UIViewController>(type: T.Type) -> T {
        for vc in tabBarController.viewControllers ?? [] {
            let navController = vc as! UINavigationController
            if let rootController = navController.viewControllers.first as? T {
                return rootController
            }
        }
        
        fatalError("Could not find a tab whose root view controller was \(type)")
    }
    
    private var tabBarController: UITabBarController {
        return window!.rootViewController as! UITabBarController
    }
    
    private var navigationController: UINavigationController {
        return tabBarController.selectedViewController as! UINavigationController
    }
    
    private var topViewController: UIViewController {
        return navigationController.topViewController!
    }
}

