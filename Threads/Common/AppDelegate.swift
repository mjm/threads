//
//  AppDelegate.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

func printResponderChain(_ responder: UIResponder?) {
    guard let responder = responder else { return }

    print(responder)
    printResponderChain(responder.next)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        #if targetEnvironment(macCatalyst)
        return UISceneConfiguration(name: "Mac", sessionRole: connectingSceneSession.role)
        #else
        return UISceneConfiguration(name: "iPhone", sessionRole: connectingSceneSession.role)
        #endif
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        if UserDefaults.standard.bool(forKey: "UseTemporaryStore") {
            return createTemporaryContainer()
        } else {
            return createCloudKitContainer()
        }
    }()

    private func createCloudKitContainer() -> NSPersistentContainer {
        let container = NSPersistentCloudKitContainer(name: "Threads")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            container.performBackgroundTask { context in
                do {
                    let numMerged = try Thread.mergeThreads(context: context)
                    try context.save()
                    NSLog("Merged \(numMerged) threads")
                } catch {
                    NSLog("Error merging duplicate threads: \(error)")
                }

                do {
                    try Thread.importThreads(DMCThread.all, context: context)
                    try context.save()
                    NSLog("Imported threads")
                } catch {
                    NSLog("Error importing threads into local store: \(error)")
                }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = UndoManager()
        return container
    }

    private func createTemporaryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "Threads")

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            container.performBackgroundTask { context in
                do {
                    try Thread.importThreads(DMCThread.all, context: context)
                    try context.save()
                    NSLog("Imported threads")
                } catch {
                    NSLog("Error importing threads into local store: \(error)")
                }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = UndoManager()
        return container
    }
    
    override func buildMenu(with builder: UIMenuBuilder) {
        guard builder.system == .main else { return }
        
        builder.remove(menu: .format)
        builder.remove(menu: .newScene) // remove option to open a new window
        builder.remove(menu: .toolbar)

        builder.insertChild(UIMenu(title: "", options: .displayInline, children: [
            UIKeyCommand(title: "New Project…", action: #selector(SplitViewController.addProject(_:)), input: "n", modifierFlags: [.command])
        ]), atStartOfMenu: .file)
        
        let share = UICommand(title: "Share", action: #selector(SplitViewController.shareProject(_:)), propertyList: UICommandTagShare)
        if let closeMenu = builder.menu(for: .close) {
            builder.replace(menu: .close, with: closeMenu.replacingChildren([share] + closeMenu.children))
        } else {
            builder.insertChild(UIMenu(title: "", options: .displayInline, children: [share]), atEndOfMenu: .file)
        }

        builder.insertChild(UIMenu(title: "", options: .displayInline, children: [
            UIKeyCommand(title: "My Threads", action: #selector(SplitViewController.viewMyThreads(_:)), input: "1", modifierFlags: [.command]),
            UIKeyCommand(title: "Shopping List", action: #selector(SplitViewController.viewShoppingList(_:)), input: "2", modifierFlags: [.command]),
        ]), atStartOfMenu: .view)
        
        builder.insertSibling(UIMenu(title: "Thread", children: [
            UIMenu(title: "", options: .displayInline, children: [
                UIKeyCommand(title: "Add Threads…", action: #selector(SplitViewController.addThreads(_:)), input: "n", modifierFlags: [.command, .shift]),
            ]),
            UIMenu(title: "", options: .displayInline, children: [
                UIKeyCommand(title: "In Stock", action: #selector(MyThreadsViewController.toggleInStock(_:)), input: "k", modifierFlags: [.command]),
                UIKeyCommand(title: "On Bobbin", action: #selector(MyThreadsViewController.toggleOnBobbin(_:)), input: "b", modifierFlags: [.command]),
            ]),
        ]), afterMenu: .view)
        
        builder.insertSibling(UIMenu(title: "Project", children: [
            UIMenu(title: "", options: .displayInline, children: [
                UIKeyCommand(title: "Edit", action: #selector(SplitViewController.toggleEditingProject(_:)), input: "e", modifierFlags: [.command, .shift]),
                UICommand(title: "Add to Shopping List", action: #selector(SplitViewController.addProjectToShoppingList(_:))),
            ]),
        ]), afterMenu: .view)
    }
}

