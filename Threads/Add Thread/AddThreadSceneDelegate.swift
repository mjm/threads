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
        
        window!.canResizeToFitContent = true
        
        let addThreadController = window!.rootViewController as! AddThreadViewController
        
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
