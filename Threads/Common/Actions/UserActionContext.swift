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

    /// Signal that the action has completed its work successfully.
    ///
    /// This will cause any completion handler that was provided when the action was run to be executed.
    ///
    /// - Parameters:
    ///     - result: A value the action is returning to the action's completion handler.
    func complete(_ result: Action.ResultType) {
        performOnMainQueue {
            self.runner.complete(self.action)
            self.completionHandler(result)
        }
    }

    /// Signal that the action has completed its work with an error.
    ///
    /// This will cause an alert to be presented with details about the error.
    ///
    /// - Parameters:
    ///     - error: The error that caused the action to fail.
    func complete(error: Error) {
        performOnMainQueue {
            self.runner.presentError(error)
        }
    }

    /// Signal that the action has completed its work successfully, and dismiss a previously presented view controller.
    ///
    /// This will cause any completion handler that was provided when the action was run to be executed.
    ///
    /// - Parameters:
    ///     - result: A value the action is returning to the action's completion handler.
    func completeAndDismiss(_ result: Action.ResultType) {
        dismiss()
        complete(result)
    }

    /// Signal that the action has completed its work with an error, dismissing a previously presented view controller.
    ///
    /// This will cause an alert to be presented with details about the error.
    ///
    /// - Parameters:
    ///     - error: The error that caused the action to fail.
    func completeAndDismiss(error: Error) {
        dismiss()
        complete(error: error)
    }

    /// Present a view controller from the context of the view controller that ran the action.
    ///
    /// - Parameters:
    ///     - viewController: The view controller to present.
    func present(_ viewController: UIViewController) {
        runner.viewController?.present(viewController, animated: true)
    }

    /// Dismiss a view controller that was previously presented using `present(_:)`.
    func dismiss() {
        runner.viewController?.dismiss(animated: true)
    }

    /// Perform an action on the same runner that ran the current action.
    ///
    /// This allows an action to chain into another action.
    ///
    /// - Parameters:
    ///     - action: The new action to run.
    ///     - completion: A completion handler to run when the new action completes successfully.
    func perform<OtherAction: UserAction>(_ action: OtherAction, completion: @escaping (OtherAction.ResultType) -> Void = { _ in }) {
        runner.perform(action, completion: completion)
    }

    private func performOnMainQueue(execute work: @escaping () -> Void) {
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
    /// Signal that the action has completed its work successfully.
    ///
    /// This will cause any completion handler that was provided when the action was run to be executed.
    func complete() {
        complete(())
    }

    /// Signal that the action has completed its work successfully, and dismiss a previously presented view controller.
    ///
    /// This will cause any completion handler that was provided when the action was run to be executed.
    func completeAndDismiss() {
        completeAndDismiss(())
    }
}
