//
//  BoundUserAction.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

struct BoundUserActionOptions: OptionSet {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let destructive = BoundUserActionOptions(rawValue: 1 << 0)
}

struct BoundUserAction<ResultType> {
    typealias CanPerformHandler = () -> Bool
    typealias WillPerformHandler = () -> Void

    typealias PerformHandler = (UserActionSource?, @escaping () -> Void) -> AnyPublisher<
        ResultType, Error
    >

    fileprivate var title: String
    fileprivate var shortTitle: String
    fileprivate var options: BoundUserActionOptions
    fileprivate var canPerformBlock: CanPerformHandler
    fileprivate var willPerformBlock: WillPerformHandler = {}
    fileprivate var performBlock: PerformHandler

    init(
        title: String,
        shortTitle: String? = nil,
        options: BoundUserActionOptions = [],
        canPerform: @escaping CanPerformHandler = { true },
        perform: @escaping PerformHandler
    ) {
        self.title = title
        self.shortTitle = shortTitle ?? title
        self.options = options
        self.canPerformBlock = canPerform
        self.performBlock = perform
    }

    init<Action: UserAction>(
        _ action: Action,
        runner: UserActionRunner,
        title: String? = nil,
        shortTitle: String? = nil,
        options: BoundUserActionOptions = []
    ) where Action.ResultType == ResultType {
        guard let shortTitle = shortTitle ?? title ?? action.shortDisplayName,
            let title = title ?? action.displayName
        else {
            preconditionFailure(
                "Could not find a title for \(action). Either pass a title: argument or set the displayName on the action."
            )
        }

        self.init(
            title: title,
            shortTitle: shortTitle,
            options: options,
            canPerform: { action.canPerform },
            perform: { source, willPerform in
                runner.perform(action, source: source, willPerform: willPerform)
            }
        )
    }

    var isDestructive: Bool {
        get {
            options.contains(.destructive)
        }
        set {
            if newValue {
                options.insert(.destructive)
            } else {
                options.remove(.destructive)
            }
        }
    }

    var canPerform: Bool { canPerformBlock() }

    @discardableResult
    func perform(source: UserActionSource? = nil, willPerform: @escaping () -> Void = {})
        -> AnyPublisher<ResultType, Error>
    {
        let myWillPerform = self.willPerformBlock
        return performBlock(
            source,
            {
                myWillPerform()
                willPerform()
            })
    }

    func onWillPerform(_ block: @escaping () -> Void) -> Self {
        var newAction = self

        let oldWillPerformBlock = willPerformBlock
        newAction.willPerformBlock = {
            block()
            oldWillPerformBlock()
        }

        return newAction
    }
}

// MARK: - Creating UIKIt actions
extension BoundUserAction {
    func alertAction(
        willPerform: @escaping () -> Void = {},
        completion: @escaping (ResultType) -> Void = { _ in }
    ) -> UIAlertAction {
        let style: UIAlertAction.Style = options.contains(.destructive) ? .destructive : .default
        return UIAlertAction(title: title, style: style) { _ in
            self.perform(willPerform: willPerform)
                .ignoreError()
                .handle(receiveValue: completion)
        }
    }

    func menuAction(
        image: UIImage? = nil,
        state: UIMenuElement.State = .off,
        source: UserActionSource? = nil,
        willPerform: @escaping () -> Void = {},
        completion: @escaping (ResultType) -> Void = { _ in }
    ) -> UIAction {
        var attributes: UIMenuElement.Attributes = []

        if !canPerform {
            attributes.insert(.disabled)
        }
        if options.contains(.destructive) {
            attributes.insert(.destructive)
        }

        return UIAction(
            title: title,
            image: image,
            attributes: attributes,
            state: state
        ) { _ in
            self.perform(source: source, willPerform: willPerform)
                .ignoreError()
                .handle(receiveValue: completion)
        }
    }

    func contextualAction(
        willPerform: @escaping () -> Void = {},
        completion: @escaping (ResultType) -> Void = { _ in }
    ) -> UIContextualAction {
        let style: UIContextualAction.Style = options.contains(.destructive)
            ? .destructive : .normal
        return UIContextualAction(style: style, title: shortTitle) {
            _, _, contextualActionCompletion in
            self.perform(willPerform: willPerform)
                .ignoreError()
                .handle(receiveValue: { value in
                    completion(value)
                    contextualActionCompletion(true)
                })
        }
    }
}

extension UICommand {
    func update<T>(_ action: BoundUserAction<T>?, updateTitle: Bool = false) {
        self.attributes = action?.canPerform ?? false ? [] : .disabled
        if updateTitle, let action = action {
            self.title = action.title
        }
    }
}
