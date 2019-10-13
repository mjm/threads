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
        (UIApplication.shared.delegate as! AppDelegate).activityItemsConfiguration = toolbarDelegate
        toolbar.delegate = toolbarDelegate
        
        scene.titlebar?.toolbar = toolbar
        scene.titlebar?.titleVisibility = .hidden
    }
}

extension NSToolbarItem.Identifier {
    static let addProject = NSToolbarItem.Identifier("addProject")
    static let title = NSToolbarItem.Identifier("title")
    static let addThreads = NSToolbarItem.Identifier("addThreads")
    static let edit = NSToolbarItem.Identifier("edit")
    static let doneEditing = NSToolbarItem.Identifier("doneEditing")
    static let share = NSToolbarItem.Identifier("share")
}

class ToolbarDelegate: NSObject, NSToolbarDelegate {
    let rootViewController: SplitViewController
    
    init(rootViewController: SplitViewController) {
        self.rootViewController = rootViewController
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addProject, .title, .flexibleSpace, .addThreads]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addProject, .title, .addThreads, .edit, .doneEditing, .share]
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .addProject:
            let item = NSToolbarItem(itemIdentifier: .addProject)
            item.toolTip = "Create a new project"
            item.image = UIImage(systemName: "rectangle.stack.badge.plus")
            item.isBordered = true
            item.action = #selector(SplitViewController.addProject(_:))
            return item
        case .title:
            let item = NSToolbarItem(itemIdentifier: .title)
            item.title = "Threads"
            return item
        case .addThreads:
            let item = NSToolbarItem(itemIdentifier: .addThreads)
            item.toolTip = "Add threads"
            item.image = UIImage(systemName: "plus")
            item.isBordered = true
            item.action = #selector(SplitViewController.addThreads(_:))
            return item
        case .edit:
            let item = NSToolbarItem(itemIdentifier: .edit)
            item.toolTip = "Edit this project"
            item.image = UIImage(systemName: "pencil")
            item.isBordered = true
            item.action = #selector(SplitViewController.toggleEditingProject(_:))
            return item
        case .doneEditing:
            let item = NSToolbarItem(itemIdentifier: .doneEditing)
            item.toolTip = "Stop editing this project"
            item.title = "Done"
            item.isBordered = true
            item.action = #selector(SplitViewController.toggleEditingProject(_:))
            return item
        case .share:
            let item = NSSharingServicePickerToolbarItem(itemIdentifier: .share)
            item.toolTip = "Publish and share this project"
            item.activityItemsConfiguration = self
            return item
        default:
            fatalError("unexpected toolbar item identifier \(itemIdentifier)")
        }
    }
}

extension ToolbarDelegate: UIActivityItemsConfigurationReading {
    var itemProvidersForActivityItemsConfiguration: [NSItemProvider] {
        if let project = rootViewController.projectDetailViewController?.project {
            return [project.itemProvider]
        }
        
        return []
    }
}

#endif
