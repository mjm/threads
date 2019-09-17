//
//  ThreadActions.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation

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
