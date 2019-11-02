//
//  MacSceneDelegate.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events
import UIKit

#if targetEnvironment(macCatalyst)

extension NSToolbar.Identifier {
    static let appToolbar = NSToolbar.Identifier("appToolbar")
}

class MacSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        let scene = scene as! UIWindowScene
        let rootViewController = window!.rootViewController as! SplitViewController

        let toolbar = NSToolbar(identifier: .appToolbar)
        toolbar.allowsUserCustomization = false
        toolbar.centeredItemIdentifier = .title

        (UIApplication.shared.delegate as! AppDelegate).activityItemsConfiguration
            = rootViewController
        toolbar.delegate = rootViewController

        scene.titlebar?.toolbar = toolbar
        scene.titlebar?.titleVisibility = .hidden

        if let activity = connectionOptions.userActivities.first
            ?? scene.session.stateRestorationActivity
        {
            restoreActivity(activity, animated: false)
        }
        Event.current.send("connecting scene")
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        restoreActivity(userActivity, animated: scene.activationState == .foregroundActive)
        Event.current.send("continued activity")
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        guard let window = window else { return nil }

        let rootViewController = window.rootViewController as! SplitViewController

        if let activity = rootViewController.detailViewController.currentUserActivity {
            UserActivity(userActivity: activity, context: .view)?.addToCurrentEvent()
            Event.current.send("saving activity")
            return activity
        }

        return nil
    }

    private func restoreActivity(_ activity: NSUserActivity, animated: Bool) {
        Event.current[.activityType] = activity.activityType

        guard let window = window else { return }

        let rootViewController = window.rootViewController as! SplitViewController

        let userActivity = UserActivity(userActivity: activity, context: .view)
        userActivity?.addToCurrentEvent()

        switch userActivity {
        case .showMyThreads, .showThread:
            rootViewController.viewModel.selection = .collection
        case .showShoppingList:
            rootViewController.viewModel.selection = .shoppingList
        case let .showProject(project):
            rootViewController.viewModel.selection = .project(project)
        case .none:
            NSLog(
                "Was not able to load the activity. It may have referenced an object that no longer exists, or it may be a new activity type handed off to us from a newer version of the app (though I'm not sure the system will let that last one happen)."
            )
        default:
            return
        }
    }
}

#endif
