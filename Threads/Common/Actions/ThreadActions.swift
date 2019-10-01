//
//  ThreadActions.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

struct MarkOffBobbinAction: SyncUserAction {
    let thread: Thread

    let undoActionName: String? = Localized.markOffBobbin

    func perform(_ context: UserActionContext<MarkOffBobbinAction>) throws {
        thread.onBobbin = false
    }
}

struct MarkOnBobbinAction: SyncUserAction {
    let thread: Thread

    let undoActionName: String? = Localized.markOnBobbin

    func perform(_ context: UserActionContext<MarkOnBobbinAction>) throws {
        thread.onBobbin = true
    }
}

struct MarkInStockAction: SyncUserAction {
    let thread: Thread

    let undoActionName: String? = Localized.markInStock

    func perform(_ context: UserActionContext<MarkInStockAction>) throws {
        thread.amountInCollection = 1
    }
}

struct MarkOutOfStockAction: SyncUserAction {
    let thread: Thread

    let undoActionName: String? = Localized.markOutOfStock

    func perform(_ context: UserActionContext<MarkOutOfStockAction>) throws {
        thread.amountInCollection = 0
        thread.onBobbin = false
    }
}

struct AddToCollectionAction: SyncUserAction {
    let threads: [Thread]

    let undoActionName: String? = Localized.addToCollection

    func perform(_ context: UserActionContext<AddToCollectionAction>) throws {
        for thread in threads {
            thread.addToCollection()
        }
    }
}

struct RemoveThreadAction: DestructiveUserAction {
    let thread: Thread

    let undoActionName: String? = Localized.removeThread

    let confirmationTitle = Localized.removeThread
    let confirmationMessage = Localized.removeThreadPrompt
    let confirmationButtonTitle = Localized.remove

    func performAsync(_ context: UserActionContext<RemoveThreadAction>) {
        UserActivity.showThread(thread).delete {
            self.thread.removeFromCollection()
            context.complete()
        }
    }
}

struct AddThreadAction<AddAction: UserAction>: UserAction {
    let choices: [Thread]
    let actionCreator: ([Thread]) -> AddAction

    // This action won't do the actual undoable work, instead the AddAction will do that.
    let undoActionName: String? = nil

    let coordinator = Coordinator()

    func performAsync(_ context: UserActionContext<AddThreadAction<AddAction>>) {
        let storyboard = UIStoryboard(name: "AddThread", bundle: nil)
        let navController = storyboard.instantiateInitialViewController() as! UINavigationController
        let addThreadController = navController.viewControllers[0] as! AddThreadViewController

        let actionCreator = self.actionCreator

        addThreadController.choices = choices
        addThreadController.onCancel = {
            context.completeAndDismiss()
        }
        addThreadController.onAdd = { threads in
            let addAction = actionCreator(threads)

            context.completeAndDismiss()
            context.perform(addAction)
        }

        navController.presentationController?.delegate = coordinator
        context.present(navController)
    }

    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            let navController = presentationController.presentedViewController as! UINavigationController
            let addThreadController = navController.viewControllers[0] as! AddThreadViewController
            return addThreadController.canDismiss
        }
    }
}
