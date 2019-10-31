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
    private var title: String
    private var options: BoundUserActionOptions
    private var canPerformBlock: () -> Bool
    private var performBlock: (@escaping () -> Void) -> AnyPublisher<ResultType, Error>

    init<Action: UserAction>(
        _ action: Action,
        runner: UserActionRunner,
        title: String? = nil,
        options: BoundUserActionOptions = []
    ) where Action.ResultType == ResultType {
        guard let title = title ?? action.undoActionName else {
            preconditionFailure(
                "Could not find a title for \(action). Either pass a title: argument or set the undoActionName on the action."
            )
        }
        self.title = title
        self.options = options
        canPerformBlock = { action.canPerform }
        performBlock = { willPerform in
            runner.perform(action, willPerform: willPerform)
        }
    }

    var canPerform: Bool { canPerformBlock() }

    @discardableResult
    func perform(willPerform: @escaping () -> Void = {}) -> AnyPublisher<ResultType, Error> {
        performBlock(willPerform)
    }
}

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
}
