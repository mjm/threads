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

class AddToCollectionAction: UserAction {
    let threads: [Thread]
    init(threads: [Thread]) { self.threads = threads }

    let undoActionName: String? = Localized.addToCollection

    func perform(_ context: UserActionContext) throws {
        for thread in threads {
            thread.addToCollection()
        }
    }
}

class AddToShoppingListAction: ThreadAction, UserAction {
    let undoActionName: String? = Localized.addToShoppingList

    var canPerform: Bool {
        !thread.inShoppingList
    }

    func perform(_ context: UserActionContext) throws {
        thread.addToShoppingList()
    }
}

class AddToProjectAction: UserAction {
    let threads: [Thread]
    let project: Project
    init(threads: [Thread], project: Project) {
        assert(threads.count > 0)

        self.threads = threads
        self.project = project
    }

    convenience init(thread: Thread, project: Project) {
        self.init(threads: [thread], project: project)
    }

    let undoActionName: String? = Localized.addToProject

    lazy var canPerform: Bool = {
        if threads.count > 1 {
            return true
        } else {
            let projectThreads = threads[0].projects as? Set<ProjectThread> ?? []
            return projectThreads.allSatisfy { $0.project != project }
        }
    }()

    func perform(_ context: UserActionContext) throws {
        for thread in threads {
            thread.add(to: project)
        }
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
