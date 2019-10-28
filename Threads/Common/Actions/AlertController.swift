//
//  AlertController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

var actionRunnerHandle: UInt8 = 0

extension UIAlertController {
    var actionRunner: UserActionRunner! {
        get {
            objc_getAssociatedObject(self, &actionRunnerHandle) as? UserActionRunner
        }
        set {
            objc_setAssociatedObject(
                self, &actionRunnerHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    convenience init(
        actionRunner: UserActionRunner, title: String? = nil, message: String? = nil,
        preferredStyle: UIAlertController.Style
    ) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        self.actionRunner = actionRunner
    }

    func addAction<Action: UserAction>(
        _ action: Action,
        title: String? = nil,
        style: UIAlertAction.Style = .default,
        willPerform: @escaping () -> Void = {},
        completion: @escaping (Action.ResultType) -> Void = { _ in }
    ) {
        addAction(
            actionRunner.alertAction(
                action, title: title, style: style, willPerform: willPerform, completion: completion
            ))
    }
}
