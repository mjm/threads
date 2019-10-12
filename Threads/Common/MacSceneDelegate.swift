//
//  MacSceneDelegate.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

#if targetEnvironment(macCatalyst)

extension NSToolbar.Identifier {
    static let appToolbar = NSToolbar.Identifier("appToolbar")
}

class MacSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var toolbarDelegate: ToolbarDelegate!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let scene = scene as! UIWindowScene
        let rootViewController = window!.rootViewController as! SplitViewController
        
        let toolbar = NSToolbar(identifier: .appToolbar)
        toolbar.allowsUserCustomization = false
        toolbar.centeredItemIdentifier = .title
        
        toolbarDelegate = ToolbarDelegate(rootViewController: rootViewController)
        toolbar.delegate = toolbarDelegate
        
        scene.titlebar?.toolbar = toolbar
        scene.titlebar?.titleVisibility = .hidden
    }
}

extension NSToolbarItem.Identifier {
    static let addProject = NSToolbarItem.Identifier("addProject")
    static let title = NSToolbarItem.Identifier("title")
}

class ToolbarDelegate: NSObject, NSToolbarDelegate {
    let rootViewController: SplitViewController
    
    init(rootViewController: SplitViewController) {
        self.rootViewController = rootViewController
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addProject, .title]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addProject, .title]
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .addProject:
            let item = NSToolbarItem(itemIdentifier: .addProject)
            item.image = UIImage(systemName: "plus")
            item.isBordered = true
            item.action = #selector(SplitViewController.addProject(_:))
            return item
        case .title:
            let item = NSToolbarItem(itemIdentifier: .title)
            item.title = "Threads"
            return item
        default:
            fatalError("unexpected toolbar item identifier \(itemIdentifier)")
        }
    }
}

#endif
