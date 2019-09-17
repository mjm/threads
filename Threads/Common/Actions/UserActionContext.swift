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
        DispatchQueue.main.async {
            self.runner.complete(self.action)
            self.completionHandler(result)
        }
    }

    func complete(error: Error) {
        DispatchQueue.main.async {
            self.runner.presentError(error)
        }
    }

    func present(_ viewController: UIViewController) {
        runner.viewController?.present(viewController, animated: true)
    }
}

extension UserActionContext where Action.ResultType == Void {
    func complete() {
        complete(())
    }
}
