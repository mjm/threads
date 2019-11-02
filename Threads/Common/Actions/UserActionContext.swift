//
//  UserActionContext.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

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

    private var completeSubscription: AnyCancellable?

    func subscribe(_ action: Action) {
        completeSubscription = action.publisher(context: self).subscribe(subject)
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

        runner.presenter?.present(viewController, animated: true)
    }

    /// Dismiss a view controller that was previously presented using `present(_:)`.
    func dismiss() {
        runner.presenter?.dismiss(animated: true)
    }

    /// Perform an action on the same runner that ran the current action.
    ///
    /// This allows an action to chain into another action.
    ///
    /// - Parameters:
    ///     - action: The new action to run.
    ///     - completion: A completion handler to run when the new action completes successfully.
    func perform<OtherAction: UserAction>(_ action: OtherAction) -> AnyPublisher<
        OtherAction.ResultType, Error
    > {
        runner.perform(action)
    }
}
