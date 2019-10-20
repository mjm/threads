//
//  MacSceneDelegate.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import Events

#if targetEnvironment(macCatalyst)

extension NSToolbar.Identifier {
    static let appToolbar = NSToolbar.Identifier("appToolbar")
}

class MacSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let scene = scene as! UIWindowScene
        let rootViewController = window!.rootViewController as! SplitViewController
        
        let toolbar = NSToolbar(identifier: .appToolbar)
        toolbar.allowsUserCustomization = false
        toolbar.centeredItemIdentifier = .title
        
        (UIApplication.shared.delegate as! AppDelegate).activityItemsConfiguration = rootViewController
        toolbar.delegate = rootViewController
        
        scene.titlebar?.toolbar = toolbar
        scene.titlebar?.titleVisibility = .hidden
        
        if let activity = connectionOptions.userActivities.first ?? scene.session.stateRestorationActivity {
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
        let activity = rootViewController.detailViewController.currentUserActivity
        
        Event.current[.activityType] = activity?.activityType
        Event.current.send("saving activity")
        
        return activity
    }
    
    private func restoreActivity(_ activity: NSUserActivity, animated: Bool) {
        Event.current[.activityType] = activity.activityType
        
        guard let window = window else { return }
        
        let rootViewController = window.rootViewController as! SplitViewController
        
        // get the context so we can rehydrate objects from the activity
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        switch UserActivity(userActivity: activity, context: context) {
        case .showMyThreads, .showThread:
            rootViewController.selection = .collection
        case .showShoppingList:
            rootViewController.selection = .shoppingList
        case let .showProject(project):
            Event.current[.projectName] = project.name
            rootViewController.selection = .project(project)
        case .none:
            NSLog("Was not able to load the activity. It may have referenced an object that no longer exists, or it may be a new activity type handed off to us from a newer version of the app (though I'm not sure the system will let that last one happen).")
        default:
            return
        }
    }
}

#endif
