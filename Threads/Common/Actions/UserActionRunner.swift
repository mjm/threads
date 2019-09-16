//
//  UserActionRunner.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class UserActionRunner {
    let viewController: UIViewController
    let managedObjectContext: NSManagedObjectContext

    init(viewController: UIViewController,
         managedObjectContext: NSManagedObjectContext) {
        self.viewController = viewController
        self.managedObjectContext = managedObjectContext
    }

    func perform(_ action: UserAction, completion: @escaping () -> Void = {}) {
        let context = UserActionContext(runner: self,
                                        action: action,
                                        completion: completion)

        if let destructiveAction = action as? DestructiveUserAction {
            performDestructiveAction(destructiveAction, context: context)
        } else {
            reallyPerform(action, context: context)
        }
    }

    private func performDestructiveAction(_ action: DestructiveUserAction, context: UserActionContext) {
        // TODO this should check a setting for whether confirmation is desired

        let alert = UIAlertController(title: action.confirmationTitle,
                                      message: action.confirmationMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: action.confirmationButtonTitle, style: .destructive) { _ in
            self.reallyPerform(action, context: context)
        })

        viewController.present(alert, animated: true)
    }

    private func reallyPerform(_ action: UserAction, context: UserActionContext) {
        if let undoActionName = action.undoActionName {
            managedObjectContext.undoManager?.setActionName(undoActionName)
            NSLog("Performing action \"\(undoActionName)\": \(action)")
        } else {
            NSLog("Performing action: \(action)")
        }

        do {
            try action.perform(context)
            if !action.isAsynchronous {
                context.complete()
            }
        } catch {
            context.complete(error)
        }
    }

    func presentError(_ error: Error) {
        let alert = UIAlertController(title: Localized.errorOccurred,
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.dismiss, style: .cancel))

        viewController.present(alert, animated: true)
    }

    func complete(_ action: UserAction, completion: () -> Void) {
        if action.saveAfterComplete {
            managedObjectContext.commit()
        }

        NSLog("Completed action: \(action)")
        completion()
    }

    func contextualAction(
        _ action: UserAction,
        title: String? = nil,
        style: UIContextualAction.Style = .normal,
        completion: @escaping () -> Void = {}
    ) -> UIContextualAction {
        UIContextualAction(style: style, title: title) { _, _, contextualActionCompletion in
            self.perform(action) {
                completion()
                contextualActionCompletion(true)
            }
        }
    }

    func menuAction(
        _ action: UserAction,
        title: String,
        image: UIImage? = nil,
        attributes: UIMenuElement.Attributes = [],
        state: UIMenuElement.State = .off,
        completion: @escaping () -> Void = {}
    ) -> UIAction {
        UIAction(title: title, image: image, attributes: attributes, state: state) { _ in
            self.perform(action, completion: completion)
        }
    }
}
