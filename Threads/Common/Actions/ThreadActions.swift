//
//  ThreadActions.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import Events
import UIKit

extension Event.Key {
    static let threadNumber: Event.Key = "thread_num"
    static let threadCount: Event.Key = "thread_count"
}

struct MarkOffBobbinAction: SyncUserAction {
    let thread: Thread

    let undoActionName: String? = Localized.markOffBobbin

    func perform(_ context: UserActionContext<MarkOffBobbinAction>) throws {
        Event.current[.threadNumber] = thread.number
        thread.onBobbin = false
    }
}

struct MarkOnBobbinAction: SyncUserAction {
    let thread: Thread

    let undoActionName: String? = Localized.markOnBobbin

    func perform(_ context: UserActionContext<MarkOnBobbinAction>) throws {
        Event.current[.threadNumber] = thread.number
        thread.onBobbin = true
    }
}

struct MarkInStockAction: SyncUserAction {
    let thread: Thread

    let undoActionName: String? = Localized.markInStock

    func perform(_ context: UserActionContext<MarkInStockAction>) throws {
        Event.current[.threadNumber] = thread.number
        thread.amountInCollection = 1
    }
}

struct MarkOutOfStockAction: SyncUserAction {
    let thread: Thread

    let undoActionName: String? = Localized.markOutOfStock

    func perform(_ context: UserActionContext<MarkOutOfStockAction>) throws {
        Event.current[.threadNumber] = thread.number
        thread.amountInCollection = 0
        thread.onBobbin = false
    }
}

struct AddToCollectionAction: SyncUserAction {
    let threads: [Thread]

    let undoActionName: String? = Localized.addToCollection

    func perform(_ context: UserActionContext<AddToCollectionAction>) throws {
        Event.current[.threadCount] = threads.count
        for thread in threads {
            thread.addToCollection()
        }
    }
}

struct RemoveThreadAction: ReactiveUserAction, DestructiveUserAction {
    let thread: Thread

    let undoActionName: String? = Localized.removeThread

    let confirmationTitle = Localized.removeThread
    let confirmationMessage = Localized.removeThreadPrompt
    let confirmationButtonTitle = Localized.remove

    func publisher(context: UserActionContext<RemoveThreadAction>) -> AnyPublisher<Void, Error> {
        Event.current[.threadNumber] = thread.number

        return Future { promise in
            UserActivity.showThread(self.thread).delete {
                RunLoop.main.perform {
                    self.thread.removeFromCollection()
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
}

struct AddThreadAction: AsyncUserAction {
    enum Mode {
        case collection
        case shoppingList
        case project(Project)

        func makeMode(context: NSManagedObjectContext) -> AddThreadMode {
            switch self {
            case .collection:
                return AddThreadsToCollectionMode(context: context)
            case .shoppingList:
                return AddThreadsToShoppingListMode(context: context)
            case let .project(project):
                return AddThreadsToProjectMode(project: project)
            }
        }
    }

    let mode: Mode

    let undoActionName: String? = nil

    #if targetEnvironment(macCatalyst)

    func performAsync(_ context: UserActionContext<AddThreadAction>) {
        let activity = UserActivity.addThreads(mode).userActivity
        UIApplication.shared.requestSceneSessionActivation(
            nil, userActivity: activity, options: nil)
    }

    #else

    let coordinator = Coordinator()

    func performAsync(_ context: UserActionContext<AddThreadAction>) {
        let storyboard = UIStoryboard(name: "AddThread", bundle: nil)
        let navController = storyboard.instantiateViewController(identifier: "NavController")
            as! UINavigationController
        let addThreadController = navController.viewControllers[0] as! AddThreadViewController

        addThreadController.viewModel.mode = mode.makeMode(context: context.managedObjectContext)
        addThreadController.onDismiss = {
            context.completeAndDismiss()
        }

        navController.presentationController?.delegate = coordinator
        context.present(navController)
    }

    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController)
            -> Bool
        {
            let navController = presentationController.presentedViewController
                as! UINavigationController
            let addThreadController = navController.viewControllers[0] as! AddThreadViewController
            return addThreadController.canDismiss
        }
    }

    #endif
}
