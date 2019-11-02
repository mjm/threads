//
//  DeleteProjectAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import Events

struct DeleteProjectAction: ReactiveUserAction, DestructiveUserAction {
    let project: Project

    var undoActionName: String? { Localized.deleteProject }

    let confirmationTitle: String = Localized.deleteProject
    let confirmationMessage: String = Localized.deleteProjectPrompt
    let confirmationButtonTitle: String = Localized.delete

    func publisher(context: UserActionContext<DeleteProjectAction>) -> AnyPublisher<Void, Error> {
        Event.current[.projectName] = project.name

        return UserActivity.showProject(self.project).delete().handleEvents(receiveOutput: {
            context.managedObjectContext.delete(self.project)
        }).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

extension Project {
    var deleteAction: DeleteProjectAction { .init(project: self) }
}
