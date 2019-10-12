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
}

