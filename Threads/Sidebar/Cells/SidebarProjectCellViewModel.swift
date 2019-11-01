//
//  SidebarProjectCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/31/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class SidebarProjectCellViewModel {
    let project: Project
    let actionRunner: UserActionRunner

    init(project: Project, actionRunner: UserActionRunner) {
        self.project = project
        self.actionRunner = actionRunner
    }

    var name: AnyPublisher<String?, Never> {
        project.publisher(for: \.displayName).optionally().eraseToAnyPublisher()
    }

    var addToShoppingListAction: BoundUserAction<Void> {
        AddProjectToShoppingListAction(project: project)
            .bind(to: actionRunner)
    }

    var shareAction: BoundUserAction<Void> {
        ShareProjectAction(project: project)
            .bind(to: actionRunner, title: Localized.share)
    }

    var deleteAction: BoundUserAction<Void> {
        DeleteProjectAction(project: project)
            .bind(to: actionRunner, title: Localized.delete, options: .destructive)
    }
}

extension SidebarProjectCellViewModel: Hashable {
    static func == (lhs: SidebarProjectCellViewModel, rhs: SidebarProjectCellViewModel) -> Bool {
        lhs.project == rhs.project
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(project)
    }
}
