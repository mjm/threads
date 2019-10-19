//
//  AddThreadSceneDelegate.swift
//  Threads
//
//  Created by Matt Moriarity on 10/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)

class AddThreadSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var addThreadsDelegate: AddThreadViewControllerDelegate?
    var toolbarDelegate: AddThreadToolbarDelegate?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let userActivity = connectionOptions.userActivities.first else {
            NSLog("AddThread scene was created without a user activity")
            closeWindow(session)
            return
        }
        
        let addThreadController = window!.rootViewController as! AddThreadViewController
    
        guard case let .addThreads(mode) = UserActivity(userActivity: userActivity, context: addThreadController.managedObjectContext) else {
            NSLog("AddThread scene was created with the wrong type of user activity")
            closeWindow(session)
            return
        }
        
        if let scene = scene as? UIWindowScene {
            scene.sizeRestrictions?.minimumSize = CGSize(width: 300, height: 300)
            scene.sizeRestrictions?.maximumSize = CGSize(width: 500, height: 4000)
            
            if let titlebar = scene.titlebar {
                titlebar.titleVisibility = .hidden
                
                let toolbar = NSToolbar(identifier: .addThreadToolbar)
                toolbarDelegate = AddThreadToolbarDelegate()
                toolbar.delegate = toolbarDelegate
                toolbar.centeredItemIdentifier = .title
                
                titlebar.toolbar = toolbar
            }
        }
        
        addThreadsDelegate = mode.makeDelegate(context: addThreadController.managedObjectContext)
        addThreadController.delegate = addThreadsDelegate
        addThreadController.onDismiss = {
            UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
        }
    }
    
    private func closeWindow(_ session: UISceneSession) {
        // this is a hack to make the window go away automatically in case this scene is left over from the application
        // terminating uncleanly.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
        }
    }
}

extension NSToolbar.Identifier {
    static let addThreadToolbar = "addThreadToolbar"
}

class AddThreadToolbarDelegate: NSObject, NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.title, .flexibleSpace, .addThreads]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .title:
            let item = NSToolbarItem(itemIdentifier: .title)
            item.title = "Add Threads"
            return item
        case .addThreads:
            let item = NSToolbarItem(itemIdentifier: .addThreads)
            item.toolTip = "Add the chosen threads"
            item.title = "Add"
            item.isBordered = true
            item.action = #selector(AddThreadViewController.add)
            return item
        default:
            preconditionFailure("unexpected toolbar item identifier \(itemIdentifier)")
        }
    }
}

#endif
