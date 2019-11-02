//
//  AppDelegate.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CoreData
import Events
import StoreKit
import UIKit

func printResponderChain(_ responder: UIResponder?) {
    guard let responder = responder else { return }

    print(responder)
    printResponderChain(responder.next)
}

extension Event.Key {
    static let temporaryStore: Event.Key = "temporary_store"
    static let loadStoreTime: Event.Key = "load_store_ms"
    static let mergeThreadsTime: Event.Key = "merge_threads_ms"
    static let mergeThreadsError: Event.Key = "merge_threads_err"
    static let importThreadsTime: Event.Key = "import_threads_ms"
    static let importThreadsError: Event.Key = "import_threads_err"

    static let premium: Event.Key = "premium"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        try! StoreObserver.default.validateReceipt()
        return true
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        SKPaymentQueue.default().add(StoreObserver.default)
        Event.sink = OSLogEventSink(subsystem: "com.mattmoriarity.Threads", category: "events")
        Event.global[.premium] = { StoreObserver.default.hasPurchased(.premium) }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        SKPaymentQueue.default().remove(StoreObserver.default)
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        #if targetEnvironment(macCatalyst)
        if options.userActivities.first?.activityType == UserActivityType.addThreads.rawValue {
            return UISceneConfiguration(name: "AddThread", sessionRole: connectingSceneSession.role)
        } else {
            return UISceneConfiguration(name: "Mac", sessionRole: connectingSceneSession.role)
        }
        #else
        return UISceneConfiguration(name: "iPhone", sessionRole: connectingSceneSession.role)
        #endif
    }

    func application(
        _ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        if UserDefaults.standard.bool(forKey: "UseTemporaryStore") {
            Event.global[.temporaryStore] = true
            return createTemporaryContainer()
        } else {
            return createCloudKitContainer()
        }
    }()

    private func createCloudKitContainer() -> NSPersistentContainer {
        var event = EventBuilder()

        let container = NSPersistentCloudKitContainer(name: "Threads")

        event.startTimer(.loadStoreTime)
        container.loadPersistentStores { storeDescription, error in
            event.stopTimer(.loadStoreTime)
            event.error = error

            if let error = error as NSError? {
                event.send(.error, "loaded persistent store")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            container.performBackgroundTask { context in
                event.startTimer(.mergeThreadsTime)
                do {
                    try Thread.mergeThreads(context: context, event: &event)
                    try context.save()
                } catch {
                    event[.mergeThreadsError] = error.localizedDescription
                }
                event.stopTimer(.mergeThreadsTime)

                event.startTimer(.importThreadsTime)
                do {
                    try Thread.importThreads(DMCThread.all, context: context, event: &event)
                    try context.save()
                } catch {
                    event[.importThreadsError] = error.localizedDescription
                }
                event.stopTimer(.importThreadsTime)

                event.send("loaded persistent store")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = UndoManager()
        return container
    }

    private func createTemporaryContainer() -> NSPersistentContainer {
        var event = EventBuilder()

        let container = NSPersistentContainer(name: "Threads")

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        event.startTimer(.loadStoreTime)
        container.loadPersistentStores { _, error in
            event.stopTimer(.loadStoreTime)
            event.error = error

            if let error = error as NSError? {
                event.send(.error, "loaded persistent store")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            container.performBackgroundTask { context in
                event.startTimer(.importThreadsTime)
                do {
                    try Thread.importThreads(DMCThread.all, context: context, event: &event)
                    try context.save()
                } catch {
                    event[.importThreadsError] = error.localizedDescription
                }
                event.stopTimer(.importThreadsTime)

                event.send("loaded persistent store")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = UndoManager()
        return container
    }

    override func buildMenu(with builder: UIMenuBuilder) {
        guard builder.system == .main else { return }

        builder.remove(menu: .format)
        builder.remove(menu: .newScene)  // remove option to open a new window
        builder.remove(menu: .toolbar)

        builder.insertSibling(
            UIMenu(
                title: "", options: .displayInline,
                children: [
                    UICommand(
                        title: "Buy Threads Premium...",
                        action: #selector(SplitViewController.buyPremium(_:))),
                ]), beforeMenu: .services)

        builder.insertChild(
            UIMenu(
                title: "", options: .displayInline,
                children: [
                    UIKeyCommand(
                        title: "New Project…",
                        action: #selector(SplitViewController.addProject(_:)),
                        input: "n", modifierFlags: [.command]),
                ]), atStartOfMenu: .file)

        let share = UICommand(
            title: "Share", action: #selector(SplitViewController.shareProject(_:)),
            propertyList: UICommandTagShare)
        if let closeMenu = builder.menu(for: .close) {
            builder.replace(
                menu: .close, with: closeMenu.replacingChildren([share] + closeMenu.children))
        } else {
            builder.insertChild(
                UIMenu(title: "", options: .displayInline, children: [share]), atEndOfMenu: .file)
        }

        builder.insertChild(
            UIMenu(
                title: "", options: .displayInline,
                children: [
                    UIKeyCommand(
                        title: "My Threads",
                        action: #selector(SplitViewController.viewMyThreads(_:)),
                        input: "1", modifierFlags: [.command]),
                    UIKeyCommand(
                        title: "Shopping List",
                        action: #selector(SplitViewController.viewShoppingList(_:)),
                        input: "2", modifierFlags: [.command]),
                ]), atStartOfMenu: .view)

        builder.insertSibling(
            UIMenu(
                title: "Thread",
                children: [
                    UIMenu(
                        title: "", options: .displayInline,
                        children: [
                            UIKeyCommand(
                                title: "Add Threads…",
                                action: #selector(SplitViewController.addThreads(_:)),
                                input: "n", modifierFlags: [.command, .shift]),
                        ]),
                    UIMenu(
                        title: "", options: .displayInline,
                        children: [
                            UIKeyCommand(
                                title: "In Stock",
                                action: #selector(MyThreadsViewController.toggleInStock(_:)),
                                input: "k", modifierFlags: [.command]),
                            UIKeyCommand(
                                title: "On Bobbin",
                                action: #selector(MyThreadsViewController.toggleOnBobbin(_:)),
                                input: "b", modifierFlags: [.command]),
                            UIKeyCommand(
                                title: "Purchased",
                                action: #selector(ShoppingListViewController
                                    .toggleThreadPurchased(_:)), input: "u",
                                modifierFlags: [.command]),
                        ]),
                    UIMenu(
                        title: "", options: .displayInline,
                        children: [
                            UIKeyCommand(
                                title: "Increase Quantity",
                                action: #selector(ShoppingListViewController
                                    .incrementThreadQuantity(_:)),
                                input: "=", modifierFlags: [.command]),
                            UIKeyCommand(
                                title: "Decrease Quantity",
                                action: #selector(ShoppingListViewController
                                    .decrementThreadQuantity(_:)),
                                input: "-", modifierFlags: [.command]),
                        ]),
                ]), afterMenu: .view)

        builder.insertSibling(
            UIMenu(
                title: "Project",
                children: [
                    UIMenu(
                        title: "", options: .displayInline,
                        children: [
                            UIKeyCommand(
                                title: "Edit",
                                action: #selector(SplitViewController.toggleEditingProject(_:)),
                                input: "e", modifierFlags: [.command, .shift]),
                            UICommand(
                                title: "Add Image…",
                                action: #selector(ProjectDetailViewController.addImageToProject(_:))
                            ),
                            UICommand(
                                title: "Add to Shopping List",
                                action: #selector(SplitViewController.addProjectToShoppingList(_:))),
                        ]),
                ]), afterMenu: .view)
    }
}
