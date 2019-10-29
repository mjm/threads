//
//  UserAction.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

protocol UserAction {
    /// The type of value this action returns when it completes successfully.
    ///
    /// If an action type doesn't specify this, it defaults to `Void`.
    associatedtype ResultType = Void

    /// The name to describe this action in undo alerts.
    ///
    /// If nil, no action name will be set. This is strongly discouraged.
    var undoActionName: String? { get }

    /// Whether to save the managed object context after the action completes.
    ///
    /// If not implemented, it defaults to true. It's probably to best to leave it that way.
    var saveAfterComplete: Bool { get }

    /// Whether the action is currently valid to perform.
    ///
    /// This will be used to automatically disable contextual menu actions. If not implemented, it defaults to true.
    var canPerform: Bool { get }

    /// Do the action's work, possibly asynchronously.
    ///
    /// The action must at some point let the context know it's finished its work by calling one of its `complete`
    /// methods. If the work will always be done immediately on the same thread, the action should probably
    /// conform to `SyncUserAction` instead.
    ///
    /// This will always be called on the main queue.
    func performAsync(_ context: UserActionContext<Self>)

    /// Runs this action through the given runner.
    ///
    /// This should not be implemented by concrete action types. It's a hook for subprotocols of `UserAction`
    /// to be able to add custom behavior to how they are performed. This is used by `DestructiveUserAction`
    /// to first present an alert confirming that the action should be run.
    func run(on runner: UserActionRunner, context: UserActionContext<Self>)
}

extension UserAction {
    var saveAfterComplete: Bool { true }
    var canPerform: Bool { true }

    func run(on runner: UserActionRunner, context: UserActionContext<Self>) {
        runner.reallyPerform(self, context: context)
    }
}

protocol AsyncUserAction: UserAction {}

protocol SyncUserAction: ReactiveUserAction {
    /// Do the action's work.
    ///
    /// This will always be called on the main queue.
    ///
    /// Any error thrown or reported to the context will be presented in an alert.
    func perform(_ context: UserActionContext<Self>) throws -> ResultType
}

extension SyncUserAction {
    func publisher(context: UserActionContext<Self>) -> AnyPublisher<ResultType, Error> {
        Result(catching: { try perform(context) }).publisher.eraseToAnyPublisher()
    }
}

protocol ReactiveUserAction: UserAction {
    func publisher(context: UserActionContext<Self>) -> AnyPublisher<ResultType, Error>
}

extension ReactiveUserAction {
    func performAsync(_ context: UserActionContext<Self>) {
        publisher(context: context).complete(context)
    }
}

protocol DestructiveUserAction: UserAction {
    /// The title to use in a confirmation alert for this action.
    var confirmationTitle: String { get }

    /// The message to show below the title in a confirmation alert for this action.
    ///
    /// This will generally be of a form like "Are you sure you want to...?"
    var confirmationMessage: String { get }

    /// The text of the button in the confirmation alert that the user will hit to perform the action.
    var confirmationButtonTitle: String { get }
}

extension DestructiveUserAction {
    func run(on runner: UserActionRunner, context: UserActionContext<Self>) {
        guard runner.presenter != nil else {
            runner.reallyPerform(self, context: context)
            return
        }

        let alert = UIAlertController(
            title: confirmationTitle,
            message: confirmationMessage,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.cancel, style: .cancel))
        alert.addAction(
            UIAlertAction(title: confirmationButtonTitle, style: .destructive) { _ in
                runner.reallyPerform(self, context: context)
            })

        context.present(alert)
    }
}

enum UserActionError: LocalizedError {
    /// An error that a user action can throw when the user has canceled the action.
    ///
    /// Unlike most errors, the action runner won't show an alert for this error.
    case canceled

    var errorDescription: String? {
        switch self {
        case .canceled:
            return "Action Canceled"
        }
    }

    var failureReason: String? {
        switch self {
        case .canceled:
            return "The user canceled the action"
        }
    }
}
