//
//  ThreadActions.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation

class ThreadAction {
    let thread: Thread
    init(thread: Thread) { self.thread = thread }
}

class MarkOffBobbinAction: ThreadAction, UserAction {
    let undoActionName: String? = Localized.markOffBobbin

    func perform(_ context: UserActionContext) throws {
        thread.onBobbin = false
    }
}

class MarkOnBobbinAction: ThreadAction, UserAction {
    let undoActionName: String? = Localized.markOnBobbin

    func perform(_ context: UserActionContext) throws {
        thread.onBobbin = true
    }
}

class MarkInStockAction: ThreadAction, UserAction {
    let undoActionName: String? = Localized.markInStock

    func perform(_ context: UserActionContext) throws {
        thread.amountInCollection = 1
    }
}

class MarkOutOfStockAction: ThreadAction, UserAction {
    let undoActionName: String? = Localized.markOutOfStock

    func perform(_ context: UserActionContext) throws {
        thread.amountInCollection = 0
        thread.onBobbin = false
    }
}

class RemoveThreadAction: ThreadAction, DestructiveUserAction {
    let undoActionName: String? = Localized.removeThread

    let confirmationTitle = Localized.removeThread
    let confirmationMessage = Localized.removeThreadPrompt
    let confirmationButtonTitle = Localized.remove

    let isAsynchronous = true

    func perform(_ context: UserActionContext) throws {
        UserActivity.showThread(thread).delete {
            self.thread.removeFromCollection()
            context.complete()
        }
    }
}
