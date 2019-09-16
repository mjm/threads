//
//  UserAction.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation

protocol UserAction {
    /// The name to describe this action in undo alerts.
    ///
    /// If nil, no action name will be set. This is strongly discouraged.
    var undoActionName: String? { get }

    /// Whether to save the managed object context after the action completes.
    ///
    /// If not implemented, it defaults to true. It's probably to best to leave it that way.
    var saveAfterComplete: Bool { get }

    /// Whether the action has to wait for asynchronous work before it can be considered complete.
    ///
    /// If not implemented, it defaults to false, meaning that the action will be considered complete as
    /// soon as the `perform(_:)` method returns.
    ///
    /// If `isAsynchronous` returns true, then the perform method will need to call `context.complete(_:)`
    /// to signal when it has finished its work.
    var isAsynchronous: Bool { get }

    /// Whether the action is currently valid to perform.
    ///
    /// This will be used to automatically disable contextual menu actions. If not implemented, it defaults to true.
    var canPerform: Bool { get }

    /// Do the action's work.
    ///
    /// This will always be called on the main queue.
    ///
    /// Any error thrown or reported to the context will be presented in an alert.
    func perform(_ context: UserActionContext) throws
}

extension UserAction {
    var saveAfterComplete: Bool { true }
    var isAsynchronous: Bool { false }
    var canPerform: Bool { true }
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
