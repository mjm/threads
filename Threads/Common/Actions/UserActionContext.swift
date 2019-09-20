//
//  UserActionContext.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class UserActionContext<Action: UserAction> {
    let runner: UserActionRunner
    let action: Action
    let willPerformHandler: () -> Void
    let completionHandler: (Action.ResultType) -> Void

    init(
        runner: UserActionRunner,
        action: Action,
        willPerform: @escaping () -> Void,
        completion: @escaping (Action.ResultType) -> Void
    ) {
        self.runner = runner
        self.action = action
        self.willPerformHandler = willPerform
        self.completionHandler = completion
    }

    var managedObjectContext: NSManagedObjectContext { runner.managedObjectContext }

    func complete(_ result: Action.ResultType) {
        perform {
            self.runner.complete(self.action)
            self.completionHandler(result)
        }
    }

    func complete(error: Error) {
        perform {
            self.runner.presentError(error)
        }
    }

    func completeAndDismiss(_ result: Action.ResultType) {
        dismiss()
        complete(result)
    }

    func completeAndDismiss(error: Error) {
        dismiss()
        complete(error: error)
    }

    func present(_ viewController: UIViewController) {
        runner.viewController?.present(viewController, animated: true)
    }

    func dismiss() {
        runner.viewController?.dismiss(animated: true)
    }

    private func perform(execute work: @escaping () -> Void) {
        // It's sometimes important that our completion handlers do not wait for the next tick
        // of the event loop. So we check if we are already on the main queue and just run the
        // block immediately if so, otherwise we dispatch it onto the main queue.
        let isMainQueue = DispatchQueue.getSpecific(key: isMainQueueKey) ?? false
        if isMainQueue {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}

// Cleaner API to not pass a result when the result type is void
extension UserActionContext where Action.ResultType == Void {
    func complete() {
        complete(())
    }

    func completeAndDismiss() {
        completeAndDismiss(())
    }
}
