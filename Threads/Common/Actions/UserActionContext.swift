//
//  UserActionContext.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import CoreData

class UserActionContext {
    let runner: UserActionRunner
    let action: UserAction
    let willPerformHandler: () -> Void
    let completionHandler: () -> Void

    init(
        runner: UserActionRunner,
        action: UserAction,
        willPerform: @escaping () -> Void,
        completion: @escaping () -> Void
    ) {
        self.runner = runner
        self.action = action
        self.willPerformHandler = willPerform
        self.completionHandler = completion
    }

    var managedObjectContext: NSManagedObjectContext { runner.managedObjectContext }

    func complete(_ error: Error? = nil) {
        if action.isAsynchronous {
            // async actions might call us from a different queue
            DispatchQueue.main.async {
                self.completeOnMainQueue(error)
            }
        } else {
            // assume we stayed on the main queue for synchronous actions
            self.completeOnMainQueue(error)
        }
    }

    private func completeOnMainQueue(_ error: Error?) {
        if let error = error {
            runner.presentError(error)
        } else {
            runner.complete(action, completion: completionHandler)
        }
    }
}
