//
//  SceneDelegate.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CoreData
import Events
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let _ = (scene as? UIWindowScene) else { return }

        if let activity = connectionOptions.userActivities.first
            ?? scene.session.stateRestorationActivity
        {
            restoreActivity(activity, animated: false)
        }

        window?.tintColor = .systemIndigo

        // Force shopping list to load so it can set its badge value
        let shoppingListController = getTab(type: ShoppingListViewController.self)
        shoppingListController.loadViewIfNeeded()

        Event.current.send("connecting scene")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext.commit()
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        restoreActivity(userActivity, animated: scene.activationState == .foregroundActive)
        Event.current.send("continuing activity")
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        guard let window = window else { return nil }

        let tabController = window.rootViewController as! UITabBarController
        let navController = tabController.selectedViewController as! UINavigationController
        let displayedController = navController.topViewController

        if let activity = displayedController?.userActivity {
            UserActivity(userActivity: activity, context: .view)?.addToCurrentEvent()
            Event.current.send("saving activity")
            return activity
        }

        return nil
    }

    private func restoreActivity(_ activity: NSUserActivity, animated: Bool) {
        Event.current[.activityType] = activity.activityType

        let userActivity = UserActivity(userActivity: activity, context: .view)
        userActivity?.addToCurrentEvent()

        switch userActivity {
        case .showMyThreads:
            selectTab(type: MyThreadsViewController.self)
        case .showShoppingList:
            selectTab(type: ShoppingListViewController.self)
        case .showProjects:
            selectTab(type: ProjectListViewController.self)
        case let .showThread(thread):
            let myThreadsController = selectTab(type: MyThreadsViewController.self)
            if let threadDetailController = topViewController as? ThreadDetailViewController,
                threadDetailController.viewModel.thread == thread
            {
                return
            }

            navigationController.popToRootViewController(animated: animated)
            let detailViewController = myThreadsController.storyboard!.instantiateViewController(
                identifier: "ThreadDetail"
            ) { coder in
                myThreadsController.makeDetailController(coder: coder, sender: thread)
            }
            navigationController.pushViewController(detailViewController, animated: animated)
        case let .showProject(project):
            let projectListController = selectTab(type: ProjectListViewController.self)
            if let projectDetailController = topViewController as? ProjectDetailViewController,
                projectDetailController.viewModel.project == project
            {
                return
            }

            navigationController.popToRootViewController(animated: animated)
            let detailViewController = projectListController.storyboard!.instantiateViewController(
                identifier: "ProjectDetail"
            ) { coder in
                projectListController.makeDetailController(
                    coder: coder, sender: ProjectDetail(project: project))
            }
            navigationController.pushViewController(detailViewController, animated: animated)
        case .addThreads:
            preconditionFailure("SceneDelegate should not have to handle an addThreads activity")
        case .none:
            NSLog(
                "Was not able to load the activity. It may have referenced an object that no longer exists, or it may be a new activity type handed off to us from a newer version of the app (though I'm not sure the system will let that last one happen)."
            )
        }
    }

    @discardableResult private func selectTab<T: UIViewController>(type controllerType: T.Type) -> T
    {
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
