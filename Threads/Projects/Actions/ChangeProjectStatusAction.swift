//
//  ChangeProjectStatusAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/9/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events
import UserActions

struct ChangeProjectStatusAction: SimpleUserAction {
    let project: Project
    let status: Project.Status

    var undoActionName: String? { Localized.changeStatus }

    var displayName: String? { status.shortDisplayName }

    var canPerform: Bool {
        project.status != status
    }

    func perform() throws {
        Event.current[.projectName] = project.name
        Event.current[.projectStatus] = status
        project.status = status
    }
}

extension Project {
    func changeStatusAction(status: Status) -> ChangeProjectStatusAction {
        .init(project: self, status: status)
    }
}
