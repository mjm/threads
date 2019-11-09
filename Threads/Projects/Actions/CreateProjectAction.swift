//
//  CreateProjectAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import Events
import UIKit
import UserActions

struct CreateProjectAction: ReactiveUserAction {
    var undoActionName: String? { Localized.newProject }

    #if targetEnvironment(macCatalyst)
    func publisher(context: UserActions.Context<CreateProjectAction>) -> AnyPublisher<
        Project, Error
    > {
        Future { promise in
            let alert = UIAlertController(
                title: "Create a Project", message: "Enter a name for your new project:",
                preferredStyle: .alert)
            alert.addTextField(configurationHandler: nil)
            alert.addAction(
                UIAlertAction(title: Localized.cancel, style: .cancel) { _ in
                    promise(.failure(UserActionError.canceled))
                })
            alert.addAction(
                UIAlertAction(title: "Create", style: .default) { _ in
                    let project = Project(context: context.managedObjectContext)
                    project.name = alert.textFields?[0].text

                    Event.current[.projectName] = project.name

                    promise(.success(project))
                })

            context.present(alert)
        }.eraseToAnyPublisher()
    }
    #else
    func publisher(context: UserActions.Context<CreateProjectAction>) -> AnyPublisher<
        Project, Error
    > {
        let project = Project(context: context.managedObjectContext)
        return Just(project).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    #endif
}
