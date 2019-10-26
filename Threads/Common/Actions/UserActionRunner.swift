//
//  UserActionRunner.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData
import Combine
import Events

let isMainQueueKey = DispatchSpecificKey<Bool>()

extension Event.Key {
    static let undoActionName: Event.Key = "undo_action"
    static let actionName: Event.Key = "action"
    static let saved: Event.Key = "saved"
    static let canceled: Event.Key = "canceled"
}

class UserActionRunner {
    weak var viewController: UIViewController?
    let managedObjectContext: NSManagedObjectContext

    init(viewController: UIViewController,
         managedObjectContext: NSManagedObjectContext) {
        self.viewController = viewController
        self.managedObjectContext = managedObjectContext

        DispatchQueue.main.setSpecific(key: isMainQueueKey, value: true)
    }

    func perform<Action: UserAction>(_ action: Action,
                                     source: UserActionSource? = nil,
                                     willPerform: @escaping () -> Void = {},
                                     completion: @escaping (Action.ResultType) -> Void = { _ in }) {
        let context = UserActionContext(runner: self,
                                        action: action,
                                        source: source,
                                        willPerform: willPerform,
                                        completion: completion)

        // The goal here is to get dynamic dispatch, so that destructive actions can do their confirmation
        // behavior. So we ask the action to run itself, though it delegates most of the real work by calling
        // back to `reallyPerform(_:context:)`.
        //
        // Concrete action types shouldn't override `run(on:context:)`, it should only be implemented in a
        // protocol extension.
        action.run(on: self, context: context)
    }

    func reallyPerform<Action: UserAction>(_ action: Action, context: UserActionContext<Action>) {
        Event.current[.actionName] = String(describing: Action.self)
        
        context.willPerformHandler()

        if let undoActionName = action.undoActionName {
            managedObjectContext.undoManager?.setActionName(undoActionName)
            Event.current[.undoActionName] = undoActionName
        }

        action.performAsync(context)
    }

    func presentError(_ error: Error) {
        if case UserActionError.canceled = error {
            Event.current[.canceled] = true
            Event.current.send("completed user action")
        } else {
            Event.current.error = error
            viewController?.present(error: error)
            Event.current.send(.error, "completed user action")
        }
    }

    func complete<Action: UserAction>(_ action: Action) {
        if action.saveAfterComplete {
            managedObjectContext.commit()
        }
        Event.current[.saved] = action.saveAfterComplete

        Event.current.send("completed user action")
    }

    func contextualAction<Action: UserAction>(
        _ action: Action,
        title: String? = nil,
        style: UIContextualAction.Style = .normal,
        willPerform: @escaping () -> Void = {},
        completion: @escaping (Action.ResultType) -> Void = { _ in }
    ) -> UIContextualAction {
        UIContextualAction(style: style, title: title) { _, _, contextualActionCompletion in
            self.perform(action, willPerform: willPerform) { result in
                completion(result)
                contextualActionCompletion(true)
            }
        }
    }

    func menuAction<Action: UserAction>(
        _ action: Action,
        title: String? = nil,
        image: UIImage? = nil,
        attributes: UIMenuElement.Attributes = [],
        state: UIMenuElement.State = .off,
        source: UserActionSource? = nil,
        willPerform: @escaping () -> Void = {},
        completion: @escaping (Action.ResultType) -> Void = { _ in }
    ) -> UIAction {
        guard let title = title ?? action.undoActionName else {
            preconditionFailure("Could not find a title for menu action for \(action). Either pass a title: argument or set the undoActionName on the action.")
        }

        let extraAttributes: UIMenuElement.Attributes = action.canPerform ? [] : .disabled
        return UIAction(title: title, image: image, attributes: attributes.union(extraAttributes), state: state) { _ in
            self.perform(action, source: source, willPerform: willPerform, completion: completion)
        }
    }

    func alertAction<Action: UserAction>(
        _ action: Action,
        title: String? = nil,
        style: UIAlertAction.Style = .default,
        willPerform: @escaping () -> Void = {},
        completion: @escaping (Action.ResultType) -> Void = { _ in }
    ) -> UIAlertAction {
        guard let title = title ?? action.undoActionName else {
            preconditionFailure("Could not find a title for alert action for \(action). Either pass a title: argument or set the undoActionName on the action.")
        }

        return UIAlertAction(title: title, style: style) { _ in
            self.perform(action, willPerform: willPerform, completion: completion)
        }
    }
}

extension Publisher {
    func perform<Action: UserAction>(on runner: UserActionRunner) -> AnyCancellable where Output == Action, Failure == Never {
        sink { action in
            runner.perform(action)
        }
    }
}
