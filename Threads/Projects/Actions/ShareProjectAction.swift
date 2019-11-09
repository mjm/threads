//
//  ShareProjectAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import Events
import UIKit
import UserActions

struct ShareProjectAction: ReactiveUserAction {
    let project: Project

    // There's not really anything you can do to undo a share, since it leaves the
    // context of the app.
    var undoActionName: String? { nil }

    func publisher(context: UserActions.Context<ShareProjectAction>) -> AnyPublisher<Void, Error> {
        Event.current[.projectName] = project.name

        let activityController = UIActivityViewController(
            activityItems: [ProjectActivity(project: project)],
            applicationActivities: [OpenInSafariActivity()])

        return Future { promise in
            activityController.completionWithItemsHandler = {
                activityType, completed, items, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }

                Event.current[.activityType] = activityType?.rawValue

                if completed {
                    promise(.success(()))
                } else {
                    promise(.failure(UserActionError.canceled))
                }
            }

            context.present(activityController)
        }.eraseToAnyPublisher()
    }
}

extension Project {
    var shareAction: ShareProjectAction { .init(project: self) }
}
