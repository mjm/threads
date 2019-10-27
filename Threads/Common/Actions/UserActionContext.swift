//
//  UserActionContext.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData
import Combine

enum UserActionSource {
    case barButtonItem(UIBarButtonItem)
    case view(UIView)
    case rect(CGRect)
}

class UserActionContext<Action: UserAction> {
    let runner: UserActionRunner
    let action: Action
    let source: UserActionSource?
    let willPerformHandler: () -> Void
    
    let subject = ReplaySubject<Action.ResultType, Error>()

    init(
        runner: UserActionRunner,
        action: Action,
        source: UserActionSource?,
        willPerform: @escaping () -> Void
    ) {
        self.runner = runner
        self.action = action
        self.source = source
        self.willPerformHandler = willPerform
    }

    var managedObjectContext: NSManagedObjectContext { runner.managedObjectContext }

    /// Signal that the action has completed its work successfully.
    ///
    /// This will cause any completion handler that was provided when the action was run to be executed.
    ///
    /// - Parameters:
    ///     - result: A value the action is returning to the action's completion handler.
    func complete(_ result: Action.ResultType) {
        subject.send(result)
        subject.send(completion: .finished)
    }

    /// Signal that the action has completed its work with an error.
    ///
    /// This will cause an alert to be presented with details about the error.
    ///
    /// - Parameters:
    ///     - error: The error that caused the action to fail.
    func complete(error: Error) {
        subject.send(completion: .failure(error))
    }
    
    fileprivate var completeSubscription: AnyCancellable?

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
        switch source {
        case let .barButtonItem(item):
            viewController.popoverPresentationController?.barButtonItem = item
        case let .view(view):
            viewController.popoverPresentationController?.sourceView = view
        case let .rect(rect):
            viewController.popoverPresentationController?.sourceRect = rect
        default:
            break
        }
        
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
    func perform<OtherAction: UserAction>(_ action: OtherAction) -> AnyPublisher<OtherAction.ResultType, Error> {
        runner.perform(action)
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

extension Publisher {
    func ignoreError() -> Publishers.Catch<Self, Empty<Output, Never>> {
        self.catch { _ in Empty(completeImmediately: false) }
    }
    
    func complete<Action>(_ context: UserActionContext<Action>) where Output == Action.ResultType, Failure == Error {
        context.completeSubscription = receive(on: RunLoop.main).subscribe(context.subject)
    }
}
